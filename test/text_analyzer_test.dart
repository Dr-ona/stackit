import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/text_analyzer.dart';

void main() {
  group('TextAnalyzer.classify', () {
    test('single word returns word', () {
      expect(TextAnalyzer.classify('hello'), TextUnit.word);
    });

    test('two words returns phrase', () {
      expect(TextAnalyzer.classify('kick the bucket'), TextUnit.phrase);
    });

    test('single hyphenated word returns word', () {
      expect(TextAnalyzer.classify('state-of-the-art'), TextUnit.word);
    });

    test('empty string returns word', () {
      expect(TextAnalyzer.classify(''), TextUnit.word);
    });

    test('whitespace-only returns word', () {
      expect(TextAnalyzer.classify('   '), TextUnit.word);
    });

    test('leading/trailing whitespace is trimmed', () {
      expect(TextAnalyzer.classify('  hello world  '), TextUnit.phrase);
    });

    test('single character returns word', () {
      expect(TextAnalyzer.classify('a'), TextUnit.word);
    });

    test('word with punctuation is a phrase if multiword', () {
      expect(TextAnalyzer.classify('hello, world'), TextUnit.phrase);
    });
  });

  group('TextAnalyzer.isMultiword', () {
    test('returns false for single word', () {
      expect(TextAnalyzer.isMultiword('bonjour'), false);
    });

    test('returns true for phrase', () {
      expect(TextAnalyzer.isMultiword('bonjour le monde'), true);
    });
  });

  group('TextAnalyzer.wordCount', () {
    test('returns 0 for empty', () {
      expect(TextAnalyzer.wordCount(''), 0);
    });

    test('returns 1 for single word', () {
      expect(TextAnalyzer.wordCount('hello'), 1);
    });

    test('counts words separated by spaces', () {
      expect(TextAnalyzer.wordCount('the quick brown fox'), 4);
    });

    test('handles multiple spaces', () {
      expect(TextAnalyzer.wordCount('hello   world'), 2);
    });
  });

  group('TextAnalyzer.normalizeForSearch', () {
    test('lowercases', () {
      expect(TextAnalyzer.normalizeForSearch('Hello'), 'hello');
    });

    test('strips punctuation', () {
      expect(TextAnalyzer.normalizeForSearch('hello, world!'), 'hello world');
    });

    test('collapses whitespace', () {
      expect(
        TextAnalyzer.normalizeForSearch('  hello   world  '),
        'hello world',
      );
    });

    test('preserves accented characters', () {
      expect(TextAnalyzer.normalizeForSearch('café'), 'café');
    });

    test('preserves Arabic text', () {
      expect(TextAnalyzer.normalizeForSearch('مرحبا'), 'مرحبا');
    });

    test('preserves numbers', () {
      expect(TextAnalyzer.normalizeForSearch('test123'), 'test123');
    });
  });
}
