import 'package:flutter/material.dart';

import '../../models/vocabulary_entry.dart';
import 'translation_meaning_list.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_entry_detail_sheet.dart';

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
    final remaining = entry.translations.skip(1).toList(growable: false);
    return ExpansionTile(
      key: PageStorageKey<String>('library-${entry.id}'),
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
            TranslationMeaningList(
              translations: [entry.translations.first],
              language: entry.targetLanguage,
              compact: true,
              totalCount: entry.translations.length,
            ),
            const SizedBox(height: 6),
            Text(
              remaining.isEmpty
                  ? 'Tap for word details'
                  : '+${remaining.length} more ${remaining.length == 1 ? 'meaning' : 'meanings'} — tap to expand',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF657069),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      children: [
        if (remaining.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Text(
              'More verified equivalents',
              style: TextStyle(
                color: Color(0xFF657069),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TranslationMeaningList(
              translations: remaining,
              language: entry.targetLanguage,
              compact: true,
              startIndex: 1,
              totalCount: entry.translations.length,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    controller.speak(entry.sourceText, entry.sourceLanguage),
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('Pronounce'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showVocabularyEntryDetails(
                  context,
                  entry: entry,
                  controller: controller,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Full details'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
