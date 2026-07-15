import 'language_pair.dart';

class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.sourceText,
    required this.translations,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.definition,
    required this.createdAt,
    this.updatedAt,
    this.source,
    this.example,
    this.contextText,
    this.contextualExplanation,
    this.contextualExample,
    this.relatedPhrases = const [],
    this.reviewCount = 0,
    this.intervalDays = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.dictionaryRevision = 0,
  });

  final String id;
  final String sourceText;
  final List<String> translations;
  final VocabularyLanguage sourceLanguage;
  final VocabularyLanguage targetLanguage;
  final String definition;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? source;
  final String? example;
  final String? contextText;
  final String? contextualExplanation;
  final String? contextualExample;
  final List<String> relatedPhrases;
  final int reviewCount;
  final int intervalDays;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final int dictionaryRevision;

  String get translationText => translations.join('؛ ');
  LanguagePair get languagePair =>
      LanguagePair(source: sourceLanguage, target: targetLanguage);

  factory VocabularyEntry.fromJson(Map<String, Object?> json) {
    final legacyTranslation = json['arabic'] as String?;
    final translations = switch (json['translations']) {
      final List<Object?> values =>
        values
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false),
      _ when legacyTranslation != null =>
        legacyTranslation
            .split(RegExp(r'\s*[؛;]\s*'))
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false),
      _ => const <String>[],
    };
    return VocabularyEntry(
      id: json['id']! as String,
      sourceText: json['sourceText'] as String? ?? json['term']! as String,
      translations: translations,
      sourceLanguage: VocabularyLanguage.fromCode(
        json['sourceLanguage'] as String? ?? 'en',
      ),
      targetLanguage: VocabularyLanguage.fromCode(
        json['targetLanguage'] as String? ?? 'ar',
      ),
      definition: json['definition']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: _optionalDate(json['updatedAt']),
      source: json['source'] as String?,
      example: json['example'] as String?,
      contextText: json['contextText'] as String?,
      contextualExplanation: json['contextualExplanation'] as String?,
      contextualExample: json['contextualExample'] as String?,
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
    );
  }

  bool isDue(DateTime now) =>
      nextReviewAt == null || !nextReviewAt!.isAfter(now);

  DateTime get effectiveUpdatedAt => updatedAt ?? lastReviewedAt ?? createdAt;

  VocabularyEntry copyWith({
    String? sourceText,
    List<String>? translations,
    String? definition,
    String? example,
    String? contextText,
    String? contextualExplanation,
    String? contextualExample,
    List<String>? relatedPhrases,
    int? reviewCount,
    int? intervalDays,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    DateTime? updatedAt,
    int? dictionaryRevision,
  }) {
    return VocabularyEntry(
      id: id,
      sourceText: sourceText ?? this.sourceText,
      translations: translations ?? this.translations,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      definition: definition ?? this.definition,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source,
      example: example ?? this.example,
      contextText: contextText ?? this.contextText,
      contextualExplanation:
          contextualExplanation ?? this.contextualExplanation,
      contextualExample: contextualExample ?? this.contextualExample,
      relatedPhrases: relatedPhrases ?? this.relatedPhrases,
      reviewCount: reviewCount ?? this.reviewCount,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      dictionaryRevision: dictionaryRevision ?? this.dictionaryRevision,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'sourceText': sourceText,
    'translations': translations,
    'sourceLanguage': sourceLanguage.code,
    'targetLanguage': targetLanguage.code,
    'definition': definition,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'source': source,
    'example': example,
    'contextText': contextText,
    'contextualExplanation': contextualExplanation,
    'contextualExample': contextualExample,
    'relatedPhrases': relatedPhrases,
    'reviewCount': reviewCount,
    'intervalDays': intervalDays,
    'nextReviewAt': nextReviewAt?.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    'dictionaryRevision': dictionaryRevision,
  };

  static DateTime? _optionalDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
