import 'dart:convert';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import '../models/language_pair.dart';
import '../models/vocabulary_entry.dart';

enum ExportFormat { json, csv, anki }

class VocabularyExportService {
  const VocabularyExportService();

  String toJson(List<VocabularyEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList(growable: false));
  }

  String toCsv(List<VocabularyEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln(
      'sourceText,translations,definition,sourceLanguage,targetLanguage,'
      'example,exampleTranslation,reviewCount,intervalDays,fsrsState,favorite,tags',
    );
    for (final entry in entries) {
      buffer.writeln(
        _escapeCsvRow([
          entry.sourceText,
          entry.translations.join('; '),
          entry.definition,
          entry.sourceLanguage.code,
          entry.targetLanguage.code,
          entry.example ?? '',
          entry.exampleTranslation ?? '',
          entry.reviewCount.toString(),
          entry.intervalDays.toString(),
          entry.fsrsState,
          entry.favorite ? 'true' : 'false',
          entry.tags.join('; '),
        ]),
      );
    }
    return buffer.toString();
  }

  String toAnki(List<VocabularyEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('#separator:tab');
    buffer.writeln('#html:false');
    buffer.writeln('#columns:Front\tBack\tTags');
    for (final entry in entries) {
      final front = entry.sourceText;
      final backParts = <String>[
        entry.translationText,
        if (entry.definition.isNotEmpty) entry.definition,
        if (entry.example != null) entry.example!,
      ];
      final back = backParts.join(' | ');
      final tags = entry.tags.join(' ');
      buffer.writeln('$front\t$back\t$tags');
    }
    return buffer.toString();
  }

  Future<void> share(
    List<VocabularyEntry> entries, {
    ExportFormat format = ExportFormat.json,
    Rect? sharePositionOrigin,
  }) async {
    final content = switch (format) {
      ExportFormat.json => toJson(entries),
      ExportFormat.csv => toCsv(entries),
      ExportFormat.anki => toAnki(entries),
    };
    final ext = switch (format) {
      ExportFormat.json => 'json',
      ExportFormat.csv => 'csv',
      ExportFormat.anki => 'txt',
    };
    final mime = switch (format) {
      ExportFormat.json => 'application/json',
      ExportFormat.csv => 'text/csv',
      ExportFormat.anki => 'text/plain',
    };
    final stamp = DateTime.now().toUtc().toIso8601String().split('T').first;
    final file = XFile.fromData(utf8.encode(content), mimeType: mime);
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: ['stackit-vocabulary-$stamp.$ext'],
        title: 'Stackit vocabulary export',
        subject: 'My Stackit vocabulary',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  List<VocabularyEntry> importFromJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List<Object?>) return const [];
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map((m) => VocabularyEntry.fromJson(m.cast<String, Object?>()))
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  List<VocabularyEntry> importFromCsv(String csv) {
    final lines = const LineSplitter().convert(csv);
    if (lines.length < 2) return const [];
    // Skip header row
    final entries = <VocabularyEntry>[];
    for (var i = 1; i < lines.length; i++) {
      final fields = _parseCsvRow(lines[i]);
      if (fields.length < 6) continue;
      final sourceLang =
          VocabularyLanguage.tryFromCode(fields[3]) ??
          VocabularyLanguage.english;
      final targetLang =
          VocabularyLanguage.tryFromCode(fields[4]) ??
          VocabularyLanguage.arabic;
      entries.add(
        VocabularyEntry(
          id: 'import_${DateTime.now().millisecondsSinceEpoch}_$i',
          sourceText: fields[0],
          translations: fields[1]
              .split(RegExp(r'\s*[;]\s*'))
              .where((s) => s.isNotEmpty)
              .toList(),
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          definition: fields[2].isEmpty ? 'Imported' : fields[2],
          createdAt: DateTime.now(),
          example: fields[5].isEmpty ? null : fields[5],
          exampleTranslation: fields.length > 6 && fields[6].isNotEmpty
              ? fields[6]
              : null,
          reviewCount: fields.length > 7 ? int.tryParse(fields[7]) ?? 0 : 0,
          intervalDays: fields.length > 8 ? int.tryParse(fields[8]) ?? 0 : 0,
          fsrsState: fields.length > 9 && fields[9].isNotEmpty
              ? fields[9]
              : 'new',
          favorite: fields.length > 10 && fields[10] == 'true',
          tags: fields.length > 11
              ? fields[11]
                    .split(RegExp(r'\s*[;]\s*'))
                    .where((s) => s.isNotEmpty)
                    .toList()
              : const [],
        ),
      );
    }
    return entries;
  }

  static String _escapeCsvRow(List<String> fields) {
    return fields
        .map((f) {
          if (f.contains(',') || f.contains('"') || f.contains('\n')) {
            return '"${f.replaceAll('"', '""')}"';
          }
          return f;
        })
        .join(',');
  }

  static List<String> _parseCsvRow(String line) {
    final fields = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          current.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          fields.add(current.toString());
          current = StringBuffer();
        } else {
          current.write(c);
        }
      }
    }
    fields.add(current.toString());
    return fields;
  }
}
