import 'package:flutter/material.dart';

import '../../models/language_pair.dart';

class TranslationMeaningList extends StatelessWidget {
  const TranslationMeaningList({
    super.key,
    required this.translations,
    required this.language,
    this.compact = false,
    this.startIndex = 0,
    this.totalCount,
  }) : assert(startIndex >= 0),
       assert(
         totalCount == null || totalCount >= startIndex + translations.length,
       );

  final List<String> translations;
  final VocabularyLanguage language;
  final bool compact;
  final int startIndex;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final direction = language.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final meaningTotal = totalCount ?? translations.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < translations.length; index++) ...[
          Semantics(
            label:
                'Meaning ${startIndex + index + 1} of $meaningTotal: '
                '${translations[index]}',
            child: Directionality(
              textDirection: direction,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 11 : 14,
                  vertical: compact ? 8 : 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3ECE6),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 24 : 28,
                      height: compact ? 24 : 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC6DDD2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${startIndex + index + 1}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: const Color(0xFF275E50),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 9 : 12),
                    Expanded(
                      child: Text(
                        translations[index],
                        textAlign: language.isRtl
                            ? TextAlign.right
                            : TextAlign.left,
                        style:
                            (compact
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.titleLarge)
                                ?.copyWith(
                                  color: const Color(0xFF356859),
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (index != translations.length - 1)
            SizedBox(height: compact ? 6 : 8),
        ],
      ],
    );
  }
}
