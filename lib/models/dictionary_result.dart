class DictionaryResult {
  const DictionaryResult({
    required this.term,
    required this.arabic,
    required this.definition,
    this.partOfSpeech,
    this.example,
  });

  final String term;
  final String arabic;
  final String definition;
  final String? partOfSpeech;
  final String? example;

  factory DictionaryResult.fromJson(Map<String, Object?> json) {
    return DictionaryResult(
      term: json['term']! as String,
      arabic: json['arabic']! as String,
      definition: json['definition']! as String,
      partOfSpeech: json['partOfSpeech'] as String?,
      example: json['example'] as String?,
    );
  }
}
