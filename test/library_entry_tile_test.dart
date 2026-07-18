import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/features/vocabulary/library_entry_tile.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  testWidgets(
    'library entry shows one meaning then expands the remaining ones',
    (tester) async {
      final controller = VocabularyController(
        OfflineDictionary(),
        PlatformBridge(),
      );
      final entry = VocabularyEntry.withSenses(
        id: 'take-off',
        sourceText: 'take off',
        senses: const [
          VocabularySense(
            id: 'aviation',
            translations: ['يُقلِع'],
            definition: 'Leave the ground in an aircraft.',
          ),
          VocabularySense(
            id: 'remove',
            translations: ['يَخلع', 'يَنزع'],
            definition: 'Remove something being worn.',
          ),
          VocabularySense(
            id: 'succeed',
            translations: ['يُحقّق نجاحًا سريعًا'],
            definition: 'Become successful very quickly.',
            examples: [
              VocabularyExample(
                sourceText: 'The product began to take off.',
                translation: 'بدأ المنتج يحقق نجاحًا سريعًا.',
              ),
            ],
          ),
        ],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        createdAt: DateTime.utc(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LibraryEntryTile(entry: entry, controller: controller),
            ),
          ),
        ),
      );

      expect(find.text('يُقلِع'), findsOneWidget);
      expect(find.text('يَخلع'), findsNothing);
      expect(find.text('يُحقّق نجاحًا سريعًا'), findsNothing);
      expect(find.text('+2 more meanings — tap to expand'), findsOneWidget);

      await tester.tap(find.text('take off'));
      await tester.pumpAndSettle();

      expect(find.text('يَخلع'), findsOneWidget);
      expect(find.text('يُحقّق نجاحًا سريعًا'), findsOneWidget);
      expect(find.text('Full details'), findsOneWidget);
      expect(
        find.text('“The product began to take off.”', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('بدأ المنتج يحقق نجاحًا سريعًا.'), findsOneWidget);
    },
  );

  testWidgets('manual library entry starts in full expanded display', (
    tester,
  ) async {
    final controller = VocabularyController(
      OfflineDictionary(),
      PlatformBridge(),
    );
    final entry = VocabularyEntry.withSenses(
      id: 'manual-stall',
      sourceText: 'stall',
      source: 'manual',
      senses: const [
        VocabularySense(
          id: 'delay',
          translations: ['يؤخّر'],
          definition: 'Delay or obstruct progress.',
        ),
        VocabularySense(
          id: 'booth',
          translations: ['كشك'],
          definition: 'A small booth or stand.',
          examples: [
            VocabularyExample(
              sourceText: 'We stopped at a market stall.',
              translation: 'توقفنا عند كشك في السوق.',
            ),
          ],
        ),
      ],
      sourceLanguage: VocabularyLanguage.english,
      targetLanguage: VocabularyLanguage.arabic,
      createdAt: DateTime.utc(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LibraryEntryTile(entry: entry, controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('يؤخّر'), findsWidgets);
    expect(find.text('كشك'), findsOneWidget);
    expect(find.text('Delay or obstruct progress.'), findsOneWidget);
    expect(find.text('A small booth or stand.'), findsOneWidget);
    expect(
      find.text('“We stopped at a market stall.”', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('توقفنا عند كشك في السوق.'), findsOneWidget);
    expect(find.text('Full details'), findsOneWidget);
  });
}
