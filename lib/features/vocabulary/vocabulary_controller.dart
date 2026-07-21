import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/offline_dictionary.dart';
import '../../data/analytics_service.dart';
import '../../data/library_service.dart';
import '../../data/platform_bridge.dart';
import '../../l10n/app_localizations.dart';
import '../../data/profile_avatar_store.dart';
import '../../data/crash_reporter.dart';
import '../../data/contextual_explanation_provider.dart';
import '../../data/example_enrichment_provider.dart';
import '../../data/meaning_discovery_provider.dart';
import '../../data/review_notification_service.dart';
import '../../data/user_profile_cloud_store.dart';
import '../../data/vocabulary_cloud_store.dart';
import '../../data/local_dictionary_cache.dart';
import '../../data/gemini_dictionary_service.dart';
import '../../data/dictionary_pre_cache_service.dart';
import '../../models/capture_payload.dart';
import '../../models/collection.dart';
import '../../models/dictionary_result.dart';
import '../../models/language_pair.dart';
import '../../models/tag.dart';
import '../../models/user_profile.dart';
import '../../models/vocabulary_entry.dart';
import '../../models/vocabulary_sense.dart';
import '../review/fsrs_scheduler.dart';
import '../review/review_scheduler.dart';

class VocabularyController extends ChangeNotifier {
  VocabularyController(
    this._dictionary,
    this._platformBridge, [
    this._cloudStore,
    this._contextualExplanationService,
    this._reviewNotificationService,
    this._profileStore,
    this._meaningDiscoveryService,
    this._profileAvatarStore,
    this._crashReporter,
    this._analyticsService,
    this._exampleEnrichmentService,
    this._localCache,
    this._geminiDictionaryService,
    this._preCacheService,
  ]);

  final OfflineDictionary _dictionary;
  final PlatformBridge _platformBridge;
  final VocabularyCloudStore? _cloudStore;
  final ContextualExplanationService? _contextualExplanationService;
  final ReviewNotificationService? _reviewNotificationService;
  final UserProfileCloudStore? _profileStore;
  final MeaningDiscoveryService? _meaningDiscoveryService;
  final ProfileAvatarStore? _profileAvatarStore;
  final CrashReporter? _crashReporter;
  final AnalyticsService? _analyticsService;
  final ExampleEnrichmentService? _exampleEnrichmentService;
  final LocalDictionaryCache? _localCache;
  final GeminiDictionaryService? _geminiDictionaryService;
  final DictionaryPreCacheService? _preCacheService;
  final FsrsScheduler _reviewScheduler = FsrsScheduler();

  List<VocabularyEntry> _entries = const [];
  List<Collection> _collections = const [];
  List<Tag> _tags = const [];
  CapturePayload? _pendingCapture;
  bool _isReady = false;
  bool _isSyncing = false;
  String? _activeUserId;
  String? _cloudSyncError;
  UserProfile? _userProfile;
  bool _isProfileSyncing = false;
  String? _profileSyncError;
  VocabularyLanguage _preferredTarget = VocabularyLanguage.arabic;
  VocabularyLanguage _lastSource = VocabularyLanguage.english;
  VocabularyLanguage? _interfaceLanguage;
  bool _hasChosenTargetLanguage = false;
  bool _reviewRemindersEnabled = false;
  String? _explainingEntryId;
  String? _explainingSenseId;
  String? _discoveringMeaningsEntryId;
  DateTime? _lastCloudSyncTime;
  int _lastSyncEntryCount = 0;
  VocabularyEntry? _lastDeletedEntry;

