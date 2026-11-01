import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/vocabulary_entry.dart';
import '../vocabulary/vocabulary_controller.dart';
import 'exercise.dart';
import 'exercise_generator.dart';
import 'review_scheduler.dart';
import 'sense_error_store.dart';

class ExerciseReviewPage extends StatefulWidget {
  const ExerciseReviewPage({
    super.key,
    required this.controller,
    this.config = const ExerciseSessionConfig(),
    this.errorStore,
    this.textOnly = false,
  });

  final VocabularyController controller;
  final ExerciseSessionConfig config;
  final SenseErrorStore? errorStore;
  final bool textOnly;

  @override
  State<ExerciseReviewPage> createState() => _ExerciseReviewPageState();
}

class _ExerciseReviewPageState extends State<ExerciseReviewPage> {
  ExerciseSession? _session;
  late final List<VocabularyEntry> _entries;
  final _textController = TextEditingController();
  bool _answered = false;
  bool? _lastCorrect;
  late int _sessionStartTodayReviewed;
  late final DateTime _sessionStarted;
  bool _completionLogged = false;

  @override
  void initState() {
    super.initState();
    _sessionStarted = DateTime.now();
    _sessionStartTodayReviewed = widget.controller.todayReviewedCount;
    _entries = widget.controller.dueEntries(limit: widget.config.maxExercises);
    _initSession();
  }

  Future<void> _initSession() async {
    Map<String, int>? errorCounts;
    if (widget.errorStore != null) {
      errorCounts = await widget.errorStore!.loadErrorCounts();
    }
    final generator = ExerciseGenerator();
    final exercises = generator.generate(
      entries: _entries,
      config: widget.config,
      senseErrorCounts: errorCounts,
    );
    if (mounted) {
      setState(() {
        _session = ExerciseSession(exercises: exercises);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _todayReviewed =>
      _sessionStartTodayReviewed + (_session?.results.length ?? 0);

  bool get _goalReached => _todayReviewed >= widget.controller.dailyGoal;

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session.exercises.isEmpty) {
      return _EmptyMessage(controller: widget.controller);
    }
    if (session.isComplete) {
      if (!_completionLogged) {
        _completionLogged = true;
        widget.controller.logReviewSessionCompleted(
          cardsReviewed: session.total,
          correctCount: session.correctCount,
          duration: DateTime.now().difference(_sessionStarted),
        );
      }
      return _SessionComplete(
        session: session,
        goalReached: _goalReached,
        todayReviewed: _todayReviewed,
        dailyGoal: widget.controller.dailyGoal,
      );
    }
    final exercise = session.current!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExerciseHeader(
              position: session.currentIndex + 1,
              total: session.total,
              correct: session.correctCount,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: session.currentIndex / session.total,
              minHeight: 7,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: const Color(0xFFE3E1D9),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildExerciseBody(exercise),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBottomBar(exercise),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseBody(Exercise exercise) {
    return switch (exercise.type) {
      ExerciseType.cloze => _ClozeExercise(
        exercise: exercise,
        revealed: _answered,
      ),
      ExerciseType.multipleChoice => _MultipleChoiceExercise(
        exercise: exercise,
        revealed: _answered,
        onSelected: _submitMCQ,
      ),
      ExerciseType.reverseTranslation => _ReverseTranslationExercise(
        exercise: exercise,
        revealed: _answered,
      ),
      ExerciseType.definitionMatch => _DefinitionMatchExercise(
        exercise: exercise,
        revealed: _answered,
      ),
    };
  }

  Widget _buildBottomBar(Exercise exercise) {
    if (exercise.type == ExerciseType.multipleChoice) {
      if (!_answered) return const SizedBox.shrink();
      return _FeedbackBar(correct: _lastCorrect ?? false, onNext: _next);
    }
    if (!_answered) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: context.l10n.typeYourAnswer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitTyped(),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _submitTyped,
            child: Text(context.l10n.check),
          ),
        ],
      );
    }
    return _FeedbackBar(correct: _lastCorrect ?? false, onNext: _next);
  }

  void _submitTyped() {
    final answer = _textController.text.trim();
    if (answer.isEmpty) return;
    _processAnswer(answer);
  }

  void _submitMCQ(String answer) {
    if (_answered) return;
    _processAnswer(answer);
  }

  void _processAnswer(String answer) {
    final session = _session!;
    final exercise = session.current!;
    final correct = _normalize(answer) == _normalize(exercise.correctAnswer);
    setState(() {
      _answered = true;
      _lastCorrect = correct;
    });
    session.record(
      ExerciseResult(
        exercise: exercise,
        userAnswer: answer,
        isCorrect: correct,
        timeSpentMs: 0,
      ),
    );
    HapticFeedback.mediumImpact();
    if (!correct) {
      widget.errorStore?.recordError(exercise.sense.id);
    }
  }

  void _next() async {
    final session = _session!;
    final exercise = session.results.last.exercise;
    final rating = session.results.last.isCorrect
        ? ReviewRating.remembered
        : ReviewRating.forgot;
    await widget.controller.review(exercise.entry, rating);
    setState(() {
      _answered = false;
      _lastCorrect = null;
      _textController.clear();
    });
  }

