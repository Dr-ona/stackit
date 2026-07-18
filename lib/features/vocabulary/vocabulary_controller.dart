import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/offline_dictionary.dart';
import '../../data/analytics_service.dart';
import '../../data/platform_bridge.dart';
import '../../l10n/app_localizations.dart';
import '../../data/profile_avatar_store.dart';
import '../../data/crash_reporter.dart';
import '../../data/contextual_explanation_provider.dart';
import '../../data/meaning_discovery_provider.dart';
import '../../data/review_notification_service.dart';
import '../../data/user_profile_cloud_store.dart';
import '../../data/vocabulary_cloud_store.dart';
import '../../models/capture_payload.dart';
import '../../models/dictionary_result.dart';
import '../../models/language_pair.dart';
import '../../models/user_profile.dart';
import '../../models/vocabulary_entry.dart';
import '../../models/vocabulary_sense.dart';
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
  final ReviewScheduler _reviewScheduler = const ReviewScheduler();

  List<VocabularyEntry> _entries = const [];
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

  List<VocabularyEntry> get entries => List.unmodifiable(_entries);
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
  ui.Locale get _locale => ui.PlatformDispatcher.instance.locale;
  int get reviewedCount =>
      _entries.where((entry) => entry.reviewCount > 0).length;
  int get masteredCount => _entries
      .where((entry) => entry.reviewCount >= 5 && entry.intervalDays >= 14)
      .length;
  int get dueCount => dueEntries(limit: _entries.length).length;

  List<VocabularyEntry> dueEntries({DateTime? now, int limit = 5}) {
    final reviewTime = now ?? DateTime.now();
    final due = _entries.where((entry) => entry.isDue(reviewTime)).toList()
      ..sort((a, b) {
        final aDue = a.nextReviewAt ?? a.createdAt;
        final bDue = b.nextReviewAt ?? b.createdAt;
        return aDue.compareTo(bDue);
      });
    return due.take(limit).toList(growable: false);
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
          .map((entry) => entry.copyWith(senses: entry.senses))
          .toList(growable: false);
      await _platformBridge.saveEntries(_entries);
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

  Future<DictionaryResult?> lookup(String text, {LanguagePair? pair}) {
    return _dictionary.lookup(text, pair ?? languagePair);
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
      createdAt: now,
      updatedAt: now,
      dictionaryRevision: OfflineDictionary.contentRevision,
    );
    _entries = [entry, ..._entries];
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
    _queueCloudUpsert(entry);
    if (_entries.length == 1) {
      _analyticsService?.logFirstSave();
    }
  }

  Future<void> delete(String id) async {
    _entries = _entries.where((entry) => entry.id != id).toList();
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
    final userId = _activeUserId;
    if (userId != null && _cloudStore != null) {
      _queueCloudWrite(_cloudStore.deleteEntry(userId, id));
    }
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
      throw ProfileAvatarException(
        AppLocalizations.signInFirst(_locale),
      );
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
      );
      final updated = entry.copyWith(
        senses: result.senses,
        updatedAt: DateTime.now(),
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
    return _platformBridge.speak(text, language);
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
