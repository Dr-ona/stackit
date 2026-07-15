import 'package:flutter/material.dart';

import '../../models/vocabulary_entry.dart';
import 'highlighted_example_text.dart';
import 'translation_meaning_list.dart';
import 'vocabulary_controller.dart';

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
    final isExplaining = controller.explainingEntryId == entry.id;
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
                tooltip: 'Pronounce',
                onPressed: () =>
                    controller.speak(entry.sourceText, entry.sourceLanguage),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            entry.translations.length == 1
                ? '1 verified ${entry.targetLanguage.label} equivalent'
                : '${entry.translations.length} verified '
                      '${entry.targetLanguage.label} equivalents',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF657069),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TranslationMeaningList(
            translations: entry.translations,
            language: entry.targetLanguage,
          ),
          const SizedBox(height: 26),
          _DetailSection(label: 'Definition', body: entry.definition),
          if (entry.example != null) ...[
            const SizedBox(height: 20),
            _DetailSection.child(
              label: 'Example',
              child: HighlightedExampleText(
                example: entry.example!,
                term: entry.sourceText,
                language: entry.sourceLanguage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (entry.source case final String source when source.isNotEmpty) ...[
            const SizedBox(height: 20),
            _DetailSection(label: 'Captured from', body: source),
          ],
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: isExplaining
                ? null
                : () => _requestContextExplanation(context, entry, controller),
            icon: isExplaining
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              entry.contextualExplanation == null
                  ? 'Explain with Gemini'
                  : 'Refresh contextual explanation',
            ),
          ),
          if (entry.contextualExplanation != null) ...[
            const SizedBox(height: 24),
            _DetailSection(
              label: 'Contextual meaning',
              body: entry.contextualExplanation!,
            ),
            if (entry.contextualExample != null) ...[
              const SizedBox(height: 20),
              _DetailSection(
                label: 'New example',
                body: entry.contextualExample!,
              ),
            ],
            if (entry.relatedPhrases.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DetailSection(
                label: 'Related phrases',
                body: entry.relatedPhrases.join('\n'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Future<void> _requestContextExplanation(
  BuildContext context,
  VocabularyEntry entry,
  VocabularyController controller,
) async {
  final input = TextEditingController(text: entry.contextText ?? '');
  final sentence = await showDialog<String?>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Explain in context'),
      content: TextField(
        controller: input,
        minLines: 2,
        maxLines: 5,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Sentence or context (optional)',
          hintText: 'Paste the sentence where you found this word.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, input.text),
          child: const Text('Explain'),
        ),
      ],
    ),
  );
  input.dispose();
  if (sentence == null || !context.mounted) return;
  try {
    await controller.enrichWithContext(entry, context: sentence);
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
