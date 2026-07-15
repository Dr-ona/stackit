import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/features/vocabulary/vocabulary_entry_detail_sheet.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

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
    expect(find.text('Definition'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
  });
}
