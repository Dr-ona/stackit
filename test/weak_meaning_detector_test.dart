import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/review/weak_meaning_detector.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

VocabularyEntry _entry(
  String id,
  String text, {
  double? fsrsDifficulty,
  double? fsrsStability,
  String fsrsState = 'new',
  int reviewCount = 0,
}) {
  return VocabularyEntry.withSenses(
    id: id,
    sourceText: text,
    senses: [
      VocabularySense(
        id: '$id-s1',
        translations: ['翻译'],
        definition: 'definition $text',
      ),
    ],
    sourceLanguage: VocabularyLanguage.english,
    targetLanguage: VocabularyLanguage.arabic,
    createdAt: DateTime(2025),
    reviewCount: reviewCount,
    fsrsDifficulty: fsrsDifficulty,
    fsrsStability: fsrsStability,
    fsrsState: fsrsState,
    meaningSource: 'offline',
  );
}

void main() {
  group('WeakMeaningDetector', () {
    const detector = WeakMeaningDetector();

    test('returns empty for entries with no signals', () {
      final entries = [
        _entry('1', 'cat', fsrsState: 'new'),
        _entry('2', 'dog', fsrsState: 'new'),
      ];
      final weaknesses = detector.detect(entries: entries);
      expect(weaknesses, isEmpty);
    });

    test('detects high difficulty', () {
      final entries = [
        _entry('1', 'cat', fsrsDifficulty: 0.85, fsrsState: 'review'),
      ];
      final weaknesses = detector.detect(entries: entries);
      expect(weaknesses, hasLength(1));
      expect(
        weaknesses.first.reasons.any((r) => r.contains('High difficulty')),
        isTrue,
      );
      expect(weaknesses.first.severity, greaterThan(0));
    });

    test('detects low stability', () {
      final entries = [
        _entry('1', 'cat', fsrsStability: 0.5, fsrsState: 'review'),
      ];
      final weaknesses = detector.detect(entries: entries);
      expect(weaknesses, hasLength(1));
      expect(
        weaknesses.first.reasons.any((r) => r.contains('Low stability')),
        isTrue,
      );
    });

    test('detects relearning state', () {
      final entries = [_entry('1', 'cat', fsrsState: 'relearning')];
      final weaknesses = detector.detect(entries: entries);
      expect(weaknesses, hasLength(1));
      expect(
        weaknesses.first.reasons.any((r) => r.contains('relearning')),
        isTrue,
      );
    });

    test('detects stuck in learning after many reviews', () {
      final entries = [
        _entry('1', 'cat', fsrsState: 'learning', reviewCount: 5),
      ];
      final weaknesses = detector.detect(entries: entries);
      expect(weaknesses, hasLength(1));
      expect(
        weaknesses.first.reasons.any((r) => r.contains('Still in learning')),
        isTrue,
      );
    });

    test('detects high error counts', () {
      final entries = [_entry('1', 'cat')];
      final errors = {'1-s1': 4};
      final weaknesses = detector.detect(
        entries: entries,
        senseErrorCounts: errors,
      );
      expect(weaknesses, hasLength(1));
      expect(
        weaknesses.first.reasons.any((r) => r.contains('4 recent errors')),
        isTrue,
      );
    });

    test('combines multiple signals for severity', () {
      final entries = [
        _entry(
          '1',
          'cat',
          fsrsDifficulty: 0.9,
          fsrsStability: 0.3,
          fsrsState: 'relearning',
        ),
      ];
      final weaknesses = detector.detect(entries: entries);
      expect(weaknesses, hasLength(1));
      expect(weaknesses.first.reasons.length, greaterThanOrEqualTo(2));
      expect(weaknesses.first.severity, greaterThan(0.5));
    });

    test('severity is clamped to 1.0', () {
      final entries = [
        _entry(
          '1',
          'cat',
          fsrsDifficulty: 1.0,
          fsrsStability: 0.1,
          fsrsState: 'relearning',
        ),
      ];
      final errors = {'1-s1': 10};
      final weaknesses = detector.detect(
        entries: entries,
        senseErrorCounts: errors,
      );
      expect(weaknesses.first.severity, lessThanOrEqualTo(1.0));
    });

    test('returns results sorted by severity descending', () {
      final entries = [
        _entry('1', 'easy', fsrsDifficulty: 0.65, fsrsState: 'review'),
        _entry('2', 'hard', fsrsState: 'relearning'),
      ];
      final weaknesses = detector.detect(entries: entries);
      if (weaknesses.length >= 2) {
        expect(
          weaknesses[0].severity,
          greaterThanOrEqualTo(weaknesses[1].severity),
        );
      }
    });
  });

  group('WeakMeaningDetector prioritizeWeak', () {
    const detector = WeakMeaningDetector();

    test('weak entries come first', () {
      final entries = [
        _entry('1', 'easy', fsrsState: 'review'),
        _entry('2', 'hard', fsrsState: 'relearning'),
      ];
      final prioritized = detector.prioritizeWeak(entries);
      expect(prioritized.first.sourceText, 'hard');
    });

    test('all entries returned when none are weak', () {
      final entries = [
        _entry('1', 'cat', fsrsState: 'new'),
        _entry('2', 'dog', fsrsState: 'new'),
      ];
      final prioritized = detector.prioritizeWeak(entries);
      expect(prioritized.length, 2);
    });
  });

  group('WeakMeaningDetector summarizePatterns', () {
    const detector = WeakMeaningDetector();

    test('summarizes common patterns', () {
      final weaknesses = [
        SenseWeakness(
          entryId: '1',
          senseId: 's1',
          sourceText: 'cat',
          definition: 'feline',
          reasons: ['High difficulty (0.85)', 'Low stability (0.5 days)'],
          severity: 0.7,
        ),
        SenseWeakness(
          entryId: '2',
          senseId: 's2',
          sourceText: 'dog',
          definition: 'canine',
          reasons: ['High difficulty (0.72)'],
          severity: 0.6,
        ),
      ];
      final summary = detector.summarizePatterns(weaknesses);
      expect(summary, containsPair('High difficulty', '2 senses affected'));
      expect(summary, containsPair('Low stability', '1 sense affected'));
    });

    test('returns empty map for empty weaknesses', () {
      final summary = detector.summarizePatterns(const []);
      expect(summary, isEmpty);
    });
  });
}
