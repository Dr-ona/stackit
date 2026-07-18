import 'package:flutter/material.dart';

import '../../models/capture_payload.dart';
import '../../models/vocabulary_entry.dart';
import '../../l10n/app_localizations.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_entry_detail_sheet.dart';
import 'vocabulary_sense_list.dart';

class LibraryEntryTile extends StatelessWidget {
  const LibraryEntryTile({
    super.key,
    required this.entry,
    required this.controller,
  });

  final VocabularyEntry entry;
  final VocabularyController controller;

  @override
  Widget build(BuildContext context) {
    final additionalSenseCount = entry.senses.length - 1;
    return ExpansionTile(
      key: PageStorageKey<String>('library-${entry.id}'),
      initiallyExpanded: entry.source == CapturePayload.manualSource,
      tilePadding: const EdgeInsets.symmetric(vertical: 5),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(
        entry.sourceText,
        textDirection: entry.sourceLanguage.isRtl
            ? TextDirection.rtl
            : TextDirection.ltr,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: entry.targetLanguage.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3ECE6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.primarySense.translations.join(' · '),
                  textAlign: entry.targetLanguage.isRtl
                      ? TextAlign.right
                      : TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF356859),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              additionalSenseCount == 0
                  ? context.l10n.tapForDetails
                  : context.l10n.moreMeanings(additionalSenseCount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF657069),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: VocabularySenseList(
            senses: entry.senses,
            sourceText: entry.sourceText,
            sourceLanguage: entry.sourceLanguage,
            targetLanguage: entry.targetLanguage,
            compact: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    controller.speak(entry.sourceText, entry.sourceLanguage),
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(context.l10n.pronounce),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showVocabularyEntryDetails(
                  context,
                  entry: entry,
                  controller: controller,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(context.l10n.fullDetails),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
