import '../../models/vocabulary_entry.dart';

enum ReviewRating { forgot, almost, remembered }

class ReviewScheduler {
  const ReviewScheduler();

  VocabularyEntry schedule(
    VocabularyEntry entry,
    ReviewRating rating,
    DateTime now,
  ) {
    final nextInterval = switch (rating) {
      ReviewRating.forgot => 0,
      ReviewRating.almost => 1,
      ReviewRating.remembered =>
        entry.intervalDays <= 1
            ? 3
            : entry.intervalDays * 2 > 60
            ? 60
            : entry.intervalDays * 2,
    };

    final nextReview = rating == ReviewRating.forgot
        ? now.add(const Duration(minutes: 10))
        : now.add(Duration(days: nextInterval));

    return entry.copyWith(
      reviewCount: entry.reviewCount + 1,
      intervalDays: nextInterval,
      lastReviewedAt: now,
      nextReviewAt: nextReview,
    );
  }
}
