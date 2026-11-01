import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/review/exercise.dart';
import 'package:stackit/features/review/exercise_generator.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

VocabularyEntry _entry(
  String id,
  String text, {
  List<String> translations = const ['ترجمة'],
  String definition = 'definition',
  List<String> examples = const [],
  int reviewCount = 0,
  double? fsrsDifficulty,
}) {
  final senseExamples = examples
      .map((e) => VocabularyExample(sourceText: e))
      .toList();
  return VocabularyEntry.withSenses(
    id: id,
    sourceText: text,
    senses: [
      VocabularySense(
        id: '$id-s1',
        translations: translations,
        definition: definition,
        partOfSpeech: 'noun',
        examples: senseExamples,
      ),
    ],
    sourceLanguage: VocabularyLanguage.english,
    targetLanguage: VocabularyLanguage.arabic,
    createdAt: DateTime(2025),
    reviewCount: reviewCount,
    fsrsDifficulty: fsrsDifficulty,
    meaningSource: 'offline',
  );
}

void main() {
  group('ExerciseSession', () {
    test('starts at index 0 with empty results', () {
      final session = ExerciseSession(exercises: const []);
      expect(session.currentIndex, 0);
      expect(session.results, isEmpty);
      expect(session.isComplete, true);
      expect(session.correctCount, 0);
      expect(session.accuracy, 0.0);
    });

    test('record advances index and tracks correctness', () {
      final entry = _entry('1', 'cat');
      final exercise = Exercise(
        type: ExerciseType.cloze,
        entry: entry,
        senseIndex: 0,
        prompt: 'The ___',
        correctAnswer: 'cat',
      );
      final session = ExerciseSession(exercises: [exercise]);
      expect(session.isComplete, false);
      expect(session.current, exercise);

      session.record(
        ExerciseResult(
          exercise: exercise,
          userAnswer: 'cat',
          isCorrect: true,
          timeSpentMs: 1000,
        ),
      );
      expect(session.isComplete, true);
      expect(session.correctCount, 1);
      expect(session.accuracy, 1.0);
    });

    test('accuracy reflects mixed results', () {
      final entry1 = _entry('1', 'cat');
      final entry2 = _entry('2', 'dog');
      final exercises = [
        Exercise(
          type: ExerciseType.cloze,
          entry: entry1,
          senseIndex: 0,
          prompt: 'a',
          correctAnswer: 'cat',
        ),
        Exercise(
          type: ExerciseType.cloze,
          entry: entry2,
          senseIndex: 0,
          prompt: 'b',
          correctAnswer: 'dog',
        ),
      ];
      final session = ExerciseSession(exercises: exercises);
      session.record(
        ExerciseResult(
          exercise: exercises[0],
          userAnswer: 'cat',
          isCorrect: true,
          timeSpentMs: 500,
        ),
      );
      session.record(
        ExerciseResult(
          exercise: exercises[1],
          userAnswer: 'wrong',
          isCorrect: false,
          timeSpentMs: 500,
        ),
      );
      expect(session.correctCount, 1);
      expect(session.accuracy, 0.5);
    });

    test('summary includes per-type accuracy', () {
      final entry = _entry('1', 'cat');
      final cloze = Exercise(
        type: ExerciseType.cloze,
        entry: entry,
        senseIndex: 0,
        prompt: 'a',
        correctAnswer: 'cat',
      );
      final mcq = Exercise(
        type: ExerciseType.multipleChoice,
        entry: entry,
        senseIndex: 0,
        prompt: 'b',
        correctAnswer: 'cat',
        options: ['cat', 'dog'],
      );
      final session = ExerciseSession(exercises: [cloze, mcq]);
      session.record(
        ExerciseResult(
          exercise: cloze,
          userAnswer: 'cat',
          isCorrect: true,
          timeSpentMs: 500,
        ),
      );
      session.record(
        ExerciseResult(
          exercise: mcq,
          userAnswer: 'dog',
          isCorrect: false,
          timeSpentMs: 500,
        ),
      );
      final summary = session.summary();
      expect(summary['total'], 2);
      expect(summary['correct'], 1);
    });
  });

  group('ExerciseGenerator', () {
    final fixedRandom = Random(42);

    test('generates exercises from a list of entries', () {
      final generator = ExerciseGenerator(random: fixedRandom);
      final entries = [
        _entry('1', 'cat', translations: ['قطة'], examples: ['The cat sat.']),
        _entry('2', 'dog', translations: ['كلب'], examples: ['The dog ran.']),
        _entry(
          '3',
          'book',
          translations: ['كتاب'],
          examples: ['Read the book.'],
        ),
      ];
      final exercises = generator.generate(
        entries: entries,
        config: const ExerciseSessionConfig(maxExercises: 6),
      );
      expect(exercises.length, greaterThanOrEqualTo(1));
      expect(exercises.length, lessThanOrEqualTo(6));
    });

    test('respects maxExercises limit', () {
      final generator = ExerciseGenerator(random: fixedRandom);
      final entries = List.generate(20, (i) => _entry('$i', 'word$i'));
      final exercises = generator.generate(
        entries: entries,
        config: const ExerciseSessionConfig(maxExercises: 5),
      );
      expect(exercises.length, lessThanOrEqualTo(5));
    });

    test('returns empty for empty entries', () {
      final generator = ExerciseGenerator(random: fixedRandom);
      final exercises = generator.generate(
        entries: const [],
        config: const ExerciseSessionConfig(),
      );
      expect(exercises, isEmpty);
    });

    test('generates cloze exercise with blanked term', () {
      final generator = ExerciseGenerator(random: fixedRandom);
      final entries = [
        _entry('1', 'cat', examples: ['The cat sat.']),
      ];
      final exercises = generator.generate(
        entries: entries,
        config: const ExerciseSessionConfig(
          maxExercises: 1,
          mixRatio: {ExerciseType.cloze: 1.0},
        ),
      );
      expect(exercises.length, 1);
      expect(exercises.first.type, ExerciseType.cloze);
      expect(exercises.first.correctAnswer, 'cat');
      expect(exercises.first.prompt, contains('______'));
    });

    test('generates multiple choice with options', () {
      final generator = ExerciseGenerator(random: fixedRandom);
      final entries = [
        _entry('1', 'cat', translations: ['قطة', 'Felis', 'gato']),
      ];
      final exercises = generator.generate(
        entries: entries,
        config: const ExerciseSessionConfig(
          maxExercises: 1,
          mixRatio: {ExerciseType.multipleChoice: 1.0},
        ),
      );
      expect(exercises.length, 1);
      expect(exercises.first.type, ExerciseType.multipleChoice);
      expect(exercises.first.options, isNotNull);
      expect(exercises.first.options!.length, greaterThanOrEqualTo(2));
    });

    test('generates reverse translation exercise', () {
      final generator = ExerciseGenerator(random: fixedRandom);
      final entries = [
        _entry('1', 'cat', translations: ['قطة']),
      ];
      final exercises = generator.generate(
        entries: entries,
        config: const ExerciseSessionConfig(
          maxExercises: 1,
          mixRatio: {ExerciseType.reverseTranslation: 1.0},
        ),
      );
      expect(exercises.length, 1);
      expect(exercises.first.type, ExerciseType.reverseTranslation);
      expect(exercises.first.prompt, 'قطة');
      expect(exercises.first.correctAnswer, 'cat');
    });

    test('generates definition match exercise', () {
      final generator = ExerciseGenerator(random: fixedRandom);
      final entries = [_entry('1', 'cat', definition: 'A small feline')];
      final exercises = generator.generate(
        entries: entries,
        config: const ExerciseSessionConfig(
          maxExercises: 1,
          mixRatio: {ExerciseType.definitionMatch: 1.0},
        ),
      );
      expect(exercises.length, 1);
      expect(exercises.first.type, ExerciseType.definitionMatch);
      expect(exercises.first.prompt, 'A small feline');
      expect(exercises.first.correctAnswer, 'cat');
    });
  });

  group('Exercise', () {
    test('sense getter returns the correct sense', () {
      final entry = _entry('1', 'cat');
      final exercise = Exercise(
        type: ExerciseType.cloze,
        entry: entry,
        senseIndex: 0,
        prompt: 'The ___',
        correctAnswer: 'cat',
      );
      expect(exercise.sense.id, '1-s1');
    });
  });

  group('ExerciseSessionConfig', () {
    test('defaults to mixed mode with 20 exercises', () {
      const config = ExerciseSessionConfig();
      expect(config.mode, ExerciseMode.mixed);
      expect(config.maxExercises, 20);
    });

    test('newWords mode can be set', () {
      const config = ExerciseSessionConfig(mode: ExerciseMode.newWords);
      expect(config.mode, ExerciseMode.newWords);
    });
  });
}