  static String _normalize(String text) => text.trim().toLowerCase();
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.position,
    required this.total,
    required this.correct,
  });

  final int position;
  final int total;
  final int correct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.exerciseSession,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF356859),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.l10n.exerciseProgress(position, total),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE3ECE6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF356859),
              ),
              const SizedBox(width: 4),
              Text(
                '$correct/$total',
                style: const TextStyle(
                  color: Color(0xFF356859),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClozeExercise extends StatelessWidget {
  const _ClozeExercise({required this.exercise, required this.revealed});

  final Exercise exercise;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.fillInBlank,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF728079),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          '"${exercise.prompt}"',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        if (revealed) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _lastCorrect(exercise) ? Icons.check_circle : Icons.cancel,
                color: _lastCorrect(exercise)
                    ? const Color(0xFF356859)
                    : const Color(0xFFB94D48),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.correctAnswer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF275E50),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (!revealed && exercise.hint != null) ...[
          const SizedBox(height: 12),
          Text(
            exercise.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF657069),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 18),
            const SizedBox(width: 6),
            Text(
              context.l10n.typeYourAnswer,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF657069)),
            ),
          ],
        ),
      ],
    );
  }

  static bool _lastCorrect(Exercise e) => false;
}

class _MultipleChoiceExercise extends StatelessWidget {
  const _MultipleChoiceExercise({
    required this.exercise,
    required this.revealed,
    required this.onSelected,
  });

  final Exercise exercise;
  final bool revealed;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = exercise.options ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.chooseCorrectTranslation,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF728079),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          exercise.prompt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        const Spacer(),
        for (final option in options) ...[
          _MCQOption(
            label: option,
            isCorrect: option == exercise.correctAnswer,
            isSelected: revealed && option == exercise.correctAnswer,
            enabled: !revealed,
            onTap: () => onSelected(option),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MCQOption extends StatelessWidget {
  const _MCQOption({
    required this.label,
    required this.isCorrect,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isCorrect;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    if (isSelected && isCorrect) {
      bgColor = const Color(0xFFE3ECE6);
      borderColor = const Color(0xFF356859);
    } else if (isSelected && !isCorrect) {
      bgColor = const Color(0xFFFDECEA);
      borderColor = const Color(0xFFB94D48);
    } else {
      bgColor = const Color(0xFFF7F5EF);
      borderColor = const Color(0xFFDCE5DF);
    }
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (isSelected)
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect
                    ? const Color(0xFF356859)
                    : const Color(0xFFB94D48),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReverseTranslationExercise extends StatelessWidget {
  const _ReverseTranslationExercise({
    required this.exercise,
    required this.revealed,
  });

  final Exercise exercise;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.translateToSource,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF728079),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          exercise.prompt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        if (revealed) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF356859)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.correctAnswer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF275E50),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (!revealed && exercise.hint != null) ...[
          const SizedBox(height: 12),
          Text(
            exercise.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF657069),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const Spacer(),
        Text(
          context.l10n.typeYourAnswer,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF657069)),
        ),
      ],
    );
  }
}

class _DefinitionMatchExercise extends StatelessWidget {
  const _DefinitionMatchExercise({
    required this.exercise,
    required this.revealed,
  });

  final Exercise exercise;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.whatWordMatches,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF728079),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          '"${exercise.prompt}"',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.45,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (revealed) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF356859)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.correctAnswer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF275E50),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (!revealed && exercise.hint != null) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.translationIs(exercise.hint!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF657069),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const Spacer(),
        Text(
          context.l10n.typeYourAnswer,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF657069)),
        ),
      ],
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({required this.correct, required this.onNext});

  final bool correct;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          correct ? Icons.check_circle_rounded : Icons.info_outline,
          color: correct ? const Color(0xFF356859) : const Color(0xFFB94D48),
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            correct ? context.l10n.correctAnswer : context.l10n.incorrectAnswer,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: correct
                  ? const Color(0xFF356859)
                  : const Color(0xFFB94D48),
            ),
          ),
        ),
        FilledButton(onPressed: onNext, child: Text(context.l10n.next)),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.controller});
  final VocabularyController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 56,
              color: Color(0xFF356859),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.noExercisesAvailable,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.collectWordsFirst,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionComplete extends StatelessWidget {
  const _SessionComplete({
    required this.session,
    required this.goalReached,
    required this.todayReviewed,
    required this.dailyGoal,
  });

  final ExerciseSession session;
  final bool goalReached;
  final int todayReviewed;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final accuracy = session.accuracy;
    final emoji = accuracy >= 0.8
        ? '🌟'
        : accuracy >= 0.5
        ? '💪'
        : '📚';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 24),
            Text(
              context.l10n.exerciseSessionComplete,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.exerciseScore(session.correctCount, session.total),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF356859),
              ),
            ),
            if (goalReached) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.goalReached,
                style: const TextStyle(
                  color: Color(0xFF356859),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
