import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/vocabulary_entry.dart';
import 'example_with_translation.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_sense_list.dart';

Future<void> showVocabularyEntryDetails(
  BuildContext context, {
  required VocabularyEntry entry,
  required VocabularyController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.9,
      child: VocabularyEntryDetailSheet(entry: entry, controller: controller),
    ),
  );
}

class VocabularyEntryDetailSheet extends StatelessWidget {
  const VocabularyEntryDetailSheet({
    super.key,
    required this.entry,
    required this.controller,
  });

  final VocabularyEntry entry;
  final VocabularyController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final current = controller.entries
            .where((candidate) => candidate.id == entry.id)
            .firstOrNull;
        return _EntryDetails(entry: current ?? entry, controller: controller);
      },
    );
  }
}

class _EntryDetails extends StatelessWidget {
  const _EntryDetails({required this.entry, required this.controller});

  final VocabularyEntry entry;
  final VocabularyController controller;

  @override
  Widget build(BuildContext context) {
    final sourceDirection = entry.sourceLanguage.isRtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final isThin =
        entry.senses.length == 1 ||
        entry.senses.every((sense) => sense.examples.isEmpty);
    final isDiscovering = controller.discoveringMeaningsEntryId == entry.id;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(
              avatar: const Icon(Icons.translate_rounded, size: 18),
              label: Text(entry.languagePair.label),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.sourceText,
                  textDirection: sourceDirection,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: context.l10n.pronounce,
                onPressed: () =>
                    controller.speak(entry.sourceText, entry.sourceLanguage),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            entry.senses.length == 1
                ? context.l10n.verifiedMeaning
                : context.l10n.verifiedMeanings(entry.senses.length),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF657069),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (controller.canDiscoverMeanings && isThin) ...[
            Text(
              context.l10n.findAllMeaningsDescription,
              style: const TextStyle(color: Color(0xFF657069), height: 1.4),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isDiscovering
                  ? null
                  : () => _findAllMeanings(context, entry, controller),
              icon: isDiscovering
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                isDiscovering
                    ? context.l10n.findingAllMeanings
                    : context.l10n.findAllMeanings,
              ),
            ),
            const SizedBox(height: 14),
          ],
          VocabularySenseList(
            senses: entry.senses,
            sourceText: entry.sourceText,
            sourceLanguage: entry.sourceLanguage,
            targetLanguage: entry.targetLanguage,
            trailingBuilder: (context, sense) {
              final isExplaining =
                  controller.explainingEntryId == entry.id &&
                  controller.explainingSenseId == sense.id;
              return IconButton(
                tooltip: context.l10n.explainWithGemini,
                onPressed: controller.explainingEntryId == entry.id
                    ? null
                    : () => _requestContextExplanation(
                        context,
                        entry,
                        controller,
                        senseId: sense.id,
                      ),
                icon: isExplaining
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
              );
            },
          ),
          if (entry.source case final String source when source.isNotEmpty) ...[
            const SizedBox(height: 20),
            _DetailSection(label: context.l10n.capturedFrom, body: source),
          ],
          if (entry.contextualExplanation != null) ...[
            const SizedBox(height: 24),
            _DetailSection(
              label: context.l10n.latestContextualExplanation,
              body: entry.contextualExplanation!,
            ),
            if (entry.contextualExample != null) ...[
              const SizedBox(height: 20),
              _DetailSection.child(
                label: context.l10n.newExample,
                child: ExampleWithTranslation(
                  example: entry.contextualExample!,
                  term: entry.sourceText,
                  sourceLanguage: entry.sourceLanguage,
                  targetLanguage: entry.targetLanguage,
                  translation: entry.contextualExampleTranslation,
                ),
              ),
            ],
            if (entry.relatedPhrases.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DetailSection(
                label: context.l10n.relatedPhrases,
                body: entry.relatedPhrases.join('\n'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Future<void> _findAllMeanings(
  BuildContext context,
  VocabularyEntry entry,
  VocabularyController controller,
) async {
  try {
    await controller.enrichEntryWithAllMeanings(entry);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.meaningDiscoveryFailed)),
    );
  }
}

Future<void> _requestContextExplanation(
  BuildContext context,
  VocabularyEntry entry,
  VocabularyController controller, {
  required String senseId,
}) async {
  var input = entry.contextText ?? '';
  final sentence = await showDialog<String?>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.explainInContext),
      content: TextFormField(
        initialValue: input,
        minLines: 2,
        maxLines: 5,
        autofocus: true,
        onChanged: (value) => input = value,
        decoration: InputDecoration(
          labelText: context.l10n.sentenceOptional,
          hintText: context.l10n.sentenceHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, input),
          child: Text(context.l10n.explain),
        ),
      ],
    ),
  );
  if (sentence == null || !context.mounted) return;
  try {
    await controller.enrichWithContext(
      entry,
      senseId: senseId,
      context: sentence,
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.body})
    : child = null;

  const _DetailSection.child({required this.label, required this.child})
    : body = null;

  final String label;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF657069),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        child ??
            Text(
              body!,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
      ],
    );
  }
}
