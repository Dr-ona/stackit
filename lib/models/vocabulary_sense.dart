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
    this.registers = const [],
    this.synonyms = const [],
    this.antonyms = const [],
    this.collocations = const [],
    this.idioms = const [],
    this.ipa,
    this.transliteration,
    this.gender,
    this.inflections = const {},
  });

  static const legacyId = 'sense-1';

  final String id;
  final List<String> translations;
  final String definition;
  final String? partOfSpeech;
  final List<VocabularyExample> examples;
  final List<String> registers;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> collocations;
  final List<String> idioms;
  final String? ipa;
  final String? transliteration;
  final String? gender;
  final Map<String, String> inflections;

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
      registers: switch (json['registers']) {
        final List<Object?> values => _cleanStrings(values),
        _ => const [],
      },
      synonyms: switch (json['synonyms']) {
        final List<Object?> values => _cleanStrings(values),
        _ => const [],
      },
      antonyms: switch (json['antonyms']) {
        final List<Object?> values => _cleanStrings(values),
        _ => const [],
      },
      collocations: switch (json['collocations']) {
        final List<Object?> values => _cleanStrings(values),
        _ => const [],
      },
      idioms: switch (json['idioms']) {
        final List<Object?> values => _cleanStrings(values),
        _ => const [],
      },
      ipa: _cleanOptional(json['ipa'] as String?),
      transliteration: _cleanOptional(json['transliteration'] as String?),
      gender: _cleanOptional(json['gender'] as String?),
      inflections: switch (json['inflections']) {
        final Map<Object?, Object?> values => {
          for (final entry in values.entries)
            if (entry.key is String && entry.value is String)
              entry.key as String: (entry.value as String).trim(),
        },
        _ => const {},
      },
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
    List<String>? registers,
    List<String>? synonyms,
    List<String>? antonyms,
    List<String>? collocations,
    List<String>? idioms,
    String? ipa,
    String? transliteration,
    String? gender,
    Map<String, String>? inflections,
  }) {
    return VocabularySense(
      id: id,
      translations: translations ?? this.translations,
      definition: definition ?? this.definition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      examples: examples ?? this.examples,
      registers: registers ?? this.registers,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      collocations: collocations ?? this.collocations,
      idioms: idioms ?? this.idioms,
      ipa: ipa ?? this.ipa,
      transliteration: transliteration ?? this.transliteration,
      gender: gender ?? this.gender,
      inflections: inflections ?? this.inflections,
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
    'registers': registers,
    'synonyms': synonyms,
    'antonyms': antonyms,
    'collocations': collocations,
    'idioms': idioms,
    if (ipa != null) 'ipa': ipa,
    if (transliteration != null) 'transliteration': transliteration,
    if (gender != null) 'gender': gender,
    if (inflections.isNotEmpty) 'inflections': inflections,
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
