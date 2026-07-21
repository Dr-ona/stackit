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
    this.groupByPartOfSpeech = false,
    this.trailingBuilder,
  });

  final List<VocabularySense> senses;
  final String sourceText;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;
  final bool compact;
  final bool showExamples;
  final bool groupByPartOfSpeech;
  final Widget Function(BuildContext context, VocabularySense sense)?
  trailingBuilder;

  static bool shouldGroup(List<VocabularySense> senses) {
    final tagged = senses.where((s) => s.partOfSpeech != null).length;
    return tagged >= 3;
  }

  @override
  Widget build(BuildContext context) {
    if (!groupByPartOfSpeech || senses.length < 3) {
      return _flatList(context, senses);
    }
    return _groupedList(context, senses);
  }

  Widget _flatList(BuildContext context, List<VocabularySense> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _SenseCard(
            sense: items[index],
            index: index,
            total: items.length,
            sourceText: sourceText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            compact: compact,
            showExamples: showExamples,
            trailing: trailingBuilder?.call(context, items[index]),
          ),
          if (index != items.length - 1) SizedBox(height: compact ? 8 : 12),
        ],
      ],
    );
  }

  Widget _groupedList(BuildContext context, List<VocabularySense> items) {
    final groups = <String, List<VocabularySense>>{};
    final posOrder = <String>[];
    final ungrouped = <VocabularySense>[];

    for (final sense in items) {
      final pos = sense.partOfSpeech;
      if (pos == null || pos.isEmpty) {
        ungrouped.add(sense);
      } else {
        groups
            .putIfAbsent(pos, () {
              posOrder.add(pos);
              return [];
            })
            .add(sense);
      }
    }

    final sections = <_SenseGroup>[];
    for (final pos in posOrder) {
      sections.add(_SenseGroup(pos: pos, senses: groups[pos]!));
    }
    if (ungrouped.isNotEmpty) {
      sections.add(_SenseGroup(pos: null, senses: ungrouped));
    }

    var globalIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (
          var sectionIndex = 0;
          sectionIndex < sections.length;
          sectionIndex++
        ) ...[
          if (sectionIndex > 0) SizedBox(height: compact ? 12 : 18),
          _SenseGroupHeader(
            pos: sections[sectionIndex].pos,
            count: sections[sectionIndex].senses.length,
          ),
          SizedBox(height: compact ? 8 : 10),
          for (
            var i = 0;
            i < sections[sectionIndex].senses.length;
            i++, globalIndex++
          ) ...[
            _SenseCard(
              sense: sections[sectionIndex].senses[i],
              index: globalIndex,
              total: items.length,
              sourceText: sourceText,
              sourceLanguage: sourceLanguage,
              targetLanguage: targetLanguage,
              compact: compact,
              showExamples: showExamples,
              trailing: trailingBuilder?.call(
                context,
                sections[sectionIndex].senses[i],
              ),
            ),
            if (i != sections[sectionIndex].senses.length - 1)
              SizedBox(height: compact ? 8 : 12),
          ],
        ],
      ],
    );
  }
}

class _SenseGroup {
  const _SenseGroup({required this.pos, required this.senses});
  final String? pos;
  final List<VocabularySense> senses;
}

class _SenseGroupHeader extends StatelessWidget {
  const _SenseGroupHeader({required this.pos, required this.count});

  final String? pos;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = pos != null
        ? context.l10n.partOfSpeechLabel(pos!)
        : context.l10n.partOfSpeechLabel('Other');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD6E5DC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF275E50),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: const Color(0xFF657069)),
        ),
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
                if (sense.gender case final g?)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: Text(
                      g,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9B59B6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ?trailing,
              ],
            ),
            if (sense.registers.isNotEmpty) ...[
              SizedBox(height: compact ? 6 : 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final register in sense.registers)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E6D3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        register,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF8B6914),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
            if (sense.ipa != null || sense.transliteration != null) ...[
              SizedBox(height: compact ? 4 : 6),
              Wrap(
                spacing: 10,
                children: [
                  if (sense.ipa case final ipa?)
                    Text(
                      '/$ipa/',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF657069),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (sense.transliteration case final tr?)
                    Text(
                      tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF657069),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
            if (sense.inflections.isNotEmpty) ...[
              SizedBox(height: compact ? 8 : 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final entry in sense.inflections.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF5E35B1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
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
            if (sense.synonyms.isNotEmpty) ...[
              SizedBox(height: compact ? 10 : 14),
              Text(
                'Synonyms',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF657069),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _SemanticChips(items: sense.synonyms),
            ],
            if (sense.antonyms.isNotEmpty) ...[
              SizedBox(height: compact ? 8 : 10),
              Text(
                'Antonyms',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF657069),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _SemanticChips(items: sense.antonyms),
            ],
            if (sense.collocations.isNotEmpty) ...[
              SizedBox(height: compact ? 8 : 10),
              Text(
                'Collocations',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF657069),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _SemanticChips(items: sense.collocations),
            ],
            if (sense.idioms.isNotEmpty) ...[
              SizedBox(height: compact ? 8 : 10),
              Text(
                'Idioms',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF657069),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _SemanticChips(items: sense.idioms),
            ],
          ],
        ),
      ),
    );
  }
}

class _SemanticChips extends StatelessWidget {
  const _SemanticChips({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF3D5A80),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
