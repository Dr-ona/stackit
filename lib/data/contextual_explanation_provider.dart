import '../models/contextual_explanation.dart';
import '../models/vocabulary_entry.dart';

abstract interface class ContextualExplanationService {
  Future<ContextualExplanation> explain(
    VocabularyEntry entry, {
    String? senseId,
    String? context,
  });
}

class ContextualExplanationException implements Exception {
  const ContextualExplanationException(this.message);

  final String message;

  @override
  String toString() => message;
}
