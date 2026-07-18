import 'language_pair.dart';
import 'vocabulary_sense.dart';

class VocabularyEntry {
  static const currentSchemaVersion = 2;

  factory VocabularyEntry({
    required String id,
    required String sourceText,
    required List<String> translations,
    required VocabularyLanguage sourceLanguage,
    required VocabularyLanguage targetLanguage,
    required String definition,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? source,
    String? example,
    String? exampleTranslation,
    String? contextText,
    String? contextualExplanation,
    String? contextualExample,
    String? contextualExampleTranslation,
    List<String> relatedPhrases = const [],
    int reviewCount = 0,
    int intervalDays = 0,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    int dictionaryRevision = 0,
  }) {
    return VocabularyEntry.withSenses(
      id: id,
      sourceText: sourceText,
      senses: [
        VocabularySense.legacy(
          translations: translations,
          definition: definition,
          example: example,
          exampleTranslation: exampleTranslation,
        ),
      ],
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source,
      contextText: contextText,
      contextualExplanation: contextualExplanation,
      contextualExample: contextualExample,
      contextualExampleTranslation: contextualExampleTranslation,
      relatedPhrases: relatedPhrases,
      reviewCount: reviewCount,
      intervalDays: intervalDays,
      nextReviewAt: nextReviewAt,
      lastReviewedAt: lastReviewedAt,
      dictionaryRevision: dictionaryRevision,
    );
  }

  const VocabularyEntry.withSenses({
    required this.id,
    required this.sourceText,
    required this.senses,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
    this.updatedAt,
    this.source,
    this.contextText,
    this.contextualExplanation,
    this.contextualExample,
    this.contextualExampleTranslation,
    this.contextualSenseId,
    this.relatedPhrases = const [],
    this.reviewCount = 0,
    this.intervalDays = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.dictionaryRevision = 0,
    this.schemaVersion = currentSchemaVersion,
  });

  final String id;
  final String sourceText;
  final List<VocabularySense> senses;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? source;
  final String? contextText;
  final String? contextualExplanation;
  final String? contextualExample;
  final String? contextualExampleTranslation;
  final String? contextualSenseId;
  final List<String> relatedPhrases;
  final int reviewCount;
  final int intervalDays;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final int dictionaryRevision;
  final int schemaVersion;

  VocabularySense get primarySense => senses.first;
  List<String> get translations => primarySense.translations;
  String get definition => primarySense.definition;
  String? get example => primarySense.primaryExample?.sourceText;
  String? get exampleTranslation => primarySense.primaryExample?.translation;
  List<String> get allTranslations => senses
      .expand((sense) => sense.translations)
      .toSet()
      .toList(growable: false);
  String get translationText => allTranslations.join('؛ ');
  bool get needsSchemaMigration => schemaVersion < currentSchemaVersion;
  LanguagePair get languagePair =>
      LanguagePair(source: sourceLanguage, target: targetLanguage);

  VocabularySense senseById(String? senseId) {
    if (senseId == null) return primarySense;
    return senses.firstWhere(
      (sense) => sense.id == senseId,
      orElse: () => primarySense,
    );
  }

