import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

VocabularyEntry _entry({
  required String id,
  DateTime? lastReviewedAt,
  int reviewCount = 0,
  int intervalDays = 0,
}) {
  return VocabularyEntry.withSenses(
    id: id,
    sourceText: id,
    senses: [
      VocabularySense.legacy(translations: const ['t'], definition: 'd'),
    ],
    sourceLanguage: VocabularyLanguage.english,
    targetLanguage: VocabularyLanguage.arabic,
    createdAt: DateTime.utc(2026, 1, 1),
    reviewCount: reviewCount,
    intervalDays: intervalDays,
    lastReviewedAt: lastReviewedAt,
  );
}

void main() {
  group('computeStreak', () {
    test('returns 0 for empty entries', () {
      expect(VocabularyController.computeStreak([]), 0);
    });

    test('returns 0 when no entry has been reviewed', () {
      final entries = [
        _entry(id: 'a', reviewCount: 0),
        _entry(id: 'b', reviewCount: 0),
      ];
      expect(VocabularyController.computeStreak(entries), 0);
    });

    test('returns 1 when only today was reviewed', () {
      final entries = [
        _entry(id: 'a', lastReviewedAt: DateTime.now(), reviewCount: 1),
      ];
      expect(VocabularyController.computeStreak(entries), 1);
    });

    test('returns 2 for today and yesterday', () {
      final now = DateTime.now();
      final entries = [
        _entry(id: 'a', lastReviewedAt: now, reviewCount: 1),
        _entry(
          id: 'b',
          lastReviewedAt: now.subtract(const Duration(days: 1)),
          reviewCount: 1,
        ),
      ];
      expect(VocabularyController.computeStreak(entries), 2);
    });

    test('returns 3 for three consecutive days ending today', () {
      final now = DateTime.now();
      final entries = [
        _entry(id: 'a', lastReviewedAt: now, reviewCount: 1),
        _entry(
          id: 'b',
          lastReviewedAt: now.subtract(const Duration(days: 1)),
          reviewCount: 1,
        ),
        _entry(
          id: 'c',
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          reviewCount: 1,
        ),
      ];
      expect(VocabularyController.computeStreak(entries), 3);
    });

    test('returns 1 when only yesterday was reviewed', () {
      final entries = [
        _entry(
          id: 'a',
          lastReviewedAt: DateTime.now().subtract(const Duration(days: 1)),
          reviewCount: 1,
        ),
      ];
      expect(VocabularyController.computeStreak(entries), 1);
    });

    test('returns 0 when last review was 2 days ago', () {
      final entries = [
        _entry(
          id: 'a',
          lastReviewedAt: DateTime.now().subtract(const Duration(days: 2)),
          reviewCount: 1,
        ),
      ];
      expect(VocabularyController.computeStreak(entries), 0);
    });

    test('handles multiple reviews on the same day', () {
      final today = DateTime.now();
      final entries = [
        _entry(id: 'a', lastReviewedAt: today, reviewCount: 3),
        _entry(id: 'b', lastReviewedAt: today, reviewCount: 2),
        _entry(
          id: 'c',
          lastReviewedAt: today.subtract(const Duration(days: 1)),
          reviewCount: 1,
        ),
      ];
      expect(VocabularyController.computeStreak(entries), 2);
    });

    test('breaks streak at a gap day', () {
      final now = DateTime.now();
      final entries = [
        _entry(id: 'a', lastReviewedAt: now, reviewCount: 1),
        // Gap: no review yesterday
        _entry(
          id: 'b',
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          reviewCount: 1,
        ),
      ];
      expect(VocabularyController.computeStreak(entries), 1);
    });
  });

  group('computeRetention', () {
    test('returns 0 when nothing reviewed', () {
      expect(VocabularyController.computeRetention(0, 0), 0);
    });

    test('returns 0 when mastered is 0', () {
      expect(VocabularyController.computeRetention(10, 0), 0);
    });

    test('returns 1.0 when all reviewed are mastered', () {
      expect(VocabularyController.computeRetention(5, 5), 1.0);
    });

    test('returns 0.5 for half mastery', () {
      expect(VocabularyController.computeRetention(10, 5), 0.5);
    });
  });

  group('computeTodayReviewed', () {
    final fixedNow = DateTime(2026, 7, 20, 14, 0);

    test('returns 0 for empty entries', () {
      expect(VocabularyController.computeTodayReviewed([], now: fixedNow), 0);
    });

    test('returns 0 when no entry was reviewed today', () {
      final entries = [
        _entry(
          id: 'a',
          lastReviewedAt: fixedNow.subtract(const Duration(days: 2)),
          reviewCount: 1,
        ),
        _entry(id: 'b', reviewCount: 0),
      ];
      expect(
        VocabularyController.computeTodayReviewed(entries, now: fixedNow),
        0,
      );
    });

    test('returns 1 when one entry was reviewed today', () {
      final entries = [
        _entry(id: 'a', lastReviewedAt: fixedNow, reviewCount: 1),
        _entry(id: 'b', reviewCount: 0),
      ];
      expect(
        VocabularyController.computeTodayReviewed(entries, now: fixedNow),
        1,
      );
    });

    test('returns count of all entries reviewed today', () {
      final entries = [
        _entry(id: 'a', lastReviewedAt: fixedNow, reviewCount: 1),
        _entry(
          id: 'b',
          lastReviewedAt: fixedNow.subtract(const Duration(hours: 2)),
          reviewCount: 1,
        ),
        _entry(
          id: 'c',
          lastReviewedAt: fixedNow.subtract(const Duration(days: 1)),
          reviewCount: 1,
        ),
      ];
      expect(
        VocabularyController.computeTodayReviewed(entries, now: fixedNow),
        2,
      );
    });

    test('counts multiple reviews of the same word as one', () {
      final entries = [
        _entry(id: 'a', lastReviewedAt: fixedNow, reviewCount: 3),
      ];
      expect(
        VocabularyController.computeTodayReviewed(entries, now: fixedNow),
        1,
      );
    });
  });
}
