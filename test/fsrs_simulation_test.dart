import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/review/fsrs_scheduler.dart';
import 'package:stackit/features/review/review_scheduler.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

VocabularyEntry _entry(String id, {DateTime? createdAt, DateTime? now}) {
  final t = now ?? DateTime(2026, 1, 1);
  return VocabularyEntry(
    id: id,
    sourceText: 'word_$id',
    translations: const ['def'],
    sourceLanguage: VocabularyLanguage.english,
    targetLanguage: VocabularyLanguage.arabic,
    definition: 'A meaning.',
    createdAt: createdAt ?? t.subtract(const Duration(days: 1)),
  );
}

/// Simulates a session where every review is [rating], advancing time
/// to each nextReviewAt (or +1 day if none).
List<VocabularyEntry> _simulate(
  VocabularyEntry start,
  ReviewRating rating, {
  required int days,
  required FsrsScheduler scheduler,
}) {
  final history = <VocabularyEntry>[start];
  var current = start;
  var day = 0;
  while (day < days) {
    final now = DateTime(2026, 1, 1).add(Duration(days: day));
    current = scheduler.schedule(current, rating, now);
    history.add(current);
    final next = current.nextReviewAt;
    if (next != null) {
      day = next.difference(DateTime(2026, 1, 1)).inDays;
    } else {
      day += 1;
    }
    if (day > days) break;
  }
  return history;
}