  List<VocabularyEntry> get entries => List.unmodifiable(_entries);
  List<Collection> get collections => List.unmodifiable(_collections);
  List<Tag> get tags => List.unmodifiable(_tags);
  List<VocabularyEntry> get inboxEntries =>
      List.unmodifiable(_entries.where((entry) => entry.reviewCount == 0));
  CapturePayload? get pendingCapture => _pendingCapture;
  bool get isReady => _isReady;
  bool get isSyncing => _isSyncing;
  String? get cloudSyncError => _cloudSyncError;
  UserProfile? get userProfile => _userProfile;
  bool get isProfileSyncing => _isProfileSyncing;
  String? get profileSyncError => _profileSyncError;
  VocabularyLanguage get preferredTargetLanguage => _preferredTarget;
  VocabularyLanguage? get interfaceLanguage => _interfaceLanguage;
  bool get hasChosenTargetLanguage => _hasChosenTargetLanguage;
  List<LanguagePair> get availableCaptureRoutes => LanguagePair.supported;
  List<LanguagePair> get preferredTargetRoutes =>
      LanguagePair.routesTo(_preferredTarget);
  LanguagePair get languagePair =>
      LanguagePair.route(_lastSource, _preferredTarget) ??
      LanguagePair.routesTo(_preferredTarget).first;
  bool get hasChosenLanguagePair => _hasChosenTargetLanguage;
  bool get reviewRemindersEnabled => _reviewRemindersEnabled;
  bool get canDiscoverMeanings => _meaningDiscoveryService != null;
  String? get explainingEntryId => _explainingEntryId;
  String? get explainingSenseId => _explainingSenseId;
  String? get discoveringMeaningsEntryId => _discoveringMeaningsEntryId;
  DateTime? get lastCloudSyncTime => _lastCloudSyncTime;
  int get lastSyncEntryCount => _lastSyncEntryCount;
  bool get hasDeletedEntry => _lastDeletedEntry != null;
  ui.Locale get _locale => ui.PlatformDispatcher.instance.locale;
  int get reviewedCount =>
      _entries.where((entry) => entry.reviewCount > 0).length;
  int get masteredCount => _entries
      .where((entry) => entry.reviewCount >= 5 && entry.intervalDays >= 14)
      .length;
  int get dueCount => dueEntries(limit: _entries.length).length;

  int get streakCount => computeStreak(_entries);
  double get estimatedRetention =>
      computeRetention(reviewedCount, masteredCount);
  int get todayReviewedCount => computeTodayReviewed(_entries);
  int get dailyGoal => _userProfile?.dailyReviewGoal ?? 10;

  void logReviewSessionCompleted({
    required int cardsReviewed,
    required int correctCount,
    required Duration duration,
  }) {
    _analyticsService?.logReviewSessionCompleted(
      cardsReviewed: cardsReviewed,
      correctCount: correctCount,
      duration: duration,
    );
  }

