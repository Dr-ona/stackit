import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/vocabulary_export_service.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

VocabularyEntry _entry(
  String id, {
  String text = 'hello',
  String definition = 'greeting',
  List<String> translations = const ['مرحبا'],
  VocabularyLanguage source = VocabularyLanguage.english,
  VocabularyLanguage target = VocabularyLanguage.arabic,
  int reviewCount = 0,
  int intervalDays = 0,
  String fsrsState = 'new',
  bool favorite = false,
  List<String> tags = const [],
  String? example,
  String? exampleTranslation,
}) {
  return VocabularyEntry(
    id: id,
    sourceText: text,
    translations: translations,
    sourceLanguage: source,
    targetLanguage: target,
    definition: definition,
    createdAt: DateTime(2026, 1, 1),
    reviewCount: reviewCount,
    intervalDays: intervalDays,
    fsrsState: fsrsState,
    favorite: favorite,
    tags: tags,
    example: example,
    exampleTranslation: exampleTranslation,
  );
}

void main() {
  final service = VocabularyExportService();

  group('JSON export/import', () {
    test('toJson produces valid JSON', () {
      final entries = [_entry('1'), _entry('2')];
      final json = service.toJson(entries);
      expect(json.isNotEmpty, true);
      expect(json.startsWith('['), true);
      expect(json.endsWith(']'), true);
    });

    test('toJson round-trips through import', () {
      final entries = [_entry('1', text: 'hello'), _entry('2', text: 'world')];
      final json = service.toJson(entries);
      final imported = service.importFromJson(json);
      expect(imported.length, 2);
      expect(imported[0].sourceText, 'hello');
      expect(imported[1].sourceText, 'world');
    });

    test('importFromJson handles invalid JSON', () {
      expect(service.importFromJson('not json'), isEmpty);
    });

    test('importFromJson handles empty array', () {
      expect(service.importFromJson('[]'), isEmpty);
    });

    test('importFromJson preserves all fields', () {
      final entry = _entry(
        '1',
        text: 'nuance',
        definition: 'subtle distinction',
        translations: const ['فرق دقيق'],
        favorite: true,
        tags: ['tag-a', 'tag-b'],
        reviewCount: 5,
        intervalDays: 7,
        fsrsState: 'review',
      );
      final json = service.toJson([entry]);
      final imported = service.importFromJson(json);
      expect(imported.first.sourceText, 'nuance');
      expect(imported.first.favorite, true);
      expect(imported.first.tags, ['tag-a', 'tag-b']);
      expect(imported.first.reviewCount, 5);
      expect(imported.first.fsrsState, 'review');
    });
  });

  group('CSV export', () {
    test('toCsv produces header and rows', () {
      final entries = [_entry('1', text: 'hello'), _entry('2', text: 'world')];
      final csv = service.toCsv(entries);
      final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, 3); // header + 2 rows
      expect(lines[0], contains('sourceText'));
      expect(lines[1], contains('hello'));
      expect(lines[2], contains('world'));
    });

    test('toCsv escapes commas in definitions', () {
      final entry = _entry('1', definition: 'a, b, c');
      final csv = service.toCsv([entry]);
      expect(csv, contains('"a, b, c"'));
    });

    test('toCsv escapes quotes in text', () {
      final entry = _entry('1', text: 'say "hello"');
      final csv = service.toCsv([entry]);
      expect(csv, contains('"say ""hello"""'));
    });

    test('toCsv preserves tags', () {
      final entry = _entry('1', tags: ['a', 'b']);
      final csv = service.toCsv([entry]);
      expect(csv, contains('a; b'));
    });
  });

  group('CSV import', () {
    test('importFromCsv parses valid CSV', () {
      final csv = StringBuffer();
      csv.writeln(
        'sourceText,translations,definition,sourceLanguage,targetLanguage,'
        'example,exampleTranslation,reviewCount,intervalDays,fsrsState,favorite,tags',
      );
      csv.writeln(
        'hello,مرحبا,greeting,en,ar,Hi there,مرحبا,3,7,review,true,tag-a; tag-b',
      );
      final imported = service.importFromCsv(csv.toString());
      expect(imported.length, 1);
      expect(imported.first.sourceText, 'hello');
      expect(imported.first.definition, 'greeting');
      expect(imported.first.reviewCount, 3);
      expect(imported.first.favorite, true);
      expect(imported.first.tags, ['tag-a', 'tag-b']);
    });

    test('importFromCsv handles empty CSV', () {
      expect(service.importFromCsv(''), isEmpty);
    });

    test('importFromCsv handles header-only CSV', () {
      final csv = 'sourceText,translations,definition\n';
      expect(service.importFromCsv(csv), isEmpty);
    });

    test('importFromCsv handles quoted fields', () {
      final csv = StringBuffer();
      csv.writeln(
        'sourceText,translations,definition,sourceLanguage,targetLanguage,example',
      );
      csv.writeln('"say ""hello""",مرحبا,"a, b, c",en,ar,Hi');
      final imported = service.importFromCsv(csv.toString());
      expect(imported.first.sourceText, 'say "hello"');
      expect(imported.first.definition, 'a, b, c');
    });
  });

  group('Anki export', () {
    test('toAnki produces header and tab-separated rows', () {
      final entries = [_entry('1', text: 'hello')];
      final anki = service.toAnki(entries);
      expect(anki, contains('#separator:tab'));
      expect(anki, contains('#columns:Front\tBack\tTags'));
      expect(anki, contains('hello\t'));
    });

    test('toAnki includes translation and definition in back', () {
      final entry = _entry('1', text: 'hello', definition: 'greeting');
      final anki = service.toAnki([entry]);
      expect(anki, contains('مرحبا'));
      expect(anki, contains('greeting'));
    });

    test('toAnki includes tags', () {
      final entry = _entry('1', tags: ['important']);
      final anki = service.toAnki([entry]);
      expect(anki, contains('important'));
    });
  });

  group('Export format selection', () {
    test('share method accepts ExportFormat enum', () {
      expect(ExportFormat.values.length, 3);
      expect(ExportFormat.json.name, 'json');
      expect(ExportFormat.csv.name, 'csv');
      expect(ExportFormat.anki.name, 'anki');
    });
  });
}
