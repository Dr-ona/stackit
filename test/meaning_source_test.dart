import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  group('VocabularyEntry meaningSource', () {
    test('defaults to offline', () {
      final entry = VocabularyEntry(
        id: '1',
        sourceText: 'hello',
        translations: ['مرحبا'],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        definition: 'A greeting.',
        createdAt: DateTime(2026),
      );
      expect(entry.meaningSource, 'offline');
    });

    test('meaningSource is preserved through JSON round-trip', () {
      final original = VocabularyEntry(
        id: '1',
        sourceText: 'test',
        translations: ['اختبار'],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        definition: 'A test.',
        createdAt: DateTime(2026),
        meaningSource: 'gemini',
      );
      final restored = VocabularyEntry.fromJson(original.toJson());
      expect(restored.meaningSource, 'gemini');
    });

    test('meaningSource is preserved through withSenses JSON round-trip', () {
      final original = VocabularyEntry.withSenses(
        id: '1',
        sourceText: 'test',
        senses: const [
          VocabularySense(
            id: 'sense-1',
            translations: ['اختبار'],
            definition: 'A test.',
          ),
        ],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        createdAt: DateTime(2026),
        meaningSource: 'manual',
      );
      final restored = VocabularyEntry.fromJson(original.toJson());
      expect(restored.meaningSource, 'manual');
    });

    test('copyWith preserves meaningSource', () {
      final original = VocabularyEntry(
        id: '1',
        sourceText: 'test',
        translations: ['t'],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        definition: 'A test.',
        createdAt: DateTime(2026),
        meaningSource: 'gemini',
      );
      final copied = original.copyWith(sourceText: 'updated');
      expect(copied.meaningSource, 'gemini');
    });

    test('copyWith can override meaningSource', () {
      final original = VocabularyEntry(
        id: '1',
        sourceText: 'test',
        translations: ['t'],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        definition: 'A test.',
        createdAt: DateTime(2026),
        meaningSource: 'offline',
      );
      final copied = original.copyWith(meaningSource: 'enriched');
      expect(copied.meaningSource, 'enriched');
    });

    test('fromJson handles missing meaningSource gracefully', () {
      final restored = VocabularyEntry.fromJson({
        'id': '1',
        'sourceText': 'test',
        'createdAt': DateTime(2026).toIso8601String(),
      });
      expect(restored.meaningSource, 'offline');
    });

    test('all four sources work', () {
      for (final source in ['offline', 'gemini', 'manual', 'enriched']) {
        final entry = VocabularyEntry(
          id: '1',
          sourceText: 'test',
          translations: ['t'],
          sourceLanguage: VocabularyLanguage.english,
          targetLanguage: VocabularyLanguage.arabic,
          definition: 'A test.',
          createdAt: DateTime(2026),
          meaningSource: source,
        );
        final restored = VocabularyEntry.fromJson(entry.toJson());
        expect(restored.meaningSource, source);
      }
    });
  });
}
