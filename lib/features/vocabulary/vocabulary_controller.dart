import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/offline_dictionary.dart';
import '../../data/platform_bridge.dart';
import '../../data/contextual_explanation_provider.dart';
import '../../data/review_notification_service.dart';
import '../../data/vocabulary_cloud_store.dart';
import '../../models/capture_payload.dart';
import '../../models/dictionary_result.dart';
import '../../models/language_pair.dart';
import '../../models/vocabulary_entry.dart';
import '../review/review_scheduler.dart';

class VocabularyController extends ChangeNotifier {
  VocabularyController(
    this._dictionary,
    this._platformBridge, [
    this._cloudStore,
    this._contextualExplanationService,
    this._reviewNotificationService,
  ]);

  final OfflineDictionary _dictionary;
  final PlatformBridge _platformBridge;
  final VocabularyCloudStore? _cloudStore;
  final ContextualExplanationService? _contextualExplanationService;
  final ReviewNotificationService? _reviewNotificationService;
  final ReviewScheduler _reviewScheduler = const ReviewScheduler();

  List<VocabularyEntry> _entries = const [];
  CapturePayload? _pendingCapture;
  bool _isReady = false;
  bool _isSyncing = false;
  String? _activeUserId;
  String? _cloudSyncError;
  LanguagePair _languagePair = LanguagePair.englishToArabic;
  bool _hasChosenLanguagePair = false;
  bool _reviewRemindersEnabled = false;
  String? _explainingEntryId;

  List<VocabularyEntry> get entries => List.unmodifiable(_entries);
  List<VocabularyEntry> get inboxEntries =>
      List.unmodifiable(_entries.where((entry) => entry.reviewCount == 0));
  CapturePayload? get pendingCapture => _pendingCapture;
  bool get isReady => _isReady;
  bool get isSyncing => _isSyncing;
  String? get cloudSyncError => _cloudSyncError;
  LanguagePair get languagePair => _languagePair;
  bool get hasChosenLanguagePair => _hasChosenLanguagePair;
  bool get reviewRemindersEnabled => _reviewRemindersEnabled;
  String? get explainingEntryId => _explainingEntryId;

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
    final storedPair = await _platformBridge.loadLanguagePair();
    if (storedPair != null) {
      _languagePair = storedPair;
      _hasChosenLanguagePair = true;
    }
    await _dictionary.load(_languagePair);
    _entries = await _platformBridge.loadEntries();
    _reviewRemindersEnabled = await _platformBridge.loadReviewReminders();
    if (_reviewRemindersEnabled) {
      await _reviewNotificationService?.scheduleDaily();
    }
    await _refreshOutdatedDictionaryEntries();
    _isReady = true;
    notifyListeners();

    final initial = await _platformBridge.takeInitialSelection();
    if (initial != null) await receiveCapture(initial);
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
    _languagePair = pair;
    _hasChosenLanguagePair = true;
    notifyListeners();
    await _platformBridge.saveLanguagePair(pair);
  }

  Future<DictionaryResult?> lookup(String text, {LanguagePair? pair}) {
    return _dictionary.lookup(text, pair ?? _languagePair);
  }

  LanguagePair resolveLanguagePair(String text) {
    return LanguagePair.resolveForText(text, _languagePair);
  }

  bool contains(String text, {LanguagePair? pair}) {
    final selectedPair = pair ?? _languagePair;
    final normalized = text.trim().toLowerCase();
    return _entries.any(
      (entry) =>
          entry.sourceLanguage == selectedPair.source &&
          entry.targetLanguage == selectedPair.target &&
          entry.sourceText.trim().toLowerCase() == normalized,
    );
  }

  Future<void> save(
    CapturePayload capture,
    DictionaryResult? result, {
    LanguagePair? pair,
  }) async {
    final selectedPair =
        pair ??
        (result == null
            ? _languagePair
            : LanguagePair(
                source: result.sourceLanguage,
                target: result.targetLanguage,
              ));
    if (contains(capture.text, pair: selectedPair)) return;
    final now = DateTime.now();
    final entry = VocabularyEntry(
      id: now.microsecondsSinceEpoch.toString(),
      sourceText: capture.text,
      translations:
          result?.translations ??
          [
            selectedPair.target == VocabularyLanguage.arabic
                ? 'بانتظار المعنى'
                : 'Translation pending',
          ],
      sourceLanguage: selectedPair.source,
      targetLanguage: selectedPair.target,
      definition: result?.definition ?? 'Meaning not available offline yet.',
      example: result?.example,
      source: capture.source,
      createdAt: now,
      updatedAt: now,
      dictionaryRevision: OfflineDictionary.contentRevision,
    );
    _entries = [entry, ..._entries];
    notifyListeners();
    await _platformBridge.saveEntries(_entries);
    _queueCloudUpsert(entry);
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
    String? context,
  }) async {
    final service = _contextualExplanationService;
    if (service == null) {
      throw const ContextualExplanationException(
        'Context explanations are not available on this device.',
      );
    }
    _explainingEntryId = entry.id;
    notifyListeners();
    try {
      final explanation = await service.explain(entry, context: context);
      final now = DateTime.now();
      final updated = entry.copyWith(
        contextText: context?.trim(),
        contextualExplanation: explanation.explanation,
        contextualExample: explanation.example,
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
      notifyListeners();
    }
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'format': 'stackit-vocabulary',
    'version': 1,
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
    return true;
  }

  Future<void> deleteAccountData(String userId) async {
    if (_cloudStore != null) await _cloudStore.deleteAllEntries(userId);
    _activeUserId = null;
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
  }

  Future<void> syncForUser(String userId) async {
    if (_cloudStore == null || (_activeUserId == userId && _isSyncing)) return;
    _activeUserId = userId;
    _isSyncing = true;
    _cloudSyncError = null;
    notifyListeners();
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
    } catch (error, stackTrace) {
      _reportCloudError(error, stackTrace);
    } finally {
      if (_activeUserId == userId) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<void> clearAfterSignOut() async {
    _activeUserId = null;
    _cloudSyncError = null;
    _entries = const [];
    await _platformBridge.saveEntries(_entries);
    notifyListeners();
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
    _cloudSyncError = switch (error) {
      FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
        'Offline. Saved locally; sync will retry.',
      FirebaseException(code: 'permission-denied') =>
        'Cloud sync needs attention. Your local words are safe.',
      _ => 'Cloud sync paused. Your local words are safe.',
    };
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
          translations: result?.translations,
          definition: result?.definition,
          example: result?.example,
          updatedAt: result == null ? entry.updatedAt : refreshedAt,
          dictionaryRevision: OfflineDictionary.contentRevision,
        ),
      );
    }
    _entries = refreshed;
    if (saveLocally) await _platformBridge.saveEntries(_entries);
  }
}
