import 'language_pair.dart';

class DictionaryResult {
  const DictionaryResult({
    required this.sourceText,
    required this.translations,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.definition,
    this.partOfSpeech,
    this.example,
  });

  final String sourceText;
  final List<String> translations;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;
  final String definition;
  final String? partOfSpeech;
  final String? example;

  String get translationText => translations.join('؛ ');

  factory DictionaryResult.fromLegacyJson(
    Map<String, Object?> json, {
    LanguagePair pair = LanguagePair.englishToArabic,
  }) {
    return DictionaryResult(
      sourceText: json['term']! as String,
      translations: splitLegacyTranslations(json['arabic']! as String),
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
      definition: json['definition']! as String,
      partOfSpeech: json['partOfSpeech'] as String?,
      example: json['example'] as String?,
    );
  }
}

List<String> splitLegacyTranslations(String value) {
  final translations = value
      .split(RegExp(r'\s*[؛;]\s*'))
      .map((translation) => translation.trim())
      .where((translation) => translation.isNotEmpty)
      .toList(growable: false);
  return translations.isEmpty ? [value.trim()] : translations;
}
