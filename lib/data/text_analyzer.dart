enum TextUnit { word, phrase }

class TextAnalyzer {
  const TextAnalyzer._();

  static TextUnit classify(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextUnit.word;
    final segments = trimmed.split(RegExp(r'\s+'));
    if (segments.length == 1) return TextUnit.word;
    return TextUnit.phrase;
  }

  static bool isMultiword(String text) => classify(text) == TextUnit.phrase;

  static int wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  static String normalizeForSearch(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
