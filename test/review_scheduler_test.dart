import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/review/review_scheduler.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  const scheduler = ReviewScheduler();
  final now = DateTime.utc(2026, 7, 13, 9);

  VocabularyEntry entry({int intervalDays = 0, int reviewCount = 0}) {
    return VocabularyEntry(
      id: 'word-1',
      term: 'nuance',
      arabic: 'فرق دقيق',
      definition: 'A subtle distinction.',
      createdAt: now.subtract(const Duration(days: 1)),
      intervalDays: intervalDays,
      reviewCount: reviewCount,
    );
  }

  test('forgotten words return in ten minutes', () {
    final scheduled = scheduler.schedule(entry(), ReviewRating.forgot, now);

    expect(scheduled.intervalDays, 0);
    expect(scheduled.nextReviewAt, now.add(const Duration(minutes: 10)));
    expect(scheduled.reviewCount, 1);
  });

  test('almost remembered words return the next day', () {
    final scheduled = scheduler.schedule(entry(), ReviewRating.almost, now);

    expect(scheduled.intervalDays, 1);
    expect(scheduled.nextReviewAt, now.add(const Duration(days: 1)));
  });

  test('remembered words begin at three days then double', () {
    final first = scheduler.schedule(entry(), ReviewRating.remembered, now);
    final later = scheduler.schedule(
      entry(intervalDays: 3, reviewCount: 1),
      ReviewRating.remembered,
      now,
    );

    expect(first.intervalDays, 3);
    expect(later.intervalDays, 6);
    expect(later.nextReviewAt, now.add(const Duration(days: 6)));
  });

  test('remembered intervals are capped at sixty days', () {
    final scheduled = scheduler.schedule(
      entry(intervalDays: 40),
      ReviewRating.remembered,
      now,
    );

    expect(scheduled.intervalDays, 60);
  });
}
