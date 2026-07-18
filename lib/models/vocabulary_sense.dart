class VocabularyExample {
  const VocabularyExample({required this.sourceText, this.translation});

  final String sourceText;
  final String? translation;

  factory VocabularyExample.fromJson(Map<String, Object?> json) {
    return VocabularyExample(
      sourceText: (json['sourceText'] as String? ?? '').trim(),
      translation: _cleanOptional(json['translation'] as String?),
    );
  }

  Map<String, Object?> toJson() => {
    'sourceText': sourceText,
    'translation': translation,
  };
}

class VocabularySense {
  const VocabularySense({
    required this.id,
    required this.translations,
    required this.definition,
    this.partOfSpeech,
    this.examples = const [],
  });

  static const legacyId = 'sense-1';

  final String id;
  final List<String> translations;
  final String definition;
  final String? partOfSpeech;
  final List<VocabularyExample> examples;

  String get primaryTranslation => translations.first;
  VocabularyExample? get primaryExample => examples.firstOrNull;

  factory VocabularySense.fromJson(Map<String, Object?> json) {
    final translations = switch (json['translations']) {
      final List<Object?> values => _cleanStrings(values),
      _ => const <String>[],
    };
    final examples = switch (json['examples']) {
      final List<Object?> values =>
        values
            .whereType<Map>()
            .map(
              (value) =>
                  VocabularyExample.fromJson(value.cast<String, Object?>()),
            )
            .where((example) => example.sourceText.isNotEmpty)
            .toList(growable: false),
      _ => const <VocabularyExample>[],
    };
    return VocabularySense(
      id: (json['id'] as String? ?? legacyId).trim(),
      translations: translations,
      definition: (json['definition'] as String? ?? '').trim(),
      partOfSpeech: _cleanOptional(json['partOfSpeech'] as String?),
      examples: examples,
    );
  }

  factory VocabularySense.legacy({
    required List<String> translations,
    required String definition,
    String? partOfSpeech,
    String? example,
    String? exampleTranslation,
  }) {
    final cleanExample = _cleanOptional(example);
    return VocabularySense(
      id: legacyId,
      translations: _cleanStrings(translations),
      definition: definition.trim(),
      partOfSpeech: _cleanOptional(partOfSpeech),
      examples: cleanExample == null
          ? const []
          : [
              VocabularyExample(
                sourceText: cleanExample,
                translation: _cleanOptional(exampleTranslation),
              ),
            ],
    );
  }

  VocabularySense copyWith({
    List<String>? translations,
    String? definition,
    String? partOfSpeech,
    List<VocabularyExample>? examples,
  }) {
    return VocabularySense(
      id: id,
      translations: translations ?? this.translations,
      definition: definition ?? this.definition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      examples: examples ?? this.examples,
    );
  }

  VocabularySense addExample(VocabularyExample example) {
    final normalizedSource = example.sourceText.trim().toLowerCase();
    if (normalizedSource.isEmpty ||
        examples.any(
          (candidate) =>
              candidate.sourceText.trim().toLowerCase() == normalizedSource,
        )) {
      return this;
    }
    return copyWith(examples: [...examples, example]);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'translations': translations,
    'definition': definition,
    'partOfSpeech': partOfSpeech,
    'examples': examples
        .map((example) => example.toJson())
        .toList(growable: false),
  };
}

List<String> _cleanStrings(Iterable<Object?> values) {
  return values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

String? _cleanOptional(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? null : clean;
}
