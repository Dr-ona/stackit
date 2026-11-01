import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/vocabulary/vocabulary_sense_list.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_sense.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

VocabularySense _sense(String id, {String? pos}) => VocabularySense(
  id: id,
  translations: const ['t'],
  definition: 'd',
  partOfSpeech: pos,
);

void main() {
  group('shouldGroup', () {
    test('returns false for fewer than 3 senses', () {
      final senses = [_sense('a', pos: 'noun'), _sense('b', pos: 'verb')];
      expect(VocabularySenseList.shouldGroup(senses), isFalse);
    });

    test('returns false when fewer than 3 have POS', () {
      final senses = [_sense('a', pos: 'noun'), _sense('b'), _sense('c')];
      expect(VocabularySenseList.shouldGroup(senses), isFalse);
    });

    test('returns true when 3+ senses have POS', () {
      final senses = [
        _sense('a', pos: 'noun'),
        _sense('b', pos: 'verb'),
        _sense('c', pos: 'adjective'),
      ];
      expect(VocabularySenseList.shouldGroup(senses), isTrue);
    });

    test('returns true with mix of tagged and untagged', () {
      final senses = [
        _sense('a', pos: 'noun'),
        _sense('b', pos: 'verb'),
        _sense('c', pos: 'adjective'),
        _sense('d'),
      ];
      expect(VocabularySenseList.shouldGroup(senses), isTrue);
    });
  });

  testWidgets('flat mode renders senses in order without section headers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        VocabularySenseList(
          senses: [
            _sense('a', pos: 'noun'),
            _sense('b', pos: 'verb'),
          ],
          sourceText: 'test',
          sourceLanguage: VocabularyLanguage.english,
          targetLanguage: VocabularyLanguage.arabic,
          groupByPartOfSpeech: false,
        ),
      ),
    );

    expect(find.text('Meaning 1 of 2'), findsOneWidget);
    expect(find.text('Meaning 2 of 2'), findsOneWidget);
    expect(find.text('Noun'), findsNothing);
    expect(find.text('Verb'), findsNothing);
  });

  testWidgets('grouped mode shows POS section headers', (tester) async {
    await tester.pumpWidget(
      _wrap(
        VocabularySenseList(
          senses: [
            _sense('a', pos: 'noun'),
            _sense('b', pos: 'verb'),
            _sense('c', pos: 'noun'),
            _sense('d', pos: 'verb'),
          ],
          sourceText: 'test',
          sourceLanguage: VocabularyLanguage.english,
          targetLanguage: VocabularyLanguage.arabic,
          groupByPartOfSpeech: true,
        ),
      ),
    );

    expect(find.text('Noun'), findsOneWidget);
    expect(find.text('Verb'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));
  });

  testWidgets('grouped mode puts null-POS senses under Other', (tester) async {
    await tester.pumpWidget(
      _wrap(
        VocabularySenseList(
          senses: [
            _sense('a', pos: 'noun'),
            _sense('b'),
            _sense('c', pos: 'noun'),
          ],
          sourceText: 'test',
          sourceLanguage: VocabularyLanguage.english,
          targetLanguage: VocabularyLanguage.arabic,
          groupByPartOfSpeech: true,
        ),
      ),
    );

    expect(find.text('Noun'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('grouped mode preserves global meaning numbering', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        VocabularySenseList(
          senses: [
            _sense('a', pos: 'verb'),
            _sense('b', pos: 'noun'),
            _sense('c', pos: 'noun'),
          ],
          sourceText: 'test',
          sourceLanguage: VocabularyLanguage.english,
          targetLanguage: VocabularyLanguage.arabic,
          groupByPartOfSpeech: true,
        ),
      ),
    );

    expect(find.text('Meaning 1 of 3'), findsOneWidget);
    expect(find.text('Meaning 2 of 3'), findsOneWidget);
    expect(find.text('Meaning 3 of 3'), findsOneWidget);
  });
}
