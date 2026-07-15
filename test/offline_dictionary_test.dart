import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/models/language_pair.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineDictionary', () {
    test('loads the complete compact FreeDict index', () async {
      final dictionary = OfflineDictionary();

      await dictionary.load();

      expect(dictionary.freeDictEntryCount, 87412);
    });

    test('finds an exact English to Arabic entry', () async {
      final result = await OfflineDictionary().lookup('elusive');
      expect(result, isNotNull);
      expect(result!.translations, contains('صعب المنال'));
    });

    test('normalizes punctuation and casing', () async {
      final result = await OfflineDictionary().lookup('  Nuance! ');
      expect(result?.sourceText, 'nuance');
      expect(result?.translations, ['فَرْق دقيق', 'دلالة خفيّة']);
    });

    test('supports phrases selected by the user', () async {
      final result = await OfflineDictionary().lookup('figure out');
      expect(result?.partOfSpeech, 'phrasal verb');
    });

    test(
      'curated corrections replace incomplete upstream translations',
      () async {
        final result = await OfflineDictionary().lookup('Solstice');

        expect(result?.translations, ['الانقلاب الشمسي']);
      },
    );

    test('returns multiple meanings for a missing hyphenated term', () async {
      final dictionary = OfflineDictionary();

      final hyphenated = await dictionary.lookup('pace-setter');
      final alias = await dictionary.lookup('pacesetter');

      expect(hyphenated?.translations, [
        'مُحدِّد الوتيرة',
        'رائد',
        'واضع المعايير',
      ]);
      expect(alias?.translations, hyphenated?.translations);
    });

    test('returns multiple English meanings for Arabic food', () async {
      final result = await OfflineDictionary().lookup(
        'طعام',
        LanguagePair.arabicToEnglish,
      );

      expect(
        result?.translations,
        containsAll(<String>['food', 'meal', 'fare', 'nourishment']),
      );
    });

    test(
      'returns curated alternatives for previously single-value words',
      () async {
        final dictionary = OfflineDictionary();

        final ultimately = await dictionary.lookup('Ultimately');
        final tournaments = await dictionary.lookup('Tournaments');

        expect(ultimately?.translations, [
          'في النهاية',
          'في نهاية المطاف',
          'أخيرًا',
        ]);
        expect(tournaments?.translations, ['البطولات', 'الدورات', 'المسابقات']);
      },
    );

    test('falls back to an entry outside the curated seed', () async {
      final result = await OfflineDictionary().lookup('Befriend');

      expect(result?.sourceText, 'befriend');
      expect(result?.translations, contains('صادق'));
      expect(result?.definition, 'Offline English–Arabic translation.');
    });

    test('loads and searches the Arabic to English reverse index', () async {
      final dictionary = OfflineDictionary();
      final result = await dictionary.lookup(
        'صَعْبُ المَنَالِ',
        LanguagePair.arabicToEnglish,
      );

      expect(dictionary.entryCountFor(LanguagePair.arabicToEnglish), 52843);
      expect(result?.translations, contains('elusive'));
      expect(result?.targetLanguage, VocabularyLanguage.english);
    });

    test('returns null for unknown text', () async {
      final result = await OfflineDictionary().lookup(
        'not-in-the-seed-lexicon',
      );
      expect(result, isNull);
    });
  });
}
