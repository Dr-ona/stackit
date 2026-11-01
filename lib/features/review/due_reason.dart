import '../../models/vocabulary_entry.dart';

class DueReason {
  const DueReason({required this.label, required this.severity});

  final String label;
  final String severity;
}

List<DueReason> explainDue(VocabularyEntry entry, DateTime now) {
  final reasons = <DueReason>[];

  if (entry.nextReviewAt == null) {
    reasons.add(
      const DueReason(label: 'New word — not yet reviewed', severity: 'new'),
    );
    return reasons;
  }

  final overdue = now.difference(entry.nextReviewAt!);
  if (overdue.isNegative) {
    reasons.add(
      DueReason(
        label: 'Scheduled review in ${_formatDuration(overdue.abs())}',
        severity: 'scheduled',
      ),
    );
    return reasons;
  }

  if (overdue.inMinutes < 60) {
    reasons.add(
      DueReason(
        label: 'Due now (overdue by ${overdue.inMinutes} min)',
        severity: 'overdue',
      ),
    );
  } else if (overdue.inHours < 24) {
    reasons.add(
      DueReason(
        label: 'Due now (overdue by ${overdue.inHours}h)',
        severity: 'overdue',
      ),
    );
  } else {
    reasons.add(
      DueReason(
        label: 'Due now (overdue by ${overdue.inDays}d)',
        severity: 'overdue',
      ),
    );
  }

  if (entry.fsrsState == 'relearning') {
    reasons.add(
      const DueReason(
        label: 'Relearning — previously forgotten',
        severity: 'weak',
      ),
    );
  } else if (entry.fsrsState == 'learning' && entry.reviewCount > 2) {
    reasons.add(
      DueReason(
        label: 'Still learning after ${entry.reviewCount} reviews',
        severity: 'weak',
      ),
    );
  }

  if (entry.fsrsDifficulty != null && entry.fsrsDifficulty! > 0.7) {
    reasons.add(
      const DueReason(
        label: 'High difficulty — frequently mistaken',
        severity: 'weak',
      ),
    );
  }

  if (entry.fsrsStability != null &&
      entry.fsrsStability! < 1.0 &&
      entry.reviewCount > 1) {
    reasons.add(
      const DueReason(label: 'Low retention confidence', severity: 'weak'),
    );
  }

  if (entry.reviewCount >= 10 && entry.fsrsState == 'review') {
    reasons.add(
      const DueReason(
        label: 'Scheduled for spaced repetition maintenance',
        severity: 'maintenance',
      ),
    );
  }

  return reasons;
}

String _formatDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays}d';
  if (d.inHours > 0) return '${d.inHours}h';
  return '${d.inMinutes}m';
}
