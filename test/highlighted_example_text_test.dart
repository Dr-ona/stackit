import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/features/vocabulary/highlighted_example_text.dart';
import 'package:stackit/models/language_pair.dart';

void main() {
  testWidgets('highlights the selected term inside an example', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HighlightedExampleText(
            example: 'Ultimately, the decision was ultimately simple.',
            term: 'ultimately',
            language: VocabularyLanguage.english,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText).last);
    final highlighted = <TextSpan>[];
    void collect(InlineSpan span) {
      if (span is! TextSpan) return;
      if (span.text?.toLowerCase() == 'ultimately') highlighted.add(span);
      for (final child in span.children ?? const <InlineSpan>[]) {
        collect(child);
      }
    }

    collect(richText.text);
    expect(highlighted, hasLength(2));
    expect(highlighted.first.style?.fontWeight, FontWeight.w900);
    expect(highlighted.first.style?.backgroundColor, const Color(0xFFCFE3D9));
  });
}
