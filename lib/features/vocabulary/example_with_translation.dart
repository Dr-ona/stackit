import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/language_pair.dart';
import 'highlighted_example_text.dart';

class ExampleWithTranslation extends StatelessWidget {
  const ExampleWithTranslation({
    super.key,
    required this.example,
    required this.term,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.translation,
    this.sourceStyle,
    this.translationStyle,
  });

  final String example;
  final String term;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;
  final String? translation;
  final TextStyle? sourceStyle;
  final TextStyle? translationStyle;

  @override
  Widget build(BuildContext context) {
    final translated = translation?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightedExampleText(
          example: example,
          term: term,
          language: sourceLanguage,
          style: sourceStyle,
        ),
        if (translated != null && translated.isNotEmpty) ...[
          const SizedBox(height: 10),
          Semantics(
            label: context.l10n.exampleTranslation,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    translated,
                    textDirection: targetLanguage.isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style:
                        translationStyle ??
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF356859),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
