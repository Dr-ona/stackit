import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  group('VocabularySense registers', () {
    test('registers are preserved through JSON round-trip', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        partOfSpeech: 'noun',
        registers: ['formal', 'technical'],
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.registers, ['formal', 'technical']);
    });

    test('empty registers is the default', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      expect(sense.registers, isEmpty);
    });

    test('registers are included in toJson', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        registers: ['informal'],
      );
      final json = sense.toJson();
      expect(json['registers'], ['informal']);
    });

    test('copyWith preserves registers', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        registers: ['literary'],
      );
      final copied = sense.copyWith(translations: ['updated']);
      expect(copied.registers, ['literary']);
    });

    test('copyWith can override registers', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        registers: ['old'],
      );
      final copied = sense.copyWith(registers: ['new']);
      expect(copied.registers, ['new']);
    });

    test('fromJson handles missing registers gracefully', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
      });
      expect(sense.registers, isEmpty);
    });

    test('fromJson deduplicates registers', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
        'registers': ['formal', 'formal'],
      });
      expect(sense.registers, ['formal']);
    });
  });
}
