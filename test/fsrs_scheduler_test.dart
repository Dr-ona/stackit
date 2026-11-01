import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/review/fsrs_scheduler.dart';
import 'package:stackit/features/review/review_scheduler.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  final scheduler = FsrsScheduler();
  final now = DateTime(2026, 7, 13, 9);

  VocabularyEntry entry({
    int intervalDays = 0,
    int reviewCount = 0,
    String fsrsState = 'new',
    double? fsrsStability,
    double? fsrsDifficulty,
  }) {
    return VocabularyEntry(
      id: 'word-1',
      sourceText: 'nuance',
      translations: const ['فرق دقيق'],
      sourceLanguage: VocabularyLanguage.english,
      targetLanguage: VocabularyLanguage.arabic,
      definition: 'A subtle distinction.',
      createdAt: now.subtract(const Duration(days: 1)),
      intervalDays: intervalDays,
      reviewCount: reviewCount,
      fsrsState: fsrsState,
      fsrsStability: fsrsStability,
      fsrsDifficulty: fsrsDifficulty,
    );
  }

  test('FSRS increments reviewCount', () {
    final scheduled = scheduler.schedule(entry(), ReviewRating.remembered, now);
    expect(scheduled.reviewCount, 1);
  });

  test('FSRS sets fsrsState to learning for new card on again', () {
    final scheduled = scheduler.schedule(entry(), ReviewRating.forgot, now);
    expect(scheduled.fsrsState, 'learning');
    expect(scheduled.nextReviewAt, isNotNull);
  });

  test('FSRS produces a nextReviewAt for every rating', () {
    for (final rating in ReviewRating.values) {
      final scheduled = scheduler.schedule(entry(), rating, now);
      expect(
        scheduled.nextReviewAt,
        isNotNull,
        reason: 'Rating $rating should produce a nextReviewAt',
      );
    }
  });

  test('FSRS stores stability and difficulty after review', () {
    final scheduled = scheduler.schedule(entry(), ReviewRating.remembered, now);
    expect(scheduled.fsrsStability, isNotNull);
    expect(scheduled.fsrsDifficulty, isNotNull);
  });

  test('FSRS produces monotonically increasing intervals for remembered', () {
    var e = entry();
    var current = now;
    final intervals = <int>[];
    for (var i = 0; i < 5; i++) {
      e = scheduler.schedule(e, ReviewRating.remembered, current);
      intervals.add(e.intervalDays);
      current = e.nextReviewAt!;
    }
    for (var i = 1; i < intervals.length; i++) {
      expect(
        intervals[i],
        greaterThanOrEqualTo(intervals[i - 1]),
        reason: 'Interval $i should be >= interval ${i - 1}',
      );
    }
  });

  test('FSRS entry survives JSON round-trip', () {
    final scheduled = scheduler.schedule(entry(), ReviewRating.remembered, now);
    final json = scheduled.toJson();
    final restored = VocabularyEntry.fromJson(json);

    expect(restored.reviewCount, scheduled.reviewCount);
    expect(restored.intervalDays, scheduled.intervalDays);
    expect(restored.fsrsState, scheduled.fsrsState);
    expect(restored.fsrsStability, scheduled.fsrsStability);
    expect(restored.fsrsDifficulty, scheduled.fsrsDifficulty);
    expect(restored.nextReviewAt, scheduled.nextReviewAt);
  });

  test('FSRS migration derives state from legacy fields', () {
    expect(VocabularyEntry.migrateFsrsState(0, 0), 'new');
    expect(VocabularyEntry.migrateFsrsState(1, 0), 'learning');
    expect(VocabularyEntry.migrateFsrsState(3, 7), 'review');
  });
}
