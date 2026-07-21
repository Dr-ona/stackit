import 'package:fsrs/fsrs.dart';

import '../../models/vocabulary_entry.dart';
import 'review_scheduler.dart';

class FsrsScheduler {
  FsrsScheduler({Scheduler? scheduler}) : _scheduler = scheduler ?? Scheduler();

  final Scheduler _scheduler;

  VocabularyEntry schedule(
    VocabularyEntry entry,
    ReviewRating rating,
    DateTime now,
  ) {
    final card = _entryToCard(entry);
    final fsrsRating = _mapRating(rating);
    final result = _scheduler.reviewCard(
      card,
      fsrsRating,
      reviewDateTime: now.toUtc(),
    );
    return _cardToEntry(entry, result.card, now);
  }

  static Rating _mapRating(ReviewRating rating) => switch (rating) {
    ReviewRating.forgot => Rating.again,
    ReviewRating.almost => Rating.hard,
    ReviewRating.remembered => Rating.good,
  };

  static Card _entryToCard(VocabularyEntry entry) {
    final state = _parseState(entry.fsrsState);
    return Card(
      cardId: entry.id.hashCode,
      state: state,
      step: entry.fsrsStep,
      stability: entry.fsrsStability,
      difficulty: entry.fsrsDifficulty,
      due: entry.nextReviewAt?.toUtc(),
      lastReview: entry.lastReviewedAt?.toUtc(),
    );
  }

  static VocabularyEntry _cardToEntry(
    VocabularyEntry entry,
    Card card,
    DateTime now,
  ) {
    final nextReview = card.due.toLocal();
    final stateName = switch (card.state) {
      State.learning => 'learning',
      State.review => 'review',
      State.relearning => 'relearning',
    };
    return entry.copyWith(
      reviewCount: entry.reviewCount + 1,
      intervalDays: nextReview != null
          ? nextReview.difference(now).inDays.clamp(0, 60)
          : 0,
      lastReviewedAt: now,
      nextReviewAt: nextReview,
      fsrsStability: card.stability,
      fsrsDifficulty: card.difficulty,
      fsrsStep: card.step,
      fsrsState: stateName,
    );
  }

  static State _parseState(String state) => switch (state) {
    'learning' => State.learning,
    'review' => State.review,
    'relearning' => State.relearning,
    _ => State.learning,
  };
}
