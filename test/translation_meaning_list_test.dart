import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/vocabulary/translation_meaning_list.dart';
import 'package:stackit/models/language_pair.dart';

void main() {
  testWidgets('renders every alternative as a separate numbered meaning', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TranslationMeaningList(
            translations: ['طعام', 'غذاء', 'مأكل'],
            language: VocabularyLanguage.arabic,
          ),
        ),
      ),
    );

    expect(find.text('طعام'), findsOneWidget);
    expect(find.text('غذاء'), findsOneWidget);
    expect(find.text('مأكل'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
