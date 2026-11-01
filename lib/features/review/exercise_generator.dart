import 'dart:math';

import '../../models/vocabulary_entry.dart';
import 'exercise.dart';
import 'weak_meaning_detector.dart';

class ExerciseGenerator {
  ExerciseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _detector = const WeakMeaningDetector();

  List<Exercise> generate({
    required List<VocabularyEntry> entries,
    required ExerciseSessionConfig config,
    Map<String, int>? senseErrorCounts,
  }) {
    if (entries.isEmpty) return const [];
    final pool = _selectPool(
      entries,
      config,
      senseErrorCounts: senseErrorCounts,
    );
    final exercises = <Exercise>[];
    for (final entry in pool) {
      final types = _distributeTypes(config.mixRatio, config.maxExercises);
      for (final type in types) {
        if (exercises.length >= config.maxExercises) break;
        final exercise = _buildExercise(type, entry);
        if (exercise != null) exercises.add(exercise);
      }
      if (exercises.length >= config.maxExercises) break;
    }
    exercises.shuffle(_random);
    return exercises.take(config.maxExercises).toList();
  }

  List<VocabularyEntry> _selectPool(
    List<VocabularyEntry> entries,
    ExerciseSessionConfig config, {
    Map<String, int>? senseErrorCounts,
  }) {
    final now = DateTime.now();
    final pool = <VocabularyEntry>[];
    switch (config.mode) {
      case ExerciseMode.newWords:
        pool.addAll(entries.where((e) => e.reviewCount == 0));
        if (pool.length < 5) {
          pool.addAll(
            entries.where((e) => e.reviewCount <= 2 && !pool.contains(e)),
          );
        }
      case ExerciseMode.weakMeanings:
        final prioritized = _detector.prioritizeWeak(
          entries.where((e) => e.isDue(now)).toList(),
          senseErrorCounts: senseErrorCounts,
        );
        pool.addAll(prioritized);
        if (pool.length < 5) {
          pool.addAll(
            _detector
                .prioritizeWeak(entries, senseErrorCounts: senseErrorCounts)
                .where((e) => !pool.contains(e)),
          );
        }
      case ExerciseMode.overdueReview:
        pool.addAll(entries.where((e) => e.isDue(now)));
      case ExerciseMode.mixed:
        pool.addAll(entries.where((e) => e.isDue(now)));
        if (pool.isEmpty) pool.addAll(entries);
    }
    pool.shuffle(_random);
    return pool;
  }

  List<ExerciseType> _distributeTypes(
    Map<ExerciseType, double> ratio,
    int count,
  ) {
    final types = <ExerciseType>[];
    for (final entry in ratio.entries) {
      types.addAll(List.filled((entry.value * count).ceil(), entry.key));
    }
    types.shuffle(_random);
    return types;
  }

  Exercise? _buildExercise(ExerciseType type, VocabularyEntry entry) {
    return switch (type) {
      ExerciseType.cloze => _buildCloze(entry),
      ExerciseType.multipleChoice => _buildMultipleChoice(entry),
      ExerciseType.reverseTranslation => _buildReverseTranslation(entry),
      ExerciseType.definitionMatch => _buildDefinitionMatch(entry),
    };
  }

  Exercise _buildCloze(VocabularyEntry entry) {
    final senseIndex = _randomSenseIndex(entry);
    final sense = entry.senses[senseIndex];
    final example = sense.primaryExample?.sourceText ?? entry.sourceText;
    final term = entry.sourceText;
    final blanked = example.replaceFirst(
      RegExp(RegExp.escape(term), caseSensitive: false),
      '______',
    );
    return Exercise(
      type: ExerciseType.cloze,
      entry: entry,
      senseIndex: senseIndex,
      prompt: blanked,
      correctAnswer: term,
      hint: sense.definition,
    );
  }

  Exercise _buildMultipleChoice(VocabularyEntry entry) {
    final senseIndex = _randomSenseIndex(entry);
    final sense = entry.senses[senseIndex];
    final correct = sense.primaryTranslation;
    final distractors = _pickDistractors(entry, correct);
    final options = [correct, ...distractors]..shuffle(_random);
    return Exercise(
      type: ExerciseType.multipleChoice,
      entry: entry,
      senseIndex: senseIndex,
      prompt:
          '${entry.sourceText} (${sense.partOfSpeech ?? ""})\n${sense.definition}',
      correctAnswer: correct,
      options: options,
    );
  }

  Exercise _buildReverseTranslation(VocabularyEntry entry) {
    final senseIndex = _randomSenseIndex(entry);
    final sense = entry.senses[senseIndex];
    final target = sense.primaryTranslation;
    return Exercise(
      type: ExerciseType.reverseTranslation,
      entry: entry,
      senseIndex: senseIndex,
      prompt: target,
      correctAnswer: entry.sourceText,
      hint: sense.definition,
    );
  }

  Exercise _buildDefinitionMatch(VocabularyEntry entry) {
    final senseIndex = _randomSenseIndex(entry);
    final sense = entry.senses[senseIndex];
    return Exercise(
      type: ExerciseType.definitionMatch,
      entry: entry,
      senseIndex: senseIndex,
      prompt: sense.definition,
      correctAnswer: entry.sourceText,
      hint: sense.primaryTranslation,
    );
  }

  int _randomSenseIndex(VocabularyEntry entry) {
    if (entry.senses.length <= 1) return 0;
    return _random.nextInt(entry.senses.length);
  }

  List<String> _pickDistractors(VocabularyEntry entry, String correct) {
    final allTranslations = entry.allTranslations
        .where((t) => t != correct)
        .toList();
    if (allTranslations.length >= 3) {
      allTranslations.shuffle(_random);
      return allTranslations.take(3).toList();
    }
    return allTranslations;
  }
}
