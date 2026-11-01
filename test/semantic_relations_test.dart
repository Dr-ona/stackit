import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  group('VocabularySense semantic relations', () {
    test('synonyms are preserved through JSON round-trip', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['happy'],
        definition: 'Feeling joy.',
        synonyms: ['joyful', 'content', 'pleased'],
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.synonyms, ['joyful', 'content', 'pleased']);
    });

    test('antonyms are preserved through JSON round-trip', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['hot'],
        definition: 'High temperature.',
        antonyms: ['cold', 'cool', 'frigid'],
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.antonyms, ['cold', 'cool', 'frigid']);
    });

    test('collocations are preserved through JSON round-trip', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['make'],
        definition: 'To create.',
        collocations: ['make a decision', 'make progress'],
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.collocations, ['make a decision', 'make progress']);
    });

    test('idioms are preserved through JSON round-trip', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['break'],
        definition: 'To shatter.',
        idioms: ['break the ice', 'break a leg'],
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.idioms, ['break the ice', 'break a leg']);
    });

    test('empty defaults for all semantic fields', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      expect(sense.synonyms, isEmpty);
      expect(sense.antonyms, isEmpty);
      expect(sense.collocations, isEmpty);
      expect(sense.idioms, isEmpty);
    });

    test('copyWith preserves all semantic fields', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        synonyms: ['a'],
        antonyms: ['b'],
        collocations: ['c'],
        idioms: ['d'],
      );
      final copied = sense.copyWith(translations: ['updated']);
      expect(copied.synonyms, ['a']);
      expect(copied.antonyms, ['b']);
      expect(copied.collocations, ['c']);
      expect(copied.idioms, ['d']);
    });

    test('copyWith can override semantic fields', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        synonyms: ['old'],
      );
      final copied = sense.copyWith(synonyms: ['new']);
      expect(copied.synonyms, ['new']);
    });

    test('fromJson handles missing semantic fields gracefully', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
      });
      expect(sense.synonyms, isEmpty);
      expect(sense.antonyms, isEmpty);
      expect(sense.collocations, isEmpty);
      expect(sense.idioms, isEmpty);
    });

    test('fromJson deduplicates semantic values', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
        'synonyms': ['a', 'a', 'b'],
        'antonyms': ['x', 'x'],
      });
      expect(sense.synonyms, ['a', 'b']);
      expect(sense.antonyms, ['x']);
    });

    test('all fields survive full JSON round-trip', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        partOfSpeech: 'noun',
        registers: ['formal'],
        synonyms: ['a', 'b'],
        antonyms: ['x'],
        collocations: ['c', 'd', 'e'],
        idioms: ['i1'],
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.id, 'sense-1');
      expect(restored.translations, ['test']);
      expect(restored.definition, 'A test.');
      expect(restored.partOfSpeech, 'noun');
      expect(restored.registers, ['formal']);
      expect(restored.synonyms, ['a', 'b']);
      expect(restored.antonyms, ['x']);
      expect(restored.collocations, ['c', 'd', 'e']);
      expect(restored.idioms, ['i1']);
    });
  });
}