void main() {
  final scheduler = FsrsScheduler();

  group('30-day consistent good reviews', () {
    test('interval grows monotonically over 30 days', () {
      final history = _simulate(
        _entry('g1'),
        ReviewRating.remembered,
        days: 30,
        scheduler: scheduler,
      );
      final intervals = history.map((e) => e.intervalDays).toList();
      for (var i = 1; i < intervals.length; i++) {
        expect(
          intervals[i],
          greaterThanOrEqualTo(intervals[i - 1]),
          reason:
              'Interval $i (${intervals[i]}) should be >= ${intervals[i - 1]}',
        );
      }
    });

    test('stability increases with consecutive good reviews', () {
      final history = _simulate(
        _entry('g2'),
        ReviewRating.remembered,
        days: 30,
        scheduler: scheduler,
      );
      final stabilities = history
          .where((e) => e.fsrsStability != null)
          .map((e) => e.fsrsStability!)
          .toList();
      for (var i = 1; i < stabilities.length; i++) {
        expect(
          stabilities[i],
          greaterThanOrEqualTo(stabilities[i - 1]),
          reason: 'Stability $i should be >= ${stabilities[i - 1]}',
        );
      }
    });

    test('card moves from learning to review state', () {
      final history = _simulate(
        _entry('g3'),
        ReviewRating.remembered,
        days: 30,
        scheduler: scheduler,
      );
      final states = history.map((e) => e.fsrsState).toSet();
      expect(states, contains('review'));
    });

    test('reviewCount equals number of schedule calls', () {
      final history = _simulate(
        _entry('g4'),
        ReviewRating.remembered,
        days: 30,
        scheduler: scheduler,
      );
      expect(history.first.reviewCount, 0);
      expect(history.last.reviewCount, history.length - 1);
    });
  });

  group('mixed rating patterns', () {
    test('alternating good/forget produces valid scheduling', () {
      var current = _entry('m1');
      final ratings = [
        ReviewRating.remembered,
        ReviewRating.forgot,
        ReviewRating.remembered,
        ReviewRating.remembered,
        ReviewRating.forgot,
        ReviewRating.remembered,
      ];
      for (var i = 0; i < ratings.length; i++) {
        final now = DateTime(2026, 1, 1).add(Duration(days: i));
        current = scheduler.schedule(current, ratings[i], now);
        expect(
          current.nextReviewAt,
          isNotNull,
          reason: 'Step $i must have nextReviewAt',
        );
        expect(
          current.fsrsState,
          isNotEmpty,
          reason: 'Step $i must have fsrsState',
        );
      }
      expect(current.reviewCount, ratings.length);
    });

    test(
      'all-hard reviews produce valid scheduling with shorter intervals than all-good',
      () {
        var hard = _entry('hard');
        var good = _entry('good');
        final now = DateTime(2026, 1, 1);
        for (var i = 0; i < 6; i++) {
          final t = now.add(Duration(days: i * 3));
          hard = scheduler.schedule(hard, ReviewRating.almost, t);
          good = scheduler.schedule(good, ReviewRating.remembered, t);
        }
        expect(
          hard.intervalDays,
          lessThanOrEqualTo(good.intervalDays),
          reason: 'Hard intervals should be shorter than good intervals',
        );
      },
    );

    test('card reenters relearning after forgetting in review state', () {
      var e = _entry('re');
      final now = DateTime(2026, 1, 1);
      // Promote to review
      for (var i = 0; i < 5; i++) {
        e = scheduler.schedule(
          e,
          ReviewRating.remembered,
          now.add(Duration(days: i * 2)),
        );
      }
      expect(e.fsrsState, 'review');
      // Forget to relearning
      e = scheduler.schedule(
        e,
        ReviewRating.forgot,
        now.add(Duration(days: 12)),
      );
      expect(e.fsrsState, anyOf(equals('relearning'), equals('learning')));
    });
  });

  group('edge cases', () {
    test('new card with forgot on first review gets learning state', () {
      final e = _entry('edge1');
      final scheduled = scheduler.schedule(
        e,
        ReviewRating.forgot,
        DateTime(2026, 1, 1),
      );
      expect(scheduled.fsrsState, 'learning');
      expect(scheduled.reviewCount, 1);
      expect(scheduled.nextReviewAt, isNotNull);
    });

    test('all reviews produce non-negative intervalDays', () {
      var e = _entry('edge2');
      final now = DateTime(2026, 1, 1);
      for (var i = 0; i < 10; i++) {
        e = scheduler.schedule(
          e,
          ReviewRating.remembered,
          now.add(Duration(days: i)),
        );
        expect(e.intervalDays, greaterThanOrEqualTo(0), reason: 'Step $i');
      }
    });

    test('long gap between reviews produces valid scheduling', () {
      var e = _entry('edge3');
      final now = DateTime(2026, 1, 1);
      e = scheduler.schedule(e, ReviewRating.remembered, now);
      // Simulate 90-day gap
      final after = scheduler.schedule(
        e,
        ReviewRating.remembered,
        now.add(const Duration(days: 90)),
      );
      expect(after.nextReviewAt, isNotNull);
      expect(after.fsrsState, isNotEmpty);
    });

    test('JSON round-trip survives 20-step simulation', () {
      var e = _entry('rt');
      final now = DateTime(2026, 1, 1);
      for (var i = 0; i < 20; i++) {
        e = scheduler.schedule(
          e,
          ReviewRating.remembered,
          now.add(Duration(days: i)),
        );
      }
      final json = e.toJson();
      final restored = VocabularyEntry.fromJson(json);
      expect(restored.fsrsState, e.fsrsState);
      expect(restored.fsrsStability, e.fsrsStability);
      expect(restored.fsrsDifficulty, e.fsrsDifficulty);
      expect(restored.nextReviewAt, e.nextReviewAt);
      expect(restored.reviewCount, e.reviewCount);
    });
  });

  group('difficulty bounds', () {
    test('difficulty stays within reasonable bounds over many reviews', () {
      var e = _entry('diff');
      final now = DateTime(2026, 1, 1);
      for (var i = 0; i < 30; i++) {
        e = scheduler.schedule(
          e,
          i % 5 == 0 ? ReviewRating.forgot : ReviewRating.remembered,
          now.add(Duration(days: i)),
        );
        if (e.fsrsDifficulty != null) {
          expect(
            e.fsrsDifficulty!,
            inInclusiveRange(1.0, 10.0),
            reason: 'Difficulty at step $i out of bounds',
          );
        }
      }
    });
  });
}
