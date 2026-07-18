import 'package:flutter/material.dart';

import '../../models/vocabulary_entry.dart';
import '../../l10n/app_localizations.dart';
import '../vocabulary/vocabulary_controller.dart';
import '../vocabulary/vocabulary_sense_list.dart';
import 'review_scheduler.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.controller});

  final VocabularyController controller;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final List<VocabularyEntry> _session;
  int _index = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _session = widget.controller.dueEntries();
  }

  VocabularyEntry? get _current =>
      _index < _session.length ? _session[_index] : null;

  @override
  Widget build(BuildContext context) {
    if (_session.isEmpty) {
      return _ReviewMessage(
        icon: Icons.wb_sunny_outlined,
        eyebrow: context.l10n.allClear,
        title: context.l10n.nothingDue,
        body: context.l10n.collectWords,
      );
    }
    if (_current == null) {
      return _ReviewMessage(
        icon: Icons.celebration_outlined,
        eyebrow: context.l10n.sessionComplete,
        title: context.l10n.wordsRevisited(_session.length),
        body: context.l10n.enoughToday,
      );
    }

    final entry = _current!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReviewHeader(position: _index + 1, total: _session.length),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _index / _session.length,
              minHeight: 7,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: const Color(0xFFE3E1D9),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _revealed
                        ? _Answer(key: const ValueKey('answer'), entry: entry)
                        : _Prompt(key: const ValueKey('prompt'), entry: entry),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _revealed
                  ? _RatingButtons(onRate: _rate)
                  : SizedBox(
                      key: const ValueKey('reveal'),
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => setState(() => _revealed = true),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(context.l10n.revealMeaning),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rate(ReviewRating rating) async {
    final entry = _current;
    if (entry == null) return;
    setState(() {
      _index += 1;
      _revealed = false;
    });
    await widget.controller.review(entry, rating);
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.position, required this.total});

  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dailyReviewHeader,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF356859),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.reviewProgress(position, total),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Text(
          context.l10n.reviewRemaining(total - position + 1),
          style: const TextStyle(
            color: Color(0xFF657069),
            fontWeight: FontWeight.w600,
          ),
        ),
        ],
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({super.key, required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    final example = entry.example;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          example == null
              ? context.l10n.recallMeaning
              : context.l10n.completeThought,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF728079),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          example == null
              ? entry.sourceText
              : '“${_hideTerm(example, entry.sourceText)}”',
          textDirection: entry.sourceLanguage.isRtl
              ? TextDirection.rtl
              : TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          example == null
              ? context.l10n.explainIn(entry.targetLanguage.nativeLabel)
              : context.l10n.wordInBlank,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF657069)),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.psychology_alt_outlined, size: 20),
            const SizedBox(width: 8),
            Text(context.l10n.recallFirst),
          ],
        ),
      ],
    );
  }

  static String _hideTerm(String example, String term) => example.replaceFirst(
    RegExp(RegExp.escape(term), caseSensitive: false),
    '________',
  );
}

class _Answer extends StatelessWidget {
  const _Answer({super.key, required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.sourceText,
                  textDirection: entry.sourceLanguage.isRtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF356859)),
            ],
          ),
          const SizedBox(height: 20),
          VocabularySenseList(
            senses: entry.senses,
            sourceText: entry.sourceText,
            sourceLanguage: entry.sourceLanguage,
            targetLanguage: entry.targetLanguage,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _RatingButtons extends StatelessWidget {
  const _RatingButtons({required this.onRate});

  final ValueChanged<ReviewRating> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('ratings'),
      children: [
        _button(
          context.l10n.forgot,
          const Color(0xFFB94D48),
          ReviewRating.forgot,
        ),
        const SizedBox(width: 8),
        _button(
          context.l10n.almost,
          const Color(0xFF9A6B20),
          ReviewRating.almost,
        ),
        const SizedBox(width: 8),
        _button(
          context.l10n.remembered,
          const Color(0xFF356859),
          ReviewRating.remembered,
        ),
      ],
    );
  }

  Widget _button(String label, Color color, ReviewRating rating) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          ),
          onPressed: () => onRate(rating),
          child: FittedBox(child: Text(label)),
        ),
      ),
    );
  }
}

class _ReviewMessage extends StatelessWidget {
  const _ReviewMessage({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF356859)),
            const SizedBox(height: 24),
            Text(
              eyebrow,
              style: const TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
