import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/data/contextual_explanation_provider.dart';
import 'package:stackit/data/meaning_discovery_provider.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/features/vocabulary/vocabulary_entry_detail_sheet.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/contextual_explanation.dart';
import 'package:stackit/models/dictionary_result.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/user_profile.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a saved entry opens with all stored alternatives and details', (
    tester,
  ) async {
    final controller = VocabularyController(
      OfflineDictionary(),
      PlatformBridge(),
    );
    final entry = VocabularyEntry(
      id: 'pace-setter',
      sourceText: 'pace-setter',
      translations: const ['مُحدِّد الوتيرة', 'رائد', 'واضع المعايير'],
      sourceLanguage: VocabularyLanguage.english,
      targetLanguage: VocabularyLanguage.arabic,
      definition: 'A person or thing that establishes the pace or standard.',
      example: 'The company became a pace-setter.',
      createdAt: DateTime.utc(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showVocabularyEntryDetails(
                context,
                entry: entry,
                controller: controller,
              ),
              child: const Text('Open saved word'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open saved word'));
    await tester.pumpAndSettle();

    expect(find.text('pace-setter'), findsOneWidget);
    expect(find.text('مُحدِّد الوتيرة'), findsOneWidget);
    expect(find.text('رائد'), findsOneWidget);
    expect(find.text('واضع المعايير'), findsOneWidget);
    expect(find.text('Meaning'), findsOneWidget);
    expect(find.text('Examples'), findsOneWidget);
  });

  testWidgets(
    'Gemini context dialog completes without disposing dependencies',
    (tester) async {
      final entry = VocabularyEntry(
        id: 'nuance',
        sourceText: 'nuance',
        translations: const ['فارق دقيق'],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        definition: 'A subtle distinction.',
        createdAt: DateTime.utc(2026),
      );
      final bridge = _EntryBridge()..entries = [entry];
      final controller = VocabularyController(
        OfflineDictionary(),
        bridge,
        null,
        _ExplanationService(),
      );
      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showVocabularyEntryDetails(
                  context,
                  entry: entry,
                  controller: controller,
                ),
                child: const Text('Open Gemini word'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Gemini word'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Explain this meaning with Gemini'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'A subtle difference.',
      );
      await tester.tap(find.text('Explain'));
      await tester.pumpAndSettle();

      expect(find.text('شرح سياقي'), findsOneWidget);
      expect(
        find.text('“A nuanced example.”', findRichText: true),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('thin manual entry can discover and persist full meanings', (
    tester,
  ) async {
    final entry = VocabularyEntry(
      id: 'craven',
      sourceText: 'craven',
      source: CapturePayload.manualSource,
      translations: const ['جبان'],
      sourceLanguage: VocabularyLanguage.english,
      targetLanguage: VocabularyLanguage.arabic,
      definition: 'Offline English–Arabic translation.',
      createdAt: DateTime.utc(2026),
      dictionaryRevision: OfflineDictionary.contentRevision,
    );
    final bridge = _EntryBridge()..entries = [entry];
    final controller = VocabularyController(
      OfflineDictionary(),
      bridge,
      null,
      null,
      null,
      null,
      _MeaningService(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showVocabularyEntryDetails(
                context,
                entry: entry,
                controller: controller,
              ),
              child: const Text('Open thin word'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open thin word'));
    await tester.pumpAndSettle();
    expect(find.text('Find all meanings'), findsOneWidget);

    await tester.tap(find.text('Find all meanings'));
    await tester.pumpAndSettle();

    expect(find.text('2 verified meanings'), findsOneWidget);
    expect(find.text('جبان'), findsWidgets);
    expect(find.text('دنيء'), findsOneWidget);
    expect(
      find.text(
        '“His craven refusal disappointed the team.”',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(bridge.entries.single.senses, hasLength(2));
    expect(bridge.entries.single.id, entry.id);
  });
}

class _EntryBridge extends PlatformBridge {
  List<VocabularyEntry> entries = const [];

  @override
  Future<VocabularyLanguage?> loadInterfaceLanguage() async => null;

  @override
  Future<LanguagePair?> loadLanguagePair() async => null;

  @override
  Future<VocabularyLanguage?> loadPreferredTargetLanguage() async =>
      VocabularyLanguage.arabic;

  @override
  Future<List<VocabularyEntry>> loadEntries() async => entries;

  @override
  Future<void> saveEntries(List<VocabularyEntry> entries) async {
    this.entries = List.unmodifiable(entries);
  }

  @override
  Future<CapturePayload?> takeInitialSelection() async => null;

  @override
  Future<bool> loadReviewReminders() async => false;

  @override
  Future<UserProfile?> loadUserProfile({String? userId}) async => null;
}

class _ExplanationService implements ContextualExplanationService {
  @override
  Future<ContextualExplanation> explain(
    VocabularyEntry entry, {
    String? senseId,
    String? context,
  }) async {
    return const ContextualExplanation(
      explanation: 'شرح سياقي',
      example: 'A nuanced example.',
      exampleTranslation: 'مثال دقيق الدلالة.',
      relatedPhrases: ['subtle difference — فرق طفيف'],
    );
  }
}

class _MeaningService implements MeaningDiscoveryService {
  @override
  Future<DictionaryResult> discoverAllMeanings(
    String text, {
    required LanguagePair pair,
    DictionaryResult? offlineResult,
    String? context,
  }) async {
    return DictionaryResult.withSenses(
      sourceText: text,
      senses: const [
        VocabularySense(
          id: 'cowardly',
          translations: ['جبان'],
          definition: 'Lacking courage; cowardly.',
          partOfSpeech: 'adjective',
          examples: [
            VocabularyExample(
              sourceText: 'His craven refusal disappointed the team.',
              translation: 'خيّب رفضه الجبان أمل الفريق.',
            ),
          ],
        ),
        VocabularySense(
          id: 'contemptible',
          translations: ['دنيء'],
          definition: 'Contemptibly lacking courage.',
          partOfSpeech: 'adjective',
        ),
      ],
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
    );
  }
}
