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
      expect(
        result?.exampleTranslation,
        'قد تفوّت الترجمة الدلالة الدقيقة لعبارة ما.',
      );
    });

    test('supports phrases selected by the user', () async {
      final result = await OfflineDictionary().lookup('figure out');
      expect(result?.partOfSpeech, 'phrasal verb');
    });

    test(
      'keeps true meanings separate and supports examples per meaning',
      () async {
        final result = await OfflineDictionary().lookup('take off');

        expect(result?.senses, hasLength(3));
        expect(result?.senses.first.id, 'aviation');
        expect(result?.senses.first.examples, hasLength(2));
        expect(result?.senses[1].translations, contains('يَخلع'));
        expect(
          result?.senses[2].translations,
          contains('يُحقّق نجاحًا سريعًا'),
        );
      },
    );

    test('manual stall lookup returns its full curated meaning set', () async {
      final result = await OfflineDictionary().lookup('stall');

      expect(result?.senses, hasLength(6));
      expect(result?.senses.map((sense) => sense.id), contains('engine-stop'));
      expect(result?.senses.expand((sense) => sense.examples), hasLength(6));
      expect(
        result?.senses.expand((sense) => sense.translations),
        containsAll(['كشك', 'مربط', 'يماطل', 'فقدان قوة الرفع']),
      );
    });

    test('same-language study routes work offline', () async {
      final english = await OfflineDictionary().lookup(
        'stall',
        LanguagePair.englishToEnglish,
      );
      final arabic = await OfflineDictionary().lookup(
        'مرحبا',
        LanguagePair.arabicToArabic,
      );
      final french = await OfflineDictionary().lookup(
        'bonjour',
        LanguagePair.frenchToFrench,
      );

      expect(english?.senses, hasLength(6));
      expect(english?.targetLanguage, VocabularyLanguage.english);
      expect(arabic?.translations, ['مرحبا']);
      expect(french?.translations, ['bonjour']);
    });

    test(
      'direct thin routes remain selectable without silent pivoting',
      () async {
        final result = await OfflineDictionary().lookup(
          'مرحبا',
          LanguagePair.arabicToFrench,
        );

        expect(result, isNull);
      },
    );

    test('FreeDict sense boundaries survive the compact index', () async {
      final result = await OfflineDictionary().lookup(
        'Abyssinia',
        LanguagePair.englishToFrench,
      );

      expect(result?.senses, hasLength(2));
      expect(result?.senses[0].translations, ['Abyssinie']);
      expect(result?.senses[1].translations, ['Ethiopie']);
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

    test('loads and searches English to French offline', () async {
      final dictionary = OfflineDictionary();
      final result = await dictionary.lookup(
        'house',
        LanguagePair.englishToFrench,
      );

      expect(dictionary.entryCountFor(LanguagePair.englishToFrench), 8767);
      expect(result?.translations, contains('maison'));
      expect(result?.targetLanguage, VocabularyLanguage.french);
    });

    test('loads and searches French to English offline', () async {
      final dictionary = OfflineDictionary();
      final result = await dictionary.lookup(
        'maison',
        LanguagePair.frenchToEnglish,
      );

      expect(dictionary.entryCountFor(LanguagePair.frenchToEnglish), 8248);
      expect(result?.translations, contains('house'));
      expect(result?.sourceLanguage, VocabularyLanguage.french);
    });

    test('returns null for unknown text', () async {
      final result = await OfflineDictionary().lookup(
        'not-in-the-seed-lexicon',
      );
      expect(result, isNull);
    });
  });
}
