class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.term,
    required this.arabic,
    required this.definition,
    required this.createdAt,
    this.updatedAt,
    this.source,
    this.example,
    this.reviewCount = 0,
    this.intervalDays = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
  });

  final String id;
  final String term;
  final String arabic;
  final String definition;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? source;
  final String? example;
  final int reviewCount;
  final int intervalDays;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

  factory VocabularyEntry.fromJson(Map<String, Object?> json) {
    return VocabularyEntry(
      id: json['id']! as String,
      term: json['term']! as String,
      arabic: json['arabic']! as String,
      definition: json['definition']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: _optionalDate(json['updatedAt']),
      source: json['source'] as String?,
      example: json['example'] as String?,
      reviewCount: json['reviewCount'] as int? ?? 0,
      intervalDays: json['intervalDays'] as int? ?? 0,
      nextReviewAt: _optionalDate(json['nextReviewAt']),
      lastReviewedAt: _optionalDate(json['lastReviewedAt']),
    );
  }

  bool isDue(DateTime now) =>
      nextReviewAt == null || !nextReviewAt!.isAfter(now);

  DateTime get effectiveUpdatedAt => updatedAt ?? lastReviewedAt ?? createdAt;

  VocabularyEntry copyWith({
    int? reviewCount,
    int? intervalDays,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    DateTime? updatedAt,
  }) {
    return VocabularyEntry(
      id: id,
      term: term,
      arabic: arabic,
      definition: definition,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source,
      example: example,
      reviewCount: reviewCount ?? this.reviewCount,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'term': term,
    'arabic': arabic,
    'definition': definition,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'source': source,
    'example': example,
    'reviewCount': reviewCount,
    'intervalDays': intervalDays,
    'nextReviewAt': nextReviewAt?.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
  };

  static DateTime? _optionalDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
