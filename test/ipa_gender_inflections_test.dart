import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  group('VocabularySense IPA and transliteration', () {
    test('ipa and transliteration round-trip through JSON', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['مكتبة'],
        definition: 'A place to borrow books.',
        ipa: 'ma.kta.ba',
        transliteration: 'maktaba',
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.ipa, 'ma.kta.ba');
      expect(restored.transliteration, 'maktaba');
    });

    test('ipa and transliteration are null by default', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      expect(sense.ipa, isNull);
      expect(sense.transliteration, isNull);
    });

    test('copyWith preserves ipa and transliteration', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        ipa: 'test',
        transliteration: 'test',
      );
      final copied = sense.copyWith(translations: ['updated']);
      expect(copied.ipa, 'test');
      expect(copied.transliteration, 'test');
    });

    test('copyWith can override ipa and transliteration', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        ipa: 'old',
        transliteration: 'old',
      );
      final copied = sense.copyWith(ipa: 'new', transliteration: 'new');
      expect(copied.ipa, 'new');
      expect(copied.transliteration, 'new');
    });

    test('fromJson handles missing ipa and transliteration', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
      });
      expect(sense.ipa, isNull);
      expect(sense.transliteration, isNull);
    });

    test('toJson omits null ipa and transliteration', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      final json = sense.toJson();
      expect(json.containsKey('ipa'), isFalse);
      expect(json.containsKey('transliteration'), isFalse);
    });
  });

  group('VocabularySense gender', () {
    test('gender round-trips through JSON', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['maison'],
        definition: 'A house.',
        gender: 'feminine',
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.gender, 'feminine');
    });

    test('gender is null by default', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      expect(sense.gender, isNull);
    });

    test('copyWith preserves and overrides gender', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        gender: 'masculine',
      );
      final preserved = sense.copyWith(translations: ['x']);
      expect(preserved.gender, 'masculine');
      final overridden = sense.copyWith(gender: 'feminine');
      expect(overridden.gender, 'feminine');
    });

    test('toJson omits null gender', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      final json = sense.toJson();
      expect(json.containsKey('gender'), isFalse);
    });
  });

  group('VocabularySense inflections', () {
    test('inflections round-trip through JSON', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['cat'],
        definition: 'A feline.',
        inflections: {'plural': 'cats', 'possessive': "cat's"},
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.inflections, {'plural': 'cats', 'possessive': "cat's"});
    });

    test('inflections is empty by default', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      expect(sense.inflections, isEmpty);
    });

    test('copyWith preserves inflections', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        inflections: {'plural': 'tests'},
      );
      final copied = sense.copyWith(translations: ['updated']);
      expect(copied.inflections, {'plural': 'tests'});
    });

    test('copyWith can override inflections', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
        inflections: {'plural': 'tests'},
      );
      final copied = sense.copyWith(inflections: {'plural': 'testi'});
      expect(copied.inflections, {'plural': 'testi'});
    });

    test('toJson omits empty inflections', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['test'],
        definition: 'A test.',
      );
      final json = sense.toJson();
      expect(json.containsKey('inflections'), isFalse);
    });

    test('fromJson handles missing inflections', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
      });
      expect(sense.inflections, isEmpty);
    });

    test('fromJson filters out non-string inflection values', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
        'inflections': {'plural': 'tests', 'bad': 123},
      });
      expect(sense.inflections, {'plural': 'tests'});
    });

    test('inflections from JSON with non-map defaults to empty', () {
      final sense = VocabularySense.fromJson({
        'id': 'sense-1',
        'translations': ['test'],
        'definition': 'A test.',
        'inflections': 'not a map',
      });
      expect(sense.inflections, isEmpty);
    });
  });

  group('Combined new fields', () {
    test('all new fields can coexist on a single sense', () {
      const sense = VocabularySense(
        id: 'sense-1',
        translations: ['هاتف'],
        definition: 'A telephone.',
        ipa: 'haː.tif',
        transliteration: 'hatif',
        gender: 'masculine',
        inflections: {'plural': 'هواتف', 'construct': 'هاتف'},
      );
      final restored = VocabularySense.fromJson(sense.toJson());
      expect(restored.ipa, 'haː.tif');
      expect(restored.transliteration, 'hatif');
      expect(restored.gender, 'masculine');
      expect(restored.inflections, {'plural': 'هواتف', 'construct': 'هاتف'});
      expect(restored.definition, 'A telephone.');
      expect(restored.translations, ['هاتف']);
    });
  });
}
