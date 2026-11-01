import '../models/vocabulary_entry.dart';
import '../models/vocabulary_sense.dart';

class EntryEditor {
  const EntryEditor();

  VocabularyEntry updateSense(
    VocabularyEntry entry,
    String senseId,
    VocabularySense Function(VocabularySense sense) updater,
  ) {
    final updatedSenses = entry.senses
        .map((sense) => sense.id == senseId ? updater(sense) : sense)
        .toList(growable: false);
    return entry.copyWith(senses: updatedSenses);
  }

  VocabularyEntry updateSenseDefinition(
    VocabularyEntry entry,
    String senseId,
    String definition,
  ) {
    return updateSense(
      entry,
      senseId,
      (s) => s.copyWith(definition: definition),
    );
  }

  VocabularyEntry updateSenseTranslations(
    VocabularyEntry entry,
    String senseId,
    List<String> translations,
  ) {
    return updateSense(
      entry,
      senseId,
      (s) => s.copyWith(translations: translations),
    );
  }

  VocabularyEntry updateSensePartOfSpeech(
    VocabularyEntry entry,
    String senseId,
    String? partOfSpeech,
  ) {
    return updateSense(
      entry,
      senseId,
      (s) => s.copyWith(partOfSpeech: partOfSpeech),
    );
  }

  VocabularyEntry addExampleToSense(
    VocabularyEntry entry,
    String senseId,
    VocabularyExample example,
  ) {
    return updateSense(entry, senseId, (s) {
      return s.copyWith(examples: [...s.examples, example]);
    });
  }

  VocabularyEntry removeExampleFromSense(
    VocabularyEntry entry,
    String senseId,
    int exampleIndex,
  ) {
    return updateSense(entry, senseId, (s) {
      final updated = List<VocabularyExample>.from(s.examples);
      if (exampleIndex >= 0 && exampleIndex < updated.length) {
        updated.removeAt(exampleIndex);
      }
      return s.copyWith(examples: updated);
    });
  }

  VocabularyEntry updateExampleInSense(
    VocabularyEntry entry,
    String senseId,
    int exampleIndex,
    VocabularyExample example,
  ) {
    return updateSense(entry, senseId, (s) {
      final updated = List<VocabularyExample>.from(s.examples);
      if (exampleIndex >= 0 && exampleIndex < updated.length) {
        updated[exampleIndex] = example;
      }
      return s.copyWith(examples: updated);
    });
  }

  VocabularyEntry deleteSense(VocabularyEntry entry, String senseId) {
    if (entry.senses.length <= 1) return entry;
    final updated = entry.senses
        .where((s) => s.id != senseId)
        .toList(growable: false);
    return entry.copyWith(senses: updated);
  }

  VocabularyEntry addSense(VocabularyEntry entry, VocabularySense sense) {
    return entry.copyWith(senses: [...entry.senses, sense]);
  }

  VocabularyEntry reorderSenses(
    VocabularyEntry entry,
    List<VocabularySense> reordered,
  ) {
    return entry.copyWith(senses: reordered);
  }
}
