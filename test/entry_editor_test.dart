import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/entry_editor.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/models/vocabulary_sense.dart';

VocabularyEntry _entry() {
  return VocabularyEntry.withSenses(
    id: '1',
    sourceText: 'hello',
    senses: [
      VocabularySense(
        id: 's1',
        translations: ['مرحبا'],
        definition: 'greeting',
        partOfSpeech: 'noun',
        examples: [
          VocabularyExample(sourceText: 'Hello there', translation: 'مرحبا'),
        ],
      ),
      VocabularySense(
        id: 's2',
        translations: ['تلقي'],
        definition: 'to meet',
        partOfSpeech: 'verb',
      ),
    ],
    sourceLanguage: VocabularyLanguage.english,
    targetLanguage: VocabularyLanguage.arabic,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final editor = const EntryEditor();

  group('updateSense', () {
    test('updates definition of a specific sense', () {
      final entry = _entry();
      final updated = editor.updateSenseDefinition(entry, 's1', 'a greeting');
      expect(updated.senses[0].definition, 'a greeting');
      expect(updated.senses[1].definition, 'to meet');
    });

    test('updates translations of a specific sense', () {
      final entry = _entry();
      final updated = editor.updateSenseTranslations(entry, 's1', ['أهلا']);
      expect(updated.senses[0].translations, ['أهلا']);
    });

    test('updates part of speech', () {
      final entry = _entry();
      final updated = editor.updateSensePartOfSpeech(entry, 's1', 'adjective');
      expect(updated.senses[0].partOfSpeech, 'adjective');
    });

    test('no-op for unknown sense id', () {
      final entry = _entry();
      final updated = editor.updateSenseDefinition(entry, 'unknown', 'new');
      expect(updated.senses[0].definition, 'greeting');
    });
  });

  group('examples', () {
    test('adds example to sense', () {
      final entry = _entry();
      final updated = editor.addExampleToSense(
        entry,
        's2',
        VocabularyExample(sourceText: 'Nice to meet you'),
      );
      expect(updated.senses[1].examples.length, 1);
      expect(updated.senses[1].examples.first.sourceText, 'Nice to meet you');
    });

    test('removes example from sense', () {
      final entry = _entry();
      final updated = editor.removeExampleFromSense(entry, 's1', 0);
      expect(updated.senses[0].examples, isEmpty);
    });

    test('updates example in sense', () {
      final entry = _entry();
      final updated = editor.updateExampleInSense(
        entry,
        's1',
        0,
        VocabularyExample(sourceText: 'Hi there', translation: 'أهلا'),
      );
      expect(updated.senses[0].examples.first.sourceText, 'Hi there');
    });

    test('removeExample with out-of-bounds index is no-op', () {
      final entry = _entry();
      final updated = editor.removeExampleFromSense(entry, 's1', 99);
      expect(updated.senses[0].examples.length, 1);
    });
  });

  group('sense management', () {
    test('deletes a sense', () {
      final entry = _entry();
      final updated = editor.deleteSense(entry, 's1');
      expect(updated.senses.length, 1);
      expect(updated.senses[0].id, 's2');
    });

    test('cannot delete last sense', () {
      final entry = _entry();
      final oneSense = editor.deleteSense(entry, 's2');
      final result = editor.deleteSense(oneSense, 's1');
      expect(result.senses.length, 1);
    });

    test('adds a new sense', () {
      final entry = _entry();
      final newSense = VocabularySense(
        id: 's3',
        translations: ['جديد'],
        definition: 'new',
      );
      final updated = editor.addSense(entry, newSense);
      expect(updated.senses.length, 3);
      expect(updated.senses[2].id, 's3');
    });

    test('reorders senses', () {
      final entry = _entry();
      final reversed = entry.senses.reversed.toList();
      final updated = editor.reorderSenses(entry, reversed);
      expect(updated.senses[0].id, 's2');
      expect(updated.senses[1].id, 's1');
    });

    test('edits survive JSON round-trip', () {
      final entry = _entry();
      final updated = editor.updateSenseDefinition(entry, 's1', 'edited');
      final json = updated.toJson();
      final restored = VocabularyEntry.fromJson(json);
      expect(restored.senses[0].definition, 'edited');
    });
  });
}
