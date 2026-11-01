import '../../models/vocabulary_entry.dart';
import '../../models/vocabulary_sense.dart';

enum ExerciseType { cloze, multipleChoice, reverseTranslation, definitionMatch }

enum ExerciseMode { newWords, weakMeanings, overdueReview, mixed }

class ExerciseSessionConfig {
  const ExerciseSessionConfig({
    this.mode = ExerciseMode.mixed,
    this.maxExercises = 20,
    this.mixRatio = const {
      ExerciseType.cloze: 0.3,
      ExerciseType.multipleChoice: 0.35,
      ExerciseType.reverseTranslation: 0.2,
      ExerciseType.definitionMatch: 0.15,
    },
  });

  final ExerciseMode mode;
  final int maxExercises;
  final Map<ExerciseType, double> mixRatio;
}

class Exercise {
  const Exercise({
    required this.type,
    required this.entry,
    required this.senseIndex,
    required this.prompt,
    required this.correctAnswer,
    this.options,
    this.hint,
    this.contextSentence,
  });

  final ExerciseType type;
  final VocabularyEntry entry;
  final int senseIndex;
  final String prompt;
  final String correctAnswer;
  final List<String>? options;
  final String? hint;
  final String? contextSentence;

  VocabularySense get sense => entry.senses[senseIndex];
}

class ExerciseResult {
  const ExerciseResult({
    required this.exercise,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpentMs,
  });

  final Exercise exercise;
  final String userAnswer;
  final bool isCorrect;
  final int timeSpentMs;
}

class ExerciseSession {
  ExerciseSession({required this.exercises});

  final List<Exercise> exercises;
  int _currentIndex = 0;
  final List<ExerciseResult> results = [];

  int get currentIndex => _currentIndex;
  int get total => exercises.length;
  bool get isComplete => _currentIndex >= exercises.length;
  Exercise? get current => isComplete ? null : exercises[_currentIndex];
  int get correctCount => results.where((r) => r.isCorrect).length;
  double get accuracy => results.isEmpty ? 0.0 : correctCount / results.length;

  void record(ExerciseResult result) {
    results.add(result);
    _currentIndex++;
  }

  Map<String, dynamic> summary() => {
    'total': total,
    'correct': correctCount,
    'accuracy': accuracy,
    'byType': {
      for (final type in ExerciseType.values)
        type.name:
            results
                .where((r) => r.exercise.type == type)
                .fold(0.0, (sum, r) => sum + (r.isCorrect ? 1.0 : 0.0)) /
            results.where((r) => r.exercise.type == type).length.clamp(0, 1),
    },
  };
}
