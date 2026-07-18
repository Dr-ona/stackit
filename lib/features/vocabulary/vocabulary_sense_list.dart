import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/language_pair.dart';
import '../../models/vocabulary_sense.dart';
import 'example_with_translation.dart';

class VocabularySenseList extends StatelessWidget {
  const VocabularySenseList({
    super.key,
    required this.senses,
    required this.sourceText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.compact = false,
    this.showExamples = true,
    this.trailingBuilder,
  });

  final List<VocabularySense> senses;
  final String sourceText;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;
  final bool compact;
  final bool showExamples;
  final Widget Function(BuildContext context, VocabularySense sense)?
  trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < senses.length; index++) ...[
          _SenseCard(
            sense: senses[index],
            index: index,
            total: senses.length,
            sourceText: sourceText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            compact: compact,
            showExamples: showExamples,
            trailing: trailingBuilder?.call(context, senses[index]),
          ),
          if (index != senses.length - 1) SizedBox(height: compact ? 8 : 12),
        ],
      ],
    );
  }
}

class _SenseCard extends StatelessWidget {
  const _SenseCard({
    required this.sense,
    required this.index,
    required this.total,
    required this.sourceText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.compact,
    required this.showExamples,
    this.trailing,
  });

  final VocabularySense sense;
  final int index;
  final int total;
  final String sourceText;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;
  final bool compact;
  final bool showExamples;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final targetDirection = targetLanguage.isRtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    return Semantics(
      container: true,
      label: context.l10n.meaningLabel(index + 1, total),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5EF),
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          border: Border.all(color: const Color(0xFFDCE5DF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.meaningLabel(index + 1, total),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF356859),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (sense.partOfSpeech case final value?)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF657069),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ?trailing,
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              context.l10n.equivalentsLabel(sense.translations.length),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF657069),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: targetDirection,
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                alignment: targetLanguage.isRtl
                    ? WrapAlignment.end
                    : WrapAlignment.start,
                children: [
                  for (final translation in sense.translations)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 12,
                        vertical: compact ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3ECE6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        translation,
                        style: TextStyle(
                          color: const Color(0xFF275E50),
                          fontSize: compact ? 15 : 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (sense.definition.isNotEmpty) ...[
              SizedBox(height: compact ? 9 : 12),
              Text(
                sense.definition,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4E5A54),
                  height: 1.45,
                ),
              ),
            ],
            if (showExamples && sense.examples.isNotEmpty) ...[
              SizedBox(height: compact ? 10 : 14),
              Text(
                context.l10n.examples,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF657069),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              for (
                var exampleIndex = 0;
                exampleIndex < sense.examples.length;
                exampleIndex++
              ) ...[
                ExampleWithTranslation(
                  example: sense.examples[exampleIndex].sourceText,
                  term: sourceText,
                  sourceLanguage: sourceLanguage,
                  targetLanguage: targetLanguage,
                  translation: sense.examples[exampleIndex].translation,
                  sourceStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF59655F),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (exampleIndex != sense.examples.length - 1)
                  const Divider(height: 20),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
