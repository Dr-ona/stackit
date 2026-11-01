String normalizeEnglishTerm(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeArabicTerm(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll('\u0640', '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'^[^\u0600-\u06FF0-9]+|[^\u0600-\u06FF0-9]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeFrenchTerm(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('\u2019', "'")
      .replaceAll(RegExp(r"^[^a-zà-öø-ÿœæç0-9]+|[^a-zà-öø-ÿœæç0-9]+$"), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeHindiTerm(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[\u0900-\u0903]'), '')
      .replaceAll(RegExp(r'[\u093A-\u094C\u0962-\u0963]'), '')
      .replaceAll('\u093C', '')
      .replaceAll('\u094D', '')
      .replaceAll(RegExp(r'^[^\u0900-\u097F0-9]+|[^\u0900-\u097F0-9]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeUrduTerm(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll('\u0640', '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'^[^\u0600-\u06FF0-9]+|[^\u0600-\u06FF0-9]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeFarsiTerm(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll('\u0640', '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll(RegExp(r'^[^\u0600-\u06FF0-9]+|[^\u0600-\u06FF0-9]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

Iterable<String> englishBaseFormCandidates(String value) sync* {
  if (value.contains(' ')) return;
  if (value.endsWith('ies') && value.length > 4) {
    yield '${value.substring(0, value.length - 3)}y';
  }
  if (value.endsWith('ing') && value.length > 5) {
    final stem = value.substring(0, value.length - 3);
    yield stem;
    yield '${stem}e';
    if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
      yield stem.substring(0, stem.length - 1);
    }
  }
  if (value.endsWith('ed') && value.length > 4) {
    final stem = value.substring(0, value.length - 2);
    yield stem;
    yield '${stem}e';
  }
  if (value.endsWith('s') && value.length > 3) {
    yield value.substring(0, value.length - 1);
  }
}
