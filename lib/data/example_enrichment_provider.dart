import '../models/language_pair.dart';
import '../models/vocabulary_sense.dart';

abstract interface class ExampleEnrichmentService {
  Future<List<VocabularySense>> enrichExamples({
    required String sourceText,
    required List<VocabularySense> senses,
    required LanguagePair pair,
  });
}

class ExampleEnrichmentException implements Exception {
  const ExampleEnrichmentException(this.message);

  final String message;

  @override
  String toString() => message;
}
