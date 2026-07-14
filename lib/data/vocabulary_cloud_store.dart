import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/vocabulary_entry.dart';

abstract interface class VocabularyCloudStore {
  Future<List<VocabularyEntry>> loadEntries(String userId);

  Future<void> upsertEntry(String userId, VocabularyEntry entry);

  Future<void> upsertEntries(String userId, Iterable<VocabularyEntry> entries);

  Future<void> deleteEntry(String userId, String entryId);
}

class FirestoreVocabularyCloudStore implements VocabularyCloudStore {
  FirestoreVocabularyCloudStore({FirebaseFirestore? firestore})
    : _firestore =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'stackit',
          );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entries(String userId) {
    return _firestore.collection('users').doc(userId).collection('vocabulary');
  }

  @override
  Future<List<VocabularyEntry>> loadEntries(String userId) async {
    final snapshot = await _entries(userId).get();
    final entries = snapshot.docs
        .map((document) => _fromFirestore(document.id, document.data()))
        .toList(growable: false);
    return entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> upsertEntry(String userId, VocabularyEntry entry) {
    return _entries(
      userId,
    ).doc(entry.id).set(_toFirestore(entry), SetOptions(merge: false));
  }

  @override
  Future<void> upsertEntries(
    String userId,
    Iterable<VocabularyEntry> entries,
  ) async {
    var batch = _firestore.batch();
    var operationCount = 0;
    for (final entry in entries) {
      batch.set(_entries(userId).doc(entry.id), _toFirestore(entry));
      operationCount++;
      if (operationCount == 400) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }
    if (operationCount > 0) await batch.commit();
  }

  @override
  Future<void> deleteEntry(String userId, String entryId) {
    return _entries(userId).doc(entryId).delete();
  }

  Map<String, dynamic> _toFirestore(VocabularyEntry entry) {
    return {
      'term': entry.term,
      'arabic': entry.arabic,
      'definition': entry.definition,
      'createdAt': Timestamp.fromDate(entry.createdAt),
      'updatedAt': Timestamp.fromDate(entry.effectiveUpdatedAt),
      'source': entry.source,
      'example': entry.example,
      'reviewCount': entry.reviewCount,
      'intervalDays': entry.intervalDays,
      'nextReviewAt': _timestamp(entry.nextReviewAt),
      'lastReviewedAt': _timestamp(entry.lastReviewedAt),
    };
  }

  VocabularyEntry _fromFirestore(String id, Map<String, dynamic> data) {
    return VocabularyEntry(
      id: id,
      term: data['term'] as String? ?? '',
      arabic: data['arabic'] as String? ?? '',
      definition: data['definition'] as String? ?? '',
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      updatedAt: _date(data['updatedAt']),
      source: data['source'] as String?,
      example: data['example'] as String?,
      reviewCount: data['reviewCount'] as int? ?? 0,
      intervalDays: data['intervalDays'] as int? ?? 0,
      nextReviewAt: _date(data['nextReviewAt']),
      lastReviewedAt: _date(data['lastReviewedAt']),
    );
  }

  Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  DateTime? _date(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
