import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/vocabulary_entry.dart';
import 'collection_picker_sheet.dart';
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  avatar: const Icon(Icons.translate_rounded, size: 18),
                  label: Text(entry.languagePair.label),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: Icon(
                    entry.meaningSource == 'gemini'
                        ? Icons.auto_awesome_rounded
                        : entry.meaningSource == 'manual'
                        ? Icons.edit_rounded
                        : Icons.book_rounded,
                    size: 16,
                  ),
                  label: Text(
                    entry.meaningSource == 'gemini'
                        ? 'Gemini'
                        : entry.meaningSource == 'manual'
                        ? 'Manual'
                        : 'Offline',
                  ),
                  backgroundColor: const Color(0xFFF0E6D3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (entry.collectionIds.isNotEmpty)
                ...entry.collectionIds.take(2).map((id) {
                  final name = controller.collections
                      .where((c) => c.id == id)
                      .map((c) => c.name)
                      .firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        name ?? id,
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  );
                }),
              ActionChip(
                avatar: const Icon(
                  Icons.collections_bookmark_outlined,
                  size: 18,
                ),
                label: Text(
                  context.l10n.addToCollection,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => showCollectionPicker(
                  context,
                  controller: controller,
                  entry: entry,
                ),
              ),
            ],
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
            groupByPartOfSpeech: VocabularySenseList.shouldGroup(entry.senses),
            trailingBuilder: (context, sense) {
              final isExplaining =
                  controller.explainingEntryId == entry.id &&
                  controller.explainingSenseId == sense.id;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
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
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Report',
                    onSelected: (value) => _reportMeaning(
                      context,
                      entry,
                      controller,
                      sense.id,
                      value,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'wrong',
                        child: Text('Wrong meaning'),
                      ),
                      const PopupMenuItem(
                        value: 'outdated',
                        child: Text('Outdated definition'),
                      ),
                      const PopupMenuItem(
                        value: 'offensive',
                        child: Text('Offensive content'),
                      ),
                      const PopupMenuItem(
                        value: 'other',
                        child: Text('Other issue'),
                      ),
                    ],
                    icon: const Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: Color(0xFF657069),
                    ),
                  ),
                ],
              );
            },
          ),
          if (entry.source case final String source when source.isNotEmpty) ...[
            const SizedBox(height: 20),
            _DetailSection(label: context.l10n.capturedFrom, body: source),
          ],
          if (entry.sourceAppName != null ||
              entry.sourceUrl != null ||
              entry.contextText != null) ...[
            const SizedBox(height: 16),
            _ContextConsentBanner(entry: entry, controller: controller),
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

void _reportMeaning(
  BuildContext context,
  VocabularyEntry entry,
  VocabularyController controller,
  String senseId,
  String reason,
) {
  controller.reportMeaning(entry, senseId, reason);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Report submitted. Thank you!')));
}

class _ContextConsentBanner extends StatelessWidget {
  const _ContextConsentBanner({required this.entry, required this.controller});

  final VocabularyEntry entry;
  final VocabularyController controller;

  @override
  Widget build(BuildContext context) {
    final synced = entry.contextConsented;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: synced ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: synced ? const Color(0xFFA5D6A7) : const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        children: [
          Icon(
            synced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 20,
            color: synced ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  synced
                      ? context.l10n.syncContextInfo
                      : context.l10n.contextSyncedLocally,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: synced
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF57F17),
                  ),
                ),
                if (!synced)
                  Text(
                    context.l10n.syncContextDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF657069),
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: synced,
            onChanged: (value) {
              controller.setContextConsent(entry, value);
            },
            activeThumbColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
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
