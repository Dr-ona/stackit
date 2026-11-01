import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/review/due_reason.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

VocabularyEntry _entry({
  DateTime? nextReviewAt,
  String fsrsState = 'new',
  double? fsrsDifficulty,
  double? fsrsStability,
  int reviewCount = 0,
}) {
  return VocabularyEntry.withSenses(
    id: '1',
    sourceText: 'cat',
    senses: [
      const VocabularySense(
        id: 's1',
        translations: ['cat'],
        definition: 'feline',
      ),
    ],
    sourceLanguage: VocabularyLanguage.english,
    targetLanguage: VocabularyLanguage.arabic,
    createdAt: DateTime(2025),
    nextReviewAt: nextReviewAt,
    fsrsState: fsrsState,
    fsrsDifficulty: fsrsDifficulty,
    fsrsStability: fsrsStability,
    reviewCount: reviewCount,
    meaningSource: 'offline',
  );
}

void main() {
  group('explainDue', () {
    test('new word has no nextReviewAt', () {
      final entry = _entry();
      final reasons = explainDue(entry, DateTime(2025));
      expect(reasons, hasLength(1));
      expect(reasons.first.label, contains('New word'));
      expect(reasons.first.severity, 'new');
    });

    test('overdue word shows overdue duration', () {
      final entry = _entry(
        nextReviewAt: DateTime(2025, 1, 1),
        fsrsState: 'review',
      );
      final reasons = explainDue(entry, DateTime(2025, 1, 5));
      expect(reasons.any((r) => r.severity == 'overdue'), isTrue);
    });

    test('relearning word shows relearning reason', () {
      final entry = _entry(
        nextReviewAt: DateTime(2025, 1, 1),
        fsrsState: 'relearning',
      );
      final reasons = explainDue(entry, DateTime(2025, 1, 5));
      expect(reasons.any((r) => r.label.contains('Relearning')), isTrue);
    });

    test('high difficulty shows weak reason', () {
      final entry = _entry(
        nextReviewAt: DateTime(2025, 1, 1),
        fsrsState: 'review',
        fsrsDifficulty: 0.85,
      );
      final reasons = explainDue(entry, DateTime(2025, 1, 5));
      expect(reasons.any((r) => r.severity == 'weak'), isTrue);
    });

    test('low stability shows weak reason', () {
      final entry = _entry(
        nextReviewAt: DateTime(2025, 1, 1),
        fsrsState: 'review',
        fsrsStability: 0.5,
        reviewCount: 5,
      );
      final reasons = explainDue(entry, DateTime(2025, 1, 5));
      expect(reasons.any((r) => r.label.contains('retention')), isTrue);
    });

    test('maintenance reason for well-reviewed words', () {
      final entry = _entry(
        nextReviewAt: DateTime(2025, 1, 1),
        fsrsState: 'review',
        reviewCount: 12,
      );
      final reasons = explainDue(entry, DateTime(2025, 1, 5));
      expect(reasons.any((r) => r.severity == 'maintenance'), isTrue);
    });

    test('multiple reasons can be combined', () {
      final entry = _entry(
        nextReviewAt: DateTime(2025, 1, 1),
        fsrsState: 'relearning',
        fsrsDifficulty: 0.9,
        fsrsStability: 0.3,
        reviewCount: 5,
      );
      final reasons = explainDue(entry, DateTime(2025, 1, 5));
      expect(reasons.length, greaterThanOrEqualTo(2));
    });

    test('scheduled word shows time until due', () {
      final entry = _entry(
        nextReviewAt: DateTime(2025, 1, 10),
        fsrsState: 'review',
      );
      final reasons = explainDue(entry, DateTime(2025, 1, 5));
      expect(reasons, hasLength(1));
      expect(reasons.first.severity, 'scheduled');
    });
  });
}
