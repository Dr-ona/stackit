import 'text_analyzer.dart';
import '../../models/vocabulary_entry.dart';
import '../../models/vocabulary_sense.dart';

class SearchService {
  const SearchService();

  List<VocabularyEntry> search(List<VocabularyEntry> entries, String query) {
    if (query.trim().isEmpty) return entries;
    final normalized = TextAnalyzer.normalizeForSearch(query);
    return entries
        .where((e) => _matchesEntry(e, normalized))
        .toList(growable: false);
  }

  bool _matchesEntry(VocabularyEntry entry, String normalized) {
    if (TextAnalyzer.normalizeForSearch(entry.sourceText).contains(normalized)) {
      return true;
    }
    if (TextAnalyzer.normalizeForSearch(entry.definition).contains(normalized)) {
      return true;
    }
    if (TextAnalyzer.normalizeForSearch(
      entry.translationText,
    ).contains(normalized)) {
      return true;
    }
    if (entry.example != null &&
        TextAnalyzer.normalizeForSearch(entry.example!).contains(normalized)) {
      return true;
    }
    if (entry.exampleTranslation != null &&
        TextAnalyzer.normalizeForSearch(
          entry.exampleTranslation!,
        ).contains(normalized)) {
      return true;
    }
    if (entry.contextText != null &&
        TextAnalyzer.normalizeForSearch(
          entry.contextText!,
        ).contains(normalized)) {
      return true;
    }
    if (entry.relatedPhrases.any(
      (phrase) => TextAnalyzer.normalizeForSearch(phrase).contains(normalized),
    )) {
      return true;
    }
    for (final sense in entry.senses) {
      if (_matchesSense(sense, normalized)) return true;
    }
    return false;
  }

  bool _matchesSense(VocabularySense sense, String normalized) {
    if (sense.translations.any(
      (t) => TextAnalyzer.normalizeForSearch(t).contains(normalized),
    )) {
      return true;
    }
    if (TextAnalyzer.normalizeForSearch(sense.definition).contains(normalized)) {
      return true;
    }
    for (final example in sense.examples) {
      if (TextAnalyzer.normalizeForSearch(
        example.sourceText,
      ).contains(normalized)) {
        return true;
      }
      if (example.translation != null &&
          TextAnalyzer.normalizeForSearch(
            example.translation!,
          ).contains(normalized)) {
        return true;
      }
    }
    if (sense.ipa != null &&
        TextAnalyzer.normalizeForSearch(sense.ipa!).contains(normalized)) {
      return true;
    }
    if (sense.synonyms.any(
      (s) => TextAnalyzer.normalizeForSearch(s).contains(normalized),
    )) {
      return true;
    }
    if (sense.antonyms.any(
      (a) => TextAnalyzer.normalizeForSearch(a).contains(normalized),
    )) {
      return true;
    }
    return false;
  }
}
