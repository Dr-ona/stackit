import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

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
    );
    final restored = VocabularyEntry.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.sourceText, original.sourceText);
    expect(restored.translations, original.translations);
    expect(restored.languagePair, LanguagePair.englishToArabic);
    expect(restored.createdAt, createdAt);
    expect(restored.source, 'reader');
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
  });
}