  factory VocabularyEntry.fromJson(Map<String, Object?> json) {
    final legacyTranslation = json['arabic'] as String?;
    final legacyTranslations = switch (json['translations']) {
      final List<Object?> values =>
        values
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
      _ when legacyTranslation != null =>
        legacyTranslation
            .split(RegExp(r'\s*[؛;]\s*'))
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
      _ => const <String>[],
    };
    final explicitSenses = _parseSenses(json['senses']);
    final senses = explicitSenses.isNotEmpty
        ? explicitSenses
        : [
            VocabularySense.legacy(
              translations: legacyTranslations.isEmpty
                  ? const ['Translation pending']
                  : legacyTranslations,
              definition:
                  json['definition'] as String? ??
                  'Meaning not available offline yet.',
              example: json['example'] as String?,
              exampleTranslation: json['exampleTranslation'] as String?,
            ),
          ];
    return VocabularyEntry.withSenses(
      id: json['id']! as String,
      sourceText: json['sourceText'] as String? ?? json['term']! as String,
      senses: senses,
      sourceLanguage: VocabularyLanguage.fromCode(
        json['sourceLanguage'] as String? ?? 'en',
      ),
      targetLanguage: VocabularyLanguage.fromCode(
        json['targetLanguage'] as String? ?? 'ar',
      ),
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: _optionalDate(json['updatedAt']),
      source: json['source'] as String?,
      contextText: json['contextText'] as String?,
      contextualExplanation: json['contextualExplanation'] as String?,
      contextualExample: json['contextualExample'] as String?,
      contextualExampleTranslation:
          json['contextualExampleTranslation'] as String?,
      contextualSenseId: json['contextualSenseId'] as String?,
      relatedPhrases: switch (json['relatedPhrases']) {
        final List<Object?> values => values.whereType<String>().toList(
          growable: false,
        ),
        _ => const [],
      },
      reviewCount: json['reviewCount'] as int? ?? 0,
      intervalDays: json['intervalDays'] as int? ?? 0,
      nextReviewAt: _optionalDate(json['nextReviewAt']),
      lastReviewedAt: _optionalDate(json['lastReviewedAt']),
      dictionaryRevision: json['dictionaryRevision'] as int? ?? 0,
      schemaVersion: explicitSenses.isEmpty
          ? 1
          : json['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  bool isDue(DateTime now) =>
      nextReviewAt == null || !nextReviewAt!.isAfter(now);

  DateTime get effectiveUpdatedAt => updatedAt ?? lastReviewedAt ?? createdAt;

  VocabularyEntry copyWith({
    String? sourceText,
    List<VocabularySense>? senses,
    List<String>? translations,
    String? definition,
    String? example,
    String? exampleTranslation,
    String? contextText,
    String? contextualExplanation,
    String? contextualExample,
    String? contextualExampleTranslation,
    String? contextualSenseId,
    List<String>? relatedPhrases,
    int? reviewCount,
    int? intervalDays,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    DateTime? updatedAt,
    int? dictionaryRevision,
  }) {
    var updatedSenses = senses ?? this.senses;
    if (senses == null &&
        (translations != null ||
            definition != null ||
            example != null ||
            exampleTranslation != null)) {
      final currentPrimary = primarySense;
      var examples = currentPrimary.examples;
      if (example != null || exampleTranslation != null) {
        final sourceExample =
            example ?? currentPrimary.primaryExample?.sourceText;
        examples = sourceExample == null
            ? const []
            : [
                VocabularyExample(
                  sourceText: sourceExample,
                  translation:
                      exampleTranslation ??
                      currentPrimary.primaryExample?.translation,
                ),
                ...currentPrimary.examples.skip(1),
              ];
      }
      updatedSenses = [
        currentPrimary.copyWith(
          translations: translations,
          definition: definition,
          examples: examples,
        ),
        ...this.senses.skip(1),
      ];
    }
    return VocabularyEntry.withSenses(
      id: id,
      sourceText: sourceText ?? this.sourceText,
      senses: updatedSenses,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source,
      contextText: contextText ?? this.contextText,
      contextualExplanation:
          contextualExplanation ?? this.contextualExplanation,
      contextualExample: contextualExample ?? this.contextualExample,
      contextualExampleTranslation:
          contextualExampleTranslation ?? this.contextualExampleTranslation,
      contextualSenseId: contextualSenseId ?? this.contextualSenseId,
      relatedPhrases: relatedPhrases ?? this.relatedPhrases,
      reviewCount: reviewCount ?? this.reviewCount,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      dictionaryRevision: dictionaryRevision ?? this.dictionaryRevision,
    );
  }

  VocabularyEntry addExampleToSense(String senseId, VocabularyExample example) {
    final updatedSenses = senses
        .map((sense) => sense.id == senseId ? sense.addExample(example) : sense)
        .toList(growable: false);
    return copyWith(senses: updatedSenses);
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'id': id,
    'sourceText': sourceText,
    'senses': senses.map((sense) => sense.toJson()).toList(growable: false),
    // Transitional projections keep older app builds readable while v2 rolls out.
    'translations': translations,
    'sourceLanguage': sourceLanguage.code,
    'targetLanguage': targetLanguage.code,
    'definition': definition,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'source': source,
    'example': example,
    'exampleTranslation': exampleTranslation,
    'contextText': contextText,
    'contextualExplanation': contextualExplanation,
    'contextualExample': contextualExample,
    'contextualExampleTranslation': contextualExampleTranslation,
    'contextualSenseId': contextualSenseId,
    'relatedPhrases': relatedPhrases,
    'reviewCount': reviewCount,
    'intervalDays': intervalDays,
    'nextReviewAt': nextReviewAt?.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    'dictionaryRevision': dictionaryRevision,
  };

  static List<VocabularySense> _parseSenses(Object? value) {
    if (value is! List<Object?>) return const [];
    return value
        .whereType<Map>()
        .map((item) => VocabularySense.fromJson(item.cast<String, Object?>()))
        .where(
          (sense) =>
              sense.translations.isNotEmpty && sense.definition.isNotEmpty,
        )
        .toList(growable: false);
  }

  static DateTime? _optionalDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
