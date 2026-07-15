class ContextualExplanation {
  const ContextualExplanation({
    required this.explanation,
    required this.example,
    required this.relatedPhrases,
  });

  final String explanation;
  final String example;
  final List<String> relatedPhrases;
}
