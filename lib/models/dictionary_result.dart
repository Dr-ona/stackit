import 'language_pair.dart';
import 'vocabulary_sense.dart';

class DictionaryResult {
  factory DictionaryResult({
    required String sourceText,
    required List<String> translations,
    required VocabularyLanguage sourceLanguage,
    required VocabularyLanguage targetLanguage,
    required String definition,
    String? partOfSpeech,
    String? example,
    String? exampleTranslation,
  }) {
    return DictionaryResult.withSenses(
      sourceText: sourceText,
      senses: [
        VocabularySense.legacy(
          translations: translations,
          definition: definition,
          partOfSpeech: partOfSpeech,
          example: example,
          exampleTranslation: exampleTranslation,
        ),
      ],
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  const DictionaryResult.withSenses({
    required this.sourceText,
    required this.senses,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final String sourceText;
  final List<VocabularySense> senses;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;

  VocabularySense get primarySense => senses.first;
  List<String> get translations => primarySense.translations;
  String get definition => primarySense.definition;
  String? get partOfSpeech => primarySense.partOfSpeech;
  String? get example => primarySense.primaryExample?.sourceText;
  String? get exampleTranslation => primarySense.primaryExample?.translation;
  String get translationText =>
      senses.expand((sense) => sense.translations).toSet().join('؛ ');

  factory DictionaryResult.fromLegacyJson(
    Map<String, Object?> json, {
    LanguagePair pair = LanguagePair.englishToArabic,
  }) {
    final explicitSenses = switch (json['senses']) {
      final List<Object?> values =>
        values
            .whereType<Map>()
            .map(
              (value) =>
                  VocabularySense.fromJson(value.cast<String, Object?>()),
            )
            .where(
              (sense) =>
                  sense.translations.isNotEmpty && sense.definition.isNotEmpty,
            )
            .toList(growable: false),
      _ => const <VocabularySense>[],
    };
    return DictionaryResult.withSenses(
      sourceText: json['term']! as String,
      senses: explicitSenses.isNotEmpty
          ? explicitSenses
          : [
              VocabularySense.legacy(
                translations: splitLegacyTranslations(
                  json['arabic']! as String,
                ),
                definition: json['definition']! as String,
                partOfSpeech: json['partOfSpeech'] as String?,
                example: json['example'] as String?,
                exampleTranslation: json['exampleTranslation'] as String?,
              ),
            ],
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
    );
  }

  DictionaryResult copyWithPrimaryTranslations(Iterable<String> translations) {
    final updatedPrimary = primarySense.copyWith(
      translations: translations.take(32).toList(growable: false),
    );
    return DictionaryResult.withSenses(
      sourceText: sourceText,
      senses: [updatedPrimary, ...senses.skip(1)],
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
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
