import '../../models/vocabulary_entry.dart';

class SenseWeakness {
  const SenseWeakness({
    required this.entryId,
    required this.senseId,
    required this.sourceText,
    required this.definition,
    required this.reasons,
    required this.severity,
  });

  final String entryId;
  final String senseId;
  final String sourceText;
  final String definition;
  final List<String> reasons;
  final double severity;

  bool get isCritical => severity >= 0.8;
  bool get isModerate => severity >= 0.5 && severity < 0.8;
}

class WeakMeaningDetector {
  const WeakMeaningDetector({
    this.difficultyThreshold = 0.6,
    this.stabilityThreshold = 1.5,
    this.recentErrorThreshold = 3,
  });

  final double difficultyThreshold;
  final double stabilityThreshold;
  final int recentErrorThreshold;

  List<SenseWeakness> detect({
    required List<VocabularyEntry> entries,
    Map<String, int>? senseErrorCounts,
  }) {
    final weaknesses = <SenseWeakness>[];
    for (final entry in entries) {
      for (final sense in entry.senses) {
        final reasons = <String>[];
        var severity = 0.0;

        if (entry.fsrsDifficulty != null &&
            entry.fsrsDifficulty! > difficultyThreshold) {
          reasons.add(
            'High difficulty (${entry.fsrsDifficulty!.toStringAsFixed(2)})',
          );
          severity = severity.clamp(0, 0.6);
          severity += entry.fsrsDifficulty! * 0.5;
        }

        if (entry.fsrsStability != null &&
            entry.fsrsStability! < stabilityThreshold &&
            entry.fsrsState != 'new') {
          reasons.add(
            'Low stability (${entry.fsrsStability!.toStringAsFixed(1)} days)',
          );
          severity += 0.3;
        }

        if (entry.fsrsState == 'relearning') {
          reasons.add('In relearning cycle');
          severity += 0.4;
        }

        if (entry.fsrsState == 'learning' && entry.reviewCount > 2) {
          reasons.add('Still in learning after ${entry.reviewCount} reviews');
          severity += 0.2;
        }

        final errorCount = senseErrorCounts?[sense.id] ?? 0;
        if (errorCount >= recentErrorThreshold) {
          reasons.add('$errorCount recent errors');
          severity += errorCount * 0.1;
        }

        if (reasons.isNotEmpty) {
          weaknesses.add(
            SenseWeakness(
              entryId: entry.id,
              senseId: sense.id,
              sourceText: entry.sourceText,
              definition: sense.definition,
              reasons: reasons,
              severity: severity.clamp(0.0, 1.0),
            ),
          );
        }
      }
    }
    weaknesses.sort((a, b) => b.severity.compareTo(a.severity));
    return weaknesses;
  }

  List<VocabularyEntry> prioritizeWeak(
    List<VocabularyEntry> entries, {
    Map<String, int>? senseErrorCounts,
  }) {
    final weaknesses = detect(
      entries: entries,
      senseErrorCounts: senseErrorCounts,
    );
    final weakIds = weaknesses.map((w) => w.entryId).toSet();
    final weakEntries = entries.where((e) => weakIds.contains(e.id)).toList();
    final strongEntries = entries
        .where((e) => !weakIds.contains(e.id))
        .toList();
    return [...weakEntries, ...strongEntries];
  }

  Map<String, String> summarizePatterns(List<SenseWeakness> weaknesses) {
    final patterns = <String, int>{};
    for (final w in weaknesses) {
      for (final reason in w.reasons) {
        final key = reason.split(' (').first;
        patterns[key] = (patterns[key] ?? 0) + 1;
      }
    }
    final sorted = patterns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {
      for (final entry in sorted)
        entry.key:
            '${entry.value} sense${entry.value == 1 ? '' : 's'} affected',
    };
  }
}
