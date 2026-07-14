import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/offline_dictionary.dart';
import '../../data/platform_bridge.dart';
import '../../data/vocabulary_cloud_store.dart';
import '../../models/capture_payload.dart';
import '../../models/dictionary_result.dart';
import '../../models/vocabulary_entry.dart';
import '../review/review_scheduler.dart';

class VocabularyController extends ChangeNotifier {
  VocabularyController(
    this._dictionary,
    this._platformBridge, [
    this._cloudStore,
  ]);

  final OfflineDictionary _dictionary;
  final PlatformBridge _platformBridge;
  final VocabularyCloudStore? _cloudStore;
  final ReviewScheduler _reviewScheduler = const ReviewScheduler();

  List<VocabularyEntry> _entries = const [];
  CapturePayload? _pendingCapture;
  bool _isReady = false;
  bool _isSyncing = false;
  String? _activeUserId;
  String? _cloudSyncError;

  List<VocabularyEntry> get entries => List.unmodifiable(_entries);
  CapturePayload? get pendingCapture => _pendingCapture;
  bool get isReady => _isReady;
  bool get isSyncing => _isSyncing;
  String? get cloudSyncError => _cloudSyncError;

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
    await _dictionary.load();
    _entries = await _platformBridge.loadEntries();
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

  Future<DictionaryResult?> lookup(String text) => _dictionary.lookup(text);

  bool contains(String term) {
    final normalized = term.trim().toLowerCase();
    return _entries.any(
      (entry) => entry.term.trim().toLowerCase() == normalized,
    );
  }

  Future<void> save(CapturePayload capture, DictionaryResult? result) async {
    if (contains(capture.text)) return;
    final now = DateTime.now();
    final entry = VocabularyEntry(
      id: now.microsecondsSinceEpoch.toString(),
      term: capture.text,
      arabic: result?.arabic ?? 'بانتظار المعنى',
      definition: result?.definition ?? 'Meaning not available offline yet.',
      example: result?.example,
      source: capture.source,
      createdAt: now,
      updatedAt: now,
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
      await _platformBridge.saveEntries(_entries);
      await _cloudStore.upsertEntries(userId, _entries);
    } catch (_) {
      _cloudSyncError = 'Cloud sync is unavailable. Local changes are safe.';
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
      } catch (_) {
        _cloudSyncError = 'Cloud sync is unavailable. Local changes are safe.';
        notifyListeners();
      }
    }());
  }

  Future<void> speak(String text) => _platformBridge.speak(text);
}
