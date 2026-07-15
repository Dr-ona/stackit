import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/features/vocabulary/library_entry_tile.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  testWidgets(
    'library entry shows one meaning then expands the remaining ones',
    (tester) async {
      final controller = VocabularyController(
        OfflineDictionary(),
        PlatformBridge(),
      );
      final entry = VocabularyEntry(
        id: 'ultimately',
        sourceText: 'ultimately',
        translations: const ['في النهاية', 'في نهاية المطاف', 'أخيرًا'],
        sourceLanguage: VocabularyLanguage.english,
        targetLanguage: VocabularyLanguage.arabic,
        definition: 'At last; in the end.',
        example: 'Ultimately, the decision was simple.',
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

      expect(find.text('في النهاية'), findsOneWidget);
      expect(find.text('في نهاية المطاف'), findsNothing);
      expect(find.text('أخيرًا'), findsNothing);
      expect(find.text('+2 more meanings — tap to expand'), findsOneWidget);

      await tester.tap(find.text('ultimately'));
      await tester.pumpAndSettle();

      expect(find.text('في نهاية المطاف'), findsOneWidget);
      expect(find.text('أخيرًا'), findsOneWidget);
      expect(find.text('Full details'), findsOneWidget);
    },
  );
}