  void logSessionOpened({Duration? sinceLastSession}) {
    _analyticsService?.logSessionOpened(sinceLastSession: sinceLastSession);
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static int computeStreak(List<VocabularyEntry> entries) {
    final reviewDates =
        entries
            .where((entry) => entry.lastReviewedAt != null)
            .map((entry) => _dateOnly(entry.lastReviewedAt!.toLocal()))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (reviewDates.isEmpty) return 0;
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    if (!reviewDates.contains(today) && !reviewDates.contains(yesterday)) {
      return 0;
    }
    var streak = 0;
    var expected = reviewDates.contains(today) ? today : yesterday;
    for (final date in reviewDates) {
      if (date == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (date.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  static double computeRetention(int reviewed, int mastered) {
    if (reviewed == 0) return 0;
    return mastered / reviewed;
  }

  static int computeTodayReviewed(
    List<VocabularyEntry> entries, {
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    return entries.where((entry) {
      if (entry.lastReviewedAt == null) return false;
      return _dateOnly(entry.lastReviewedAt!.toLocal()) == today;
    }).length;
  }

  List<VocabularyEntry> dueEntries({DateTime? now, int? limit}) {
    final reviewTime = now ?? DateTime.now();
    final due = _entries.where((entry) => entry.isDue(reviewTime)).toList()
      ..sort((a, b) {
        final aDue = a.nextReviewAt ?? a.createdAt;
        final bDue = b.nextReviewAt ?? b.createdAt;
        return aDue.compareTo(bDue);
      });
    final maxItems = limit ?? dailyGoal;
    return due.take(maxItems).toList(growable: false);
  }

  Future<void> initialize() async {
    _platformBridge.onSelectionReceived = receiveCapture;
    _interfaceLanguage = await _platformBridge.loadInterfaceLanguage();
    final storedTarget = await _platformBridge.loadPreferredTargetLanguage();
    final storedPair = await _platformBridge.loadLanguagePair();
    if (storedTarget != null) {
      _preferredTarget = storedTarget;
      _lastSource = storedPair?.target == storedTarget
          ? storedPair!.source
          : LanguagePair.routesTo(storedTarget).first.source;
      _hasChosenTargetLanguage = true;
    } else if (storedPair != null) {
      _preferredTarget = storedPair.target;
      _lastSource = storedPair.source;
      _hasChosenTargetLanguage = true;
      await _platformBridge.savePreferredTargetLanguage(_preferredTarget);
    } else {
      final deviceLanguage = VocabularyLanguage.tryFromCode(
        ui.PlatformDispatcher.instance.locale.languageCode,
      );
      if (deviceLanguage != null &&
          LanguagePair.availableTargets.contains(deviceLanguage)) {
        _preferredTarget = deviceLanguage;
      }
      _lastSource = LanguagePair.routesTo(_preferredTarget).first.source;
    }
    _entries = await _platformBridge.loadEntries();
    if (_entries.any((entry) => entry.needsSchemaMigration)) {
      _entries = _entries
          .map((entry) {
            if (!entry.needsSchemaMigration) return entry;
            return entry.copyWith(
              senses: entry.senses,
              fsrsStability:
                  entry.fsrsStability ??
                  (entry.intervalDays > 0
                      ? entry.intervalDays.toDouble()
                      : null),
              fsrsDifficulty:
                  entry.fsrsDifficulty ?? (entry.reviewCount > 0 ? 5.0 : null),
              fsrsState: entry.fsrsState == 'new'
                  ? VocabularyEntry.migrateFsrsState(
                      entry.reviewCount,
                      entry.intervalDays,
                    )
                  : entry.fsrsState,
            );
          })
          .toList(growable: false);
      await _platformBridge.saveEntries(_entries);
    }
    final libraryJson = await _platformBridge.loadLibrary();
    if (libraryJson != null) {
      _collections = const LibraryService().collectionsFromJson(libraryJson);
      _tags = const LibraryService().tagsFromJson(libraryJson);
    }
    _reviewRemindersEnabled = await _platformBridge.loadReviewReminders();
    _userProfile = await _platformBridge.loadUserProfile();
    _applyProfilePreferences(_userProfile);
    if (_reviewRemindersEnabled) {
      await _reviewNotificationService?.scheduleDaily();
    }
    await _refreshOutdatedDictionaryEntries();
    _isReady = true;
    notifyListeners();

    await pollPlatformCapture();
    _startPreCache();
  }

  void _startPreCache() {
    if (_preCacheService == null || _preCacheService.isRunning) return;
    _preCacheService.preCache(languagePair).catchError((_) {});
  }

  Future<void> pollPlatformCapture() async {
    final capture = await _platformBridge.takeInitialSelection();
    if (capture != null) await receiveCapture(capture);
  }

  Future<void> receiveCapture(CapturePayload payload) async {
    _pendingCapture = payload;
    notifyListeners();
  }

  CapturePayload? takePendingCapture() {
    final capture = _pendingCapture;
    _pendingCapture = null;
    return capture;
  }

  Future<void> setLanguagePair(LanguagePair pair) async {
    await _dictionary.load(pair);
    _preferredTarget = pair.target;
    _lastSource = pair.source;
    _hasChosenTargetLanguage = true;
    notifyListeners();
    await _platformBridge.saveLanguagePair(pair);
    await _platformBridge.savePreferredTargetLanguage(pair.target);
    await _persistProfileChange(
      (profile) =>
          profile.copyWith(preferredTargetLanguageCode: pair.target.code),
    );
    _startPreCache();
  }

  Future<void> setPreferredTargetLanguage(VocabularyLanguage language) async {
    final routes = LanguagePair.routesTo(language);
    if (routes.isEmpty) {
      throw UnsupportedError(
        AppLocalizations.noOfflineRoutes(_locale, language.label),
      );
    }
    _preferredTarget = language;
    if (LanguagePair.route(_lastSource, language) == null) {
      _lastSource = routes.first.source;
    }
    _hasChosenTargetLanguage = true;
    notifyListeners();
    await _platformBridge.savePreferredTargetLanguage(language);
    await _persistProfileChange(
      (profile) => profile.copyWith(preferredTargetLanguageCode: language.code),
    );
  }

  Future<void> setInterfaceLanguage(VocabularyLanguage? language) async {
    _interfaceLanguage = language;
    notifyListeners();
    await _platformBridge.saveInterfaceLanguage(language);
    await _persistProfileChange(
      (profile) => profile.copyWith(interfaceLanguageCode: language?.code),
    );
  }

  Future<DictionaryResult?> lookup(String text, {LanguagePair? pair}) async {
    final targetPair = pair ?? languagePair;

    // 1. Offline dictionary
    final offlineResult = await _dictionary.lookup(text, targetPair);
    if (offlineResult != null) return offlineResult;

    // 2. Local cache (Gemini translations persisted to disk)
    if (_localCache != null) {
      final cached = await _localCache.lookup(text, targetPair);
      if (cached != null) return cached;
    }

    // 3. Gemini API (online)
    if (_geminiDictionaryService != null && _localCache != null) {
      final geminiResult = await _geminiDictionaryService.lookup(
        text,
        targetPair,
      );
      if (geminiResult != null) {
        await _localCache.store(geminiResult, targetPair);
        return geminiResult;
      }
    }

    return null;
  }

  LanguagePair resolveLanguagePair(String text) {
    return autoLanguagePair(text) ?? languagePair;
  }

  LanguagePair? autoLanguagePair(String text) {
    return LanguagePair.resolveForTarget(
      text,
      _preferredTarget,
      fallbackSource: _lastSource,
    );
  }

  Future<LanguagePair?> resolveCaptureLanguagePair(String text) async {
    final scriptHint = LanguagePair.detectSourceLanguage(text);
    if (scriptHint == VocabularyLanguage.arabic ||
        scriptHint == VocabularyLanguage.french) {
      return _bestAvailableRouteFrom(scriptHint!);
    }

    final latinSources = LanguagePair.supported
        .map((pair) => pair.source)
        .where((language) => language.writingSystem == WritingSystem.latin)
        .toSet();
    final matches = <VocabularyLanguage>[];
    for (final source in latinSources) {
      if (await _dictionary.recognizesSource(text, source)) {
        matches.add(source);
      }
    }
    if (matches.length == 1) {
      return _bestAvailableRouteFrom(matches.single);
    }
    if (scriptHint != null) {
      return _bestAvailableRouteFrom(scriptHint);
    }
    return null;
  }

  LanguagePair? _bestAvailableRouteFrom(VocabularyLanguage source) {
    final preferred = LanguagePair.route(source, _preferredTarget);
    if (preferred != null) return preferred;

    // A captured word can already be in the user's preferred target language.
    // In that case reverse the most recently used relationship instead of
    // producing an invalid same-language route.
    final reciprocal = LanguagePair.route(source, _lastSource);
    if (reciprocal != null) return reciprocal;

    return null;
  }

  bool contains(String text, {LanguagePair? pair}) {
    final selectedPair = pair ?? languagePair;
    final normalized = text.trim().toLowerCase();
    return _entries.any(
      (entry) =>
          entry.sourceLanguage == selectedPair.source &&
          entry.targetLanguage == selectedPair.target &&
          entry.sourceText.trim().toLowerCase() == normalized,
    );
  }

  VocabularyEntry? newestEntryForText(String text) {
    final normalized = text.trim().toLowerCase();
    for (final entry in _entries) {
      if (entry.sourceText.trim().toLowerCase() == normalized) return entry;
    }
    return null;
  }

  Future<void> save(
    CapturePayload capture,
    DictionaryResult? result, {
    LanguagePair? pair,
  }) async {
    final selectedPair =
        pair ??
        (result == null
            ? languagePair
            : LanguagePair(
                source: result.sourceLanguage,
                target: result.targetLanguage,
              ));
    if (contains(capture.text, pair: selectedPair)) return;
    final now = DateTime.now();
    final meaningSource = result != null ? 'offline' : 'manual';
    final entry = VocabularyEntry.withSenses(
      id: now.microsecondsSinceEpoch.toString(),
      sourceText: capture.text,
      senses:
          result?.senses ??
          [
            VocabularySense.legacy(
              translations: [
                selectedPair.source == selectedPair.target
                    ? capture.text
                    : AppLocalizations.translationPending(_locale),
              ],
              definition: selectedPair.source == selectedPair.target
                  ? AppLocalizations.sameLanguageStudy(_locale)
                  : AppLocalizations.meaningNotAvailable(_locale),
            ),
          ],
      sourceLanguage: selectedPair.source,
      targetLanguage: selectedPair.target,
      source: capture.source,
      contextText: capture.context?.trim(),
      sourceAppName: capture.sourceAppName,
      sourceUrl: capture.sourceUrl,
      createdAt: now,
      updatedAt: now,
      dictionaryRevision: OfflineDictionary.contentRevision,
      meaningSource: meaningSource,
    );
    _entries = [entry, ..._entries];
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
    _queueCloudUpsert(entry);
    if (_entries.length == 1) {
      _analyticsService?.logFirstSave();
    }
    _enrichExamplesAsync(entry, selectedPair);
  }

  Future<void> _enrichExamplesAsync(
    VocabularyEntry entry,
    LanguagePair pair,
  ) async {
    final service = _exampleEnrichmentService;
    if (service == null) return;
    final hasEmptySenses = entry.senses.any((s) => s.examples.isEmpty);
    if (!hasEmptySenses) return;
    try {
      final enrichedSenses = await service.enrichExamples(
        sourceText: entry.sourceText,
        senses: entry.senses,
        pair: pair,
      );
      final idx = _entries.indexWhere((e) => e.id == entry.id);
      if (idx == -1) return;
      _entries = [
        ..._entries.sublist(0, idx),
        entry.copyWith(senses: enrichedSenses, updatedAt: DateTime.now()),
        ..._entries.sublist(idx + 1),
      ];
      notifyListeners();
      await _platformBridge.saveEntries(_entries);
    } catch (_) {
      // Enrichment is best-effort; don't block or crash.
    }
  }

  Future<void> delete(String id) async {
    final entry = _entries.firstWhere(
      (e) => e.id == id,
      orElse: () => throw StateError('Entry $id not found'),
    );
    _lastDeletedEntry = entry;
    _entries = _entries.where((entry) => entry.id != id).toList();
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
    final userId = _activeUserId;
    if (userId != null && _cloudStore != null) {
      _queueCloudWrite(_cloudStore.deleteEntry(userId, id));
    }
  }

  Future<void> undoDelete() async {
    final entry = _lastDeletedEntry;
    if (entry == null) return;
    _lastDeletedEntry = null;
    _entries = [entry, ..._entries];
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
    _queueCloudUpsert(entry);
  }

  Future<void> enrichWithContext(
    VocabularyEntry entry, {
    String? senseId,
    String? context,
  }) async {
    final service = _contextualExplanationService;
    if (service == null) {
      throw ContextualExplanationException(
        AppLocalizations.contextExplanationUnavailable(_locale),
      );
    }
    final selectedSense = entry.senseById(senseId);
    _explainingEntryId = entry.id;
    _explainingSenseId = selectedSense.id;
    notifyListeners();
    _analyticsService?.logAiExplanationRequested();
    try {
      final explanation = await service.explain(
        entry,
        senseId: selectedSense.id,
        context: context,
      );
      final now = DateTime.now();
      final updated = entry
          .addExampleToSense(
            selectedSense.id,
            VocabularyExample(
              sourceText: explanation.example,
              translation: explanation.exampleTranslation,
            ),
          )
          .copyWith(
            contextText: context?.trim(),
            contextualExplanation: explanation.explanation,
            contextualExample: explanation.example,
            contextualExampleTranslation: explanation.exampleTranslation,
            contextualSenseId: selectedSense.id,
            relatedPhrases: explanation.relatedPhrases,
            contextConsented: context != null && context.trim().isNotEmpty,
            updatedAt: now,
          );
      _entries = _entries
          .map((candidate) => candidate.id == entry.id ? updated : candidate)
          .toList(growable: false);
      await _platformBridge.saveEntries(_entries);
      _queueCloudUpsert(updated);
    } finally {
      _explainingEntryId = null;
      _explainingSenseId = null;
      notifyListeners();
    }
  }

  void reportMeaning(VocabularyEntry entry, String senseId, String reason) {
    _analyticsService?.logMeaningReported();
    _reportNonFatal(
      Exception('Meaning report: ${entry.sourceText} / $senseId: $reason'),
      StackTrace.current,
      operation: 'meaning_report',
    );
  }

  void setContextConsent(VocabularyEntry entry, bool consented) {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx == -1) return;
    final updated = entry.copyWith(
      contextConsented: consented,
      updatedAt: DateTime.now(),
    );
    _entries = [
      ..._entries.sublist(0, idx),
      updated,
      ..._entries.sublist(idx + 1),
    ];
    notifyListeners();
    _platformBridge.saveEntries(_entries);
    _queueCloudUpsert(updated);
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'format': 'stackit-vocabulary',
    'version': 2,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'entries': _entries.map((entry) => entry.toJson()).toList(growable: false),
  });

  Future<bool> setReviewReminders(bool enabled) async {
    if (enabled) {
      final granted =
          await _reviewNotificationService?.requestPermission() ?? false;
      if (!granted) return false;
      await _reviewNotificationService?.scheduleDaily();
    } else {
      await _reviewNotificationService?.cancel();
    }
    _reviewRemindersEnabled = enabled;
    await _platformBridge.saveReviewReminders(enabled);
    notifyListeners();
    await _persistProfileChange(
      (profile) => profile.copyWith(notificationsEnabled: enabled),
    );
    return true;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final now = DateTime.now();
    final updated = profile.copyWith(updatedAt: now).normalized();
    _userProfile = updated;
    _applyProfilePreferences(updated);
    notifyListeners();

    await _platformBridge.saveUserProfile(updated, userId: _activeUserId);
    await _platformBridge.saveInterfaceLanguage(_interfaceLanguage);
    await _platformBridge.savePreferredTargetLanguage(_preferredTarget);

    final userId = _activeUserId;
    if (userId != null && _profileStore != null) {
      _queueProfileWrite(_profileStore.saveProfile(userId, updated));
    }
  }

  Future<Uint8List?> loadProfileAvatar() async {
    final userId = _activeUserId;
    final store = _profileAvatarStore;
    if (userId == null ||
        store == null ||
        _userProfile?.avatarStoragePath != store.pathForUser(userId)) {
      return null;
    }
    return store.loadAvatar(userId);
  }

  Future<void> uploadProfileAvatar(Uint8List bytes) async {
    final userId = _activeUserId;
    final store = _profileAvatarStore;
    final profile = _userProfile;
    if (userId == null || store == null || profile == null) {
      throw ProfileAvatarException(AppLocalizations.signInFirst(_locale));
    }
    final path = await store.uploadAvatar(userId, bytes);
    await updateUserProfile(profile.copyWith(avatarStoragePath: path));
  }

  Future<void> removeProfileAvatar() async {
    final userId = _activeUserId;
    final store = _profileAvatarStore;
    final profile = _userProfile;
    if (userId == null || store == null || profile == null) return;
    await store.deleteAvatar(userId);
    await updateUserProfile(profile.copyWith(avatarStoragePath: null));
  }

  Future<void> deleteAccountData(String userId) async {
    if (_profileAvatarStore != null) {
      await _profileAvatarStore.deleteAvatar(userId);
    }
    if (_profileStore != null) await _profileStore.deleteProfile(userId);
    if (_cloudStore != null) await _cloudStore.deleteAllEntries(userId);
    await _platformBridge.clearUserProfile();
    _activeUserId = null;
    _userProfile = null;
    _entries = const [];
    await _platformBridge.saveEntries(_entries);
    notifyListeners();
  }

  Future<void> review(
    VocabularyEntry entry,
    ReviewRating rating, {
    DateTime? now,
  }) async {
    final reviewTime = now ?? DateTime.now();
    final reviewed = _reviewScheduler
        .schedule(entry, rating, reviewTime)
        .copyWith(updatedAt: reviewTime);
    _entries = _entries
        .map((candidate) => candidate.id == entry.id ? reviewed : candidate)
        .toList(growable: false);
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
    _queueCloudUpsert(reviewed);
    if (reviewedCount == 1) {
      _analyticsService?.logFirstReview();
    }
  }

  Future<void> syncForUser(String userId, {String? displayName}) async {
    if (_cloudStore == null || (_activeUserId == userId && _isSyncing)) return;
    _activeUserId = userId;
    _isSyncing = true;
    _cloudSyncError = null;
    notifyListeners();
    await _syncProfileForUser(userId, displayName: displayName);
    try {
      final remote = await _cloudStore.loadEntries(userId);
      if (_activeUserId != userId) return;
      final merged = <String, VocabularyEntry>{};
      for (final entry in [...remote, ..._entries]) {
        final existing = merged[entry.id];
        if (existing == null ||
            entry.effectiveUpdatedAt.isAfter(existing.effectiveUpdatedAt)) {
          merged[entry.id] = entry;
        }
      }
      _entries = merged.values.toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _refreshOutdatedDictionaryEntries(saveLocally: false);
      await _platformBridge.saveEntries(_entries);
      await _cloudStore.upsertEntries(userId, _entries);
      _lastCloudSyncTime = DateTime.now();
      _lastSyncEntryCount = merged.length;
    } catch (error, stackTrace) {
      _reportCloudError(error, stackTrace);
    } finally {
      if (_activeUserId == userId) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryCloudSync() async {
    final userId = _activeUserId;
    if (userId == null || _cloudStore == null || _isSyncing) return;
    await syncForUser(userId);
  }

  Future<DictionaryResult> discoverAllMeanings(
    String text, {
    required LanguagePair pair,
    DictionaryResult? offlineResult,
    String? context,
  }) async {
    final service = _meaningDiscoveryService;
    if (service == null) {
      throw MeaningDiscoveryException(
        AppLocalizations.meaningDiscoveryNotConfigured(_locale),
      );
    }
    return service.discoverAllMeanings(
      text,
      pair: pair,
      offlineResult: offlineResult,
      context: context,
    );
  }

  Future<void> enrichEntryWithAllMeanings(VocabularyEntry entry) async {
    final service = _meaningDiscoveryService;
    if (service == null) {
      throw MeaningDiscoveryException(
        AppLocalizations.meaningDiscoveryNotConfigured(_locale),
      );
    }
    _discoveringMeaningsEntryId = entry.id;
    notifyListeners();
    _analyticsService?.logMeaningExpanded();
    try {
      final result = await service.discoverAllMeanings(
        entry.sourceText,
        pair: entry.languagePair,
        offlineResult: DictionaryResult.withSenses(
          sourceText: entry.sourceText,
          senses: entry.senses,
          sourceLanguage: entry.sourceLanguage,
          targetLanguage: entry.targetLanguage,
        ),
        context: entry.contextText,
      );
      final updated = entry.copyWith(
        senses: result.senses,
        updatedAt: DateTime.now(),
        meaningSource: 'gemini',
      );
      _entries = _entries
          .map((candidate) => candidate.id == entry.id ? updated : candidate)
          .toList(growable: false);
      await _platformBridge.saveEntries(_entries);
      _queueCloudUpsert(updated);
    } finally {
      _discoveringMeaningsEntryId = null;
      notifyListeners();
    }
  }

  Future<void> clearAfterSignOut() async {
    _activeUserId = null;
    _cloudSyncError = null;
    _entries = const [];
    await _platformBridge.saveEntries(_entries);
    notifyListeners();
  }

  Future<void> _syncProfileForUser(String userId, {String? displayName}) async {
    final store = _profileStore;
    if (store == null) return;
    _isProfileSyncing = true;
    _profileSyncError = null;
    notifyListeners();

    final now = DateTime.now();
    var local = await _platformBridge.loadUserProfile(userId: userId);
    local ??= UserProfile.defaults(
      now: now,
      displayName: displayName,
      interfaceLanguageCode: _interfaceLanguage?.code,
      preferredTargetLanguageCode: _preferredTarget.code,
      notificationsEnabled: _reviewRemindersEnabled,
    );
    _userProfile = local;
    _applyProfilePreferences(local);
    notifyListeners();

    try {
      final remote = await store.loadProfile(userId);
      if (_activeUserId != userId) return;
      var merged = remote == null
          ? local
          : remote.updatedAt.isAfter(local.updatedAt)
          ? remote
          : local.copyWith(createdAt: remote.createdAt);
      if ((merged.displayName == null || merged.displayName!.isEmpty) &&
          displayName != null &&
          displayName.trim().isNotEmpty) {
        merged = merged.copyWith(
          displayName: displayName,
          updatedAt: DateTime.now(),
        );
      }
      _userProfile = merged;
      _applyProfilePreferences(merged);
      await _platformBridge.saveUserProfile(merged, userId: userId);
      await _platformBridge.saveInterfaceLanguage(_interfaceLanguage);
      await _platformBridge.savePreferredTargetLanguage(_preferredTarget);
      await store.saveProfile(userId, merged);
    } catch (error, stackTrace) {
      debugPrint('Stackit profile sync failed: $error\n$stackTrace');
      _reportNonFatal(error, stackTrace, operation: 'profile_sync');
      _profileSyncError = switch (error) {
        FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
          AppLocalizations.profileOfflineMessage(_locale),
        FirebaseException(code: 'permission-denied') =>
          AppLocalizations.profilePermissionDeniedMessage(_locale),
        _ => AppLocalizations.profileSyncPausedMessage(_locale),
      };
      await _platformBridge.saveUserProfile(local, userId: userId);
    } finally {
      if (_activeUserId == userId) {
        _isProfileSyncing = false;
        notifyListeners();
      }
    }
  }

  void _applyProfilePreferences(UserProfile? profile) {
    if (profile == null) return;
    final target = VocabularyLanguage.tryFromCode(
      profile.preferredTargetLanguageCode,
    );
    if (target != null && LanguagePair.routesTo(target).isNotEmpty) {
      _preferredTarget = target;
      if (LanguagePair.route(_lastSource, target) == null) {
        _lastSource = LanguagePair.routesTo(target).first.source;
      }
      _hasChosenTargetLanguage = true;
    }
    _interfaceLanguage = VocabularyLanguage.tryFromCode(
      profile.interfaceLanguageCode,
    );
    _analyticsService?.setConsent(profile.analyticsConsent);
  }

  Future<void> _persistProfileChange(
    UserProfile Function(UserProfile profile) change,
  ) async {
    final profile = _userProfile;
    if (profile == null) return;
    final updated = change(
      profile,
    ).copyWith(updatedAt: DateTime.now()).normalized();
    _userProfile = updated;
    await _platformBridge.saveUserProfile(updated, userId: _activeUserId);
    final userId = _activeUserId;
    if (userId != null && _profileStore != null) {
      _queueProfileWrite(_profileStore.saveProfile(userId, updated));
    }
    notifyListeners();
  }

  void _queueProfileWrite(Future<void> operation) {
    unawaited(() async {
      try {
        await operation;
        if (_profileSyncError != null) {
          _profileSyncError = null;
          notifyListeners();
        }
      } catch (error, stackTrace) {
        debugPrint('Stackit profile update failed: $error\n$stackTrace');
        _reportNonFatal(error, stackTrace, operation: 'profile_update');
        _profileSyncError = AppLocalizations.profileSyncPausedMessage(_locale);
        notifyListeners();
      }
    }());
  }

  void _queueCloudUpsert(VocabularyEntry entry) {
    final userId = _activeUserId;
    if (userId != null && _cloudStore != null) {
      _queueCloudWrite(_cloudStore.upsertEntry(userId, entry));
    }
  }

  void _queueCloudWrite(Future<void> operation) {
    unawaited(() async {
      try {
        await operation;
        if (_cloudSyncError != null) {
          _cloudSyncError = null;
          notifyListeners();
        }
      } catch (error, stackTrace) {
        _reportCloudError(error, stackTrace);
        notifyListeners();
      }
    }());
  }

  Future<void> speak(String text, VocabularyLanguage language) {
    final accent = _userProfile?.learningLanguages
        .where((l) => l.languageCode == language.code)
        .map((l) => l.pronunciationLocale)
        .firstOrNull;
    return _platformBridge.speak(text, language, localeTag: accent);
  }

  Future<CapturePayload?> readClipboard() {
    return _platformBridge.readClipboard();
  }

  static const _libraryService = LibraryService();

  Future<Collection> createCollection(
    String name, {
    String description = '',
  }) async {
    final collection = _libraryService.createCollection(
      name,
      description: description,
    );
    _collections = [..._collections, collection];
    notifyListeners();
    await _saveLibrary();
    return collection;
  }

  Future<void> deleteCollection(String collectionId) async {
    _entries = _entries
        .map((e) {
          if (!e.collectionIds.contains(collectionId)) return e;
          return _libraryService.removeFromCollection(e, collectionId);
        })
        .toList(growable: false);
    _collections = _collections.where((c) => c.id != collectionId).toList();
    notifyListeners();
    await _saveLibrary();
    await _platformBridge.saveEntries(_entries);
  }

  Future<void> addToCollection(
    VocabularyEntry entry,
    String collectionId,
  ) async {
    _entries = _entries
        .map((e) {
          if (e.id != entry.id) return e;
          return _libraryService.addToCollection(e, collectionId);
        })
        .toList(growable: false);
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
  }

  Future<void> removeFromCollection(
    VocabularyEntry entry,
    String collectionId,
  ) async {
    _entries = _entries
        .map((e) {
          if (e.id != entry.id) return e;
          return _libraryService.removeFromCollection(e, collectionId);
        })
        .toList(growable: false);
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
  }

  Future<void> toggleFavorite(VocabularyEntry entry) async {
    _entries = _entries
        .map((e) {
          if (e.id != entry.id) return e;
          return _libraryService.toggleFavorite(e);
        })
        .toList(growable: false);
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
  }

  Future<void> _saveLibrary() async {
    final data = _libraryService.encodeLibrary(
      collections: _collections,
      tags: _tags,
    );
    await _platformBridge.saveLibrary(data);
  }

  void _reportCloudError(Object error, StackTrace stackTrace) {
    debugPrint('Stackit cloud sync failed: $error\n$stackTrace');
    _reportNonFatal(error, stackTrace, operation: 'vocabulary_sync');
    _cloudSyncError = switch (error) {
      FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
        AppLocalizations.offlineMessage(_locale),
      FirebaseException(code: 'permission-denied') =>
        AppLocalizations.permissionDeniedCloudMessage(_locale),
      _ => AppLocalizations.cloudSyncPausedMessage(_locale),
    };
  }

  void _reportNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) {
    final reporter = _crashReporter;
    if (reporter == null) return;
    unawaited(reporter.recordNonFatal(error, stackTrace, operation: operation));
  }

  Future<void> _refreshOutdatedDictionaryEntries({
    bool saveLocally = true,
  }) async {
    if (_entries.every(
      (entry) => entry.dictionaryRevision >= OfflineDictionary.contentRevision,
    )) {
      return;
    }

    final refreshed = <VocabularyEntry>[];
    final refreshedAt = DateTime.now();
    for (final entry in _entries) {
      if (entry.dictionaryRevision >= OfflineDictionary.contentRevision) {
        refreshed.add(entry);
        continue;
      }

      final result = await _dictionary.lookup(
        entry.sourceText,
        entry.languagePair,
      );
      refreshed.add(
        entry.copyWith(
          senses: result?.senses,
          updatedAt: result == null ? entry.updatedAt : refreshedAt,
          dictionaryRevision: OfflineDictionary.contentRevision,
        ),
      );
    }
    _entries = refreshed;
    if (saveLocally) await _platformBridge.saveEntries(_entries);
  }
}
