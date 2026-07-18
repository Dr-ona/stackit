class ContextualExplanation {
  const ContextualExplanation({
    required this.explanation,
    required this.example,
    required this.exampleTranslation,
    required this.relatedPhrases,
  });

  final String explanation;
  final String example;
  final String exampleTranslation;
  final List<String> relatedPhrases;
}
