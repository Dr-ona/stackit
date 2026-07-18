import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/vocabulary_entry.dart';
import '../models/language_pair.dart';
import '../models/vocabulary_sense.dart';

abstract interface class VocabularyCloudStore {
  Future<List<VocabularyEntry>> loadEntries(String userId);

  Future<void> upsertEntry(String userId, VocabularyEntry entry);

  Future<void> upsertEntries(String userId, Iterable<VocabularyEntry> entries);

  Future<void> deleteEntry(String userId, String entryId);

  Future<void> deleteAllEntries(String userId);
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

  @override
  Future<void> deleteAllEntries(String userId) async {
    while (true) {
      final snapshot = await _entries(userId).limit(400).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  Map<String, dynamic> _toFirestore(VocabularyEntry entry) {
    return {
      'schemaVersion': VocabularyEntry.currentSchemaVersion,
      'sourceText': entry.sourceText,
      'senses': entry.senses
          .map((sense) => sense.toJson())
          .toList(growable: false),
      'translations': entry.translations,
      'sourceLanguage': entry.sourceLanguage.code,
      'targetLanguage': entry.targetLanguage.code,
      'definition': entry.definition,
      'createdAt': Timestamp.fromDate(entry.createdAt),
      'updatedAt': Timestamp.fromDate(entry.effectiveUpdatedAt),
      'source': entry.source,
      'example': entry.example,
      'exampleTranslation': entry.exampleTranslation,
      'contextText': entry.contextText,
      'contextualExplanation': entry.contextualExplanation,
      'contextualExample': entry.contextualExample,
      'contextualExampleTranslation': entry.contextualExampleTranslation,
      'contextualSenseId': entry.contextualSenseId,
      'relatedPhrases': entry.relatedPhrases,
      'reviewCount': entry.reviewCount,
      'intervalDays': entry.intervalDays,
      'nextReviewAt': _timestamp(entry.nextReviewAt),
      'lastReviewedAt': _timestamp(entry.lastReviewedAt),
      'dictionaryRevision': entry.dictionaryRevision,
    };
  }

  VocabularyEntry _fromFirestore(String id, Map<String, dynamic> data) {
    final legacyTranslation = data['arabic'] as String?;
    final translations = switch (data['translations']) {
      final List<dynamic> values => values.whereType<String>().toList(
        growable: false,
      ),
      _ when legacyTranslation != null =>
        legacyTranslation
            .split(RegExp(r'\s*[؛;]\s*'))
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false),
      _ => const <String>[],
    };
    final parsedSenses = switch (data['senses']) {
      final List<dynamic> values =>
        values
            .whereType<Map>()
            .map(
              (value) =>
                  VocabularySense.fromJson(value.cast<String, Object?>()),
            )
            .where(
              (sense) =>
                  sense.translations.isNotEmpty && sense.definition.isNotEmpty,
            )
            .toList(growable: false),
      _ => const <VocabularySense>[],
    };
    return VocabularyEntry.withSenses(
      id: id,
      sourceText:
          data['sourceText'] as String? ?? data['term'] as String? ?? '',
      senses: parsedSenses.isNotEmpty
          ? parsedSenses
          : [
              VocabularySense.legacy(
                translations: translations.isEmpty
                    ? const ['Translation pending']
                    : translations,
                definition:
                    data['definition'] as String? ??
                    'Meaning not available offline yet.',
                example: data['example'] as String?,
                exampleTranslation: data['exampleTranslation'] as String?,
              ),
            ],
      sourceLanguage: VocabularyLanguage.fromCode(
        data['sourceLanguage'] as String? ?? 'en',
      ),
      targetLanguage: VocabularyLanguage.fromCode(
        data['targetLanguage'] as String? ?? 'ar',
      ),
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      updatedAt: _date(data['updatedAt']),
      source: data['source'] as String?,
      contextText: data['contextText'] as String?,
      contextualExplanation: data['contextualExplanation'] as String?,
      contextualExample: data['contextualExample'] as String?,
      contextualExampleTranslation:
          data['contextualExampleTranslation'] as String?,
      contextualSenseId: data['contextualSenseId'] as String?,
      relatedPhrases: switch (data['relatedPhrases']) {
        final List<dynamic> values => values.whereType<String>().toList(
          growable: false,
        ),
        _ => const [],
      },
      reviewCount: data['reviewCount'] as int? ?? 0,
      intervalDays: data['intervalDays'] as int? ?? 0,
      nextReviewAt: _date(data['nextReviewAt']),
      lastReviewedAt: _date(data['lastReviewedAt']),
      dictionaryRevision: data['dictionaryRevision'] as int? ?? 0,
      schemaVersion: parsedSenses.isEmpty
          ? 1
          : data['schemaVersion'] as int? ??
                VocabularyEntry.currentSchemaVersion,
    );
  }

  Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  DateTime? _date(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
