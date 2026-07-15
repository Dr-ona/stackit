import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/features/review/review_scheduler.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores and persists the user-selected language direction', () async {
    final bridge = _MemoryPlatformBridge()
      ..storedPair = LanguagePair.arabicToEnglish;
    final controller = VocabularyController(OfflineDictionary(), bridge);

    await controller.initialize();

    expect(controller.hasChosenLanguagePair, isTrue);
    expect(controller.languagePair, LanguagePair.arabicToEnglish);

    await controller.setLanguagePair(LanguagePair.englishToArabic);
    expect(bridge.storedPair, LanguagePair.englishToArabic);
  });

  test(
    'saves Arabic captures with English equivalents and language codes',
    () async {
      final bridge = _MemoryPlatformBridge()
        ..storedPair = LanguagePair.arabicToEnglish;
      final controller = VocabularyController(OfflineDictionary(), bridge);
      await controller.initialize();

      const text = 'صَعْبُ المَنَالِ';
      final result = await controller.lookup(text);
      await controller.save(const CapturePayload(text: text), result);

      final entry = controller.entries.single;
      expect(entry.sourceLanguage, VocabularyLanguage.arabic);
      expect(entry.targetLanguage, VocabularyLanguage.english);
      expect(entry.translations, contains('elusive'));
    },
  );

  test(
    'refreshes old saved entries from the current dictionary revision',
    () async {
      final bridge = _MemoryPlatformBridge()
        ..storedEntries = [
          VocabularyEntry(
            id: 'legacy-solstice',
            sourceText: 'Solstice',
            translations: const ['الوقت من السنة الذي تكون الأرض أبعد ما'],
            sourceLanguage: VocabularyLanguage.english,
            targetLanguage: VocabularyLanguage.arabic,
            definition: 'Old dictionary value',
            createdAt: DateTime.utc(2026),
            reviewCount: 3,
          ),
        ];
      final controller = VocabularyController(OfflineDictionary(), bridge);

      await controller.initialize();

      final refreshed = controller.entries.single;
      expect(refreshed.translations, ['الانقلاب الشمسي']);
      expect(refreshed.dictionaryRevision, OfflineDictionary.contentRevision);
      expect(refreshed.reviewCount, 3);
      expect(bridge.storedEntries.single.translations, ['الانقلاب الشمسي']);
    },
  );

  test(
    'revision 3 enriches a saved one-value entry with alternatives',
    () async {
      final bridge = _MemoryPlatformBridge()
        ..storedEntries = [
          VocabularyEntry(
            id: 'ultimately',
            sourceText: 'Ultimately',
            translations: const ['في النهاية'],
            sourceLanguage: VocabularyLanguage.english,
            targetLanguage: VocabularyLanguage.arabic,
            definition: 'Old dictionary value',
            createdAt: DateTime.utc(2026),
            dictionaryRevision: 2,
          ),
        ];
      final controller = VocabularyController(OfflineDictionary(), bridge);

      await controller.initialize();

      expect(controller.entries.single.sourceText, 'Ultimately');
      expect(controller.entries.single.translations, [
        'في النهاية',
        'في نهاية المطاف',
        'أخيرًا',
      ]);
      expect(
        controller.entries.single.dictionaryRevision,
        OfflineDictionary.contentRevision,
      );
    },
  );

  test('reviewed words leave Inbox but remain in Library entries', () async {
    final bridge = _MemoryPlatformBridge();
    final controller = VocabularyController(OfflineDictionary(), bridge);
    await controller.initialize();
    final result = await controller.lookup('nuance');
    await controller.save(const CapturePayload(text: 'nuance'), result);

    expect(controller.inboxEntries, hasLength(1));
    expect(controller.entries, hasLength(1));

    await controller.review(
      controller.entries.single,
      ReviewRating.remembered,
      now: DateTime.utc(2026, 7, 15),
    );

    expect(controller.inboxEntries, isEmpty);
    expect(controller.entries, hasLength(1));
  });

  test(
    'capture direction follows the selected text without changing default',
    () async {
      final bridge = _MemoryPlatformBridge()
        ..storedPair = LanguagePair.arabicToEnglish;
      final controller = VocabularyController(OfflineDictionary(), bridge);
      await controller.initialize();

      expect(
        controller.resolveLanguagePair('proprietary'),
        LanguagePair.englishToArabic,
      );
      expect(
        controller.resolveLanguagePair('طعام'),
        LanguagePair.arabicToEnglish,
      );
      expect(
        controller.resolveLanguagePair('food طعام'),
        LanguagePair.arabicToEnglish,
      );
      expect(controller.languagePair, LanguagePair.arabicToEnglish);
    },
  );

  test(
    'auto-detected proprietary capture is found in the reverse dictionary',
    () async {
      final bridge = _MemoryPlatformBridge()
        ..storedPair = LanguagePair.arabicToEnglish;
      final controller = VocabularyController(OfflineDictionary(), bridge);
      await controller.initialize();

      final pair = controller.resolveLanguagePair('proprietary');
      final result = await controller.lookup('proprietary', pair: pair);

      expect(pair, LanguagePair.englishToArabic);
      expect(result?.translations, contains('الملكية'));
    },
  );
}

class _MemoryPlatformBridge extends PlatformBridge {
  LanguagePair? storedPair;
  List<VocabularyEntry> storedEntries = const [];

  @override
  Future<LanguagePair?> loadLanguagePair() async => storedPair;

  @override
  Future<void> saveLanguagePair(LanguagePair pair) async {
    storedPair = pair;
  }

  @override
  Future<CapturePayload?> takeInitialSelection() async => null;

  @override
  Future<List<VocabularyEntry>> loadEntries() async => storedEntries;

  @override
  Future<void> saveEntries(List<VocabularyEntry> entries) async {
    storedEntries = List.unmodifiable(entries);
  }
}
