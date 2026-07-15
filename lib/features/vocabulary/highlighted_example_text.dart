import 'package:flutter/material.dart';

import '../../models/language_pair.dart';

class HighlightedExampleText extends StatelessWidget {
  const HighlightedExampleText({
    super.key,
    required this.example,
    required this.term,
    required this.language,
    this.style,
  });

  final String example;
  final String term;
  final VocabularyLanguage language;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style.merge(style);
    final highlightStyle = baseStyle.copyWith(
      color: const Color(0xFF275E50),
      backgroundColor: const Color(0xFFCFE3D9),
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.normal,
    );
    final spans = <InlineSpan>[const TextSpan(text: '“')];
    final normalizedTerm = term.trim();
    if (normalizedTerm.isEmpty) {
      spans.add(TextSpan(text: example));
    } else {
      final matches = RegExp(
        RegExp.escape(normalizedTerm),
        caseSensitive: false,
        unicode: true,
      ).allMatches(example);
      var cursor = 0;
      for (final match in matches) {
        if (match.start > cursor) {
          spans.add(TextSpan(text: example.substring(cursor, match.start)));
        }
        spans.add(
          TextSpan(
            text: example.substring(match.start, match.end),
            style: highlightStyle,
          ),
        );
        cursor = match.end;
      }
      if (cursor < example.length) {
        spans.add(TextSpan(text: example.substring(cursor)));
      }
    }
    spans.add(const TextSpan(text: '”'));

    return Semantics(
      label: '“$example”',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(style: baseStyle, children: spans),
          textDirection: language.isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }
}
