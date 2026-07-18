import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  test('VocabularyEntry survives local JSON serialization', () {
    final createdAt = DateTime.utc(2026, 7, 13, 8, 30);
    final original = VocabularyEntry(
      id: 'entry-1',
      sourceText: 'nuance',
      translations: const ['فَرْق دقيق', 'دلالة خفيّة'],
      sourceLanguage: VocabularyLanguage.english,
      targetLanguage: VocabularyLanguage.arabic,
      definition: 'A subtle distinction.',
      createdAt: createdAt,
      source: 'reader',
      example: 'Translation can miss the nuance.',
      exampleTranslation: 'قد تفوّت الترجمة الدلالة الدقيقة.',
      contextualExample: 'A nuanced example.',
      contextualExampleTranslation: 'مثال دقيق الدلالة.',
    );
    final restored = VocabularyEntry.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.sourceText, original.sourceText);
    expect(restored.translations, original.translations);
    expect(restored.languagePair, LanguagePair.englishToArabic);
    expect(restored.createdAt, createdAt);
    expect(restored.source, 'reader');
    expect(restored.exampleTranslation, original.exampleTranslation);
    expect(restored.schemaVersion, VocabularyEntry.currentSchemaVersion);
    expect(restored.senses.single.examples, hasLength(1));
    expect(
      restored.contextualExampleTranslation,
      original.contextualExampleTranslation,
    );
  });

  test('older saved entries migrate to an immediately due review', () {
    final restored = VocabularyEntry.fromJson({
      'id': 'legacy-entry',
      'term': 'elusive',
      'arabic': 'صعب المنال',
      'definition': 'Difficult to find.',
      'createdAt': '2026-07-12T10:00:00.000Z',
    });

    expect(restored.reviewCount, 0);
    expect(restored.intervalDays, 0);
    expect(restored.nextReviewAt, isNull);
    expect(restored.isDue(DateTime.utc(2026, 7, 13)), isTrue);
    expect(restored.sourceText, 'elusive');
    expect(restored.translations, ['صعب المنال']);
    expect(restored.languagePair, LanguagePair.englishToArabic);
    expect(restored.exampleTranslation, isNull);
    expect(restored.needsSchemaMigration, isTrue);
    expect(restored.senses, hasLength(1));
  });

  test('multiple senses and paired examples survive JSON serialization', () {
    final original = VocabularyEntry.withSenses(
      id: 'take-off',
      sourceText: 'take off',
      senses: const [
        VocabularySense(
          id: 'aviation',
          translations: ['يُقلِع'],
          definition: 'Leave the ground in an aircraft.',
          examples: [
            VocabularyExample(
              sourceText: 'The plane will take off at noon.',
              translation: 'ستُقلع الطائرة عند الظهر.',
            ),
            VocabularyExample(
              sourceText: 'Our flight took off on time.',
              translation: 'أقلعت رحلتنا في موعدها.',
            ),
          ],
        ),
        VocabularySense(
          id: 'remove',
          translations: ['يَخلع', 'يَنزع'],
          definition: 'Remove something being worn.',
        ),
      ],
      sourceLanguage: VocabularyLanguage.english,
      targetLanguage: VocabularyLanguage.arabic,
      createdAt: DateTime.utc(2026, 7, 16),
    );

    final restored = VocabularyEntry.fromJson(original.toJson());

    expect(restored.senses, hasLength(2));
    expect(restored.senses.first.examples, hasLength(2));
    expect(restored.senses.last.translations, ['يَخلع', 'يَنزع']);
    expect(restored.translations, ['يُقلِع']);
  });
}
