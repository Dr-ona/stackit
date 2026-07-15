import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stackit/data/dictionary_normalization.dart';

const _sourcePath = 'third_party/freedict/eng-ara-0.6.3/eng-ara/eng-ara.tei';
const _licenseSourcePath = 'third_party/freedict/eng-ara-0.6.3/eng-ara/COPYING';
const _englishArabicOutputPath =
    'assets/dictionaries/freedict_en_ar.stkdict.gz';
const _arabicEnglishOutputPath =
    'assets/dictionaries/freedict_ar_en.stkdict.gz';
const _licenseOutputPath = 'assets/licenses/freedict-eng-ara-COPYING.txt';
const _magic = 'STKD';
const _version = 2;

void main() {
  final source = File(_sourcePath);
  if (!source.existsSync()) {
    stderr.writeln('Missing FreeDict source: $_sourcePath');
    exitCode = 2;
    return;
  }

  final xml = source.readAsStringSync();
  final entries = <String, Set<String>>{};
  final reverseEntries = <String, Set<String>>{};
  final entryPattern = RegExp(
    r'<entry(?:\s[^>]*)?>(.*?)</entry>',
    dotAll: true,
  );
  final orthPattern = RegExp(r'<orth(?:\s[^>]*)?>(.*?)</orth>', dotAll: true);
  final quotePattern = RegExp(
    r'<quote(?:\s[^>]*)?>(.*?)</quote>',
    dotAll: true,
  );

  for (final match in entryPattern.allMatches(xml)) {
    final block = match.group(1)!;
    final orthMatch = orthPattern.firstMatch(block);
    if (orthMatch == null) continue;
    final term = normalizeEnglishTerm(_plainText(orthMatch.group(1)!));
    if (term.isEmpty) continue;

    final translations = entries.putIfAbsent(term, () => <String>{});
    for (final quote in quotePattern.allMatches(block)) {
      final translation = _plainText(quote.group(1)!);
      if (translation.isNotEmpty) {
        translations.add(translation);
        final normalizedArabic = normalizeArabicTerm(translation);
        if (normalizedArabic.isNotEmpty) {
          reverseEntries
              .putIfAbsent(normalizedArabic, () => <String>{})
              .add(term);
        }
      }
    }
    if (translations.isEmpty) entries.remove(term);
  }

  final englishArabic = _writeDictionary(_englishArabicOutputPath, entries);
  final arabicEnglish = _writeDictionary(
    _arabicEnglishOutputPath,
    reverseEntries,
  );
  final licenseOutput = File(_licenseOutputPath)
    ..parent.createSync(recursive: true);
  File(_licenseSourcePath).copySync(licenseOutput.path);

  stdout.writeln('English → Arabic records: ${entries.length}');
  stdout.writeln('English → Arabic compressed bytes: ${englishArabic.length}');
  stdout.writeln('Arabic → English records: ${reverseEntries.length}');
  stdout.writeln('Arabic → English compressed bytes: ${arabicEnglish.length}');
  stdout.writeln('Licence: ${licenseOutput.path}');
}

List<int> _writeDictionary(String path, Map<String, Set<String>> entries) {
  final sorted = entries.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final records = <Uint8List>[];
  final offsets = <int>[0];
  var dataLength = 0;

  for (final entry in sorted) {
    final key = utf8.encode(entry.key);
    final value = utf8.encode(jsonEncode(entry.value.toList(growable: false)));
    final record = Uint8List(key.length + 1 + value.length)
      ..setRange(0, key.length, key)
      ..[key.length] = 0
      ..setRange(key.length + 1, key.length + 1 + value.length, value);
    records.add(record);
    dataLength += record.length;
    offsets.add(dataLength);
  }

  final headerLength = 12 + offsets.length * 4;
  final binary = Uint8List(headerLength + dataLength);
  binary.setRange(0, 4, ascii.encode(_magic));
  final view = ByteData.sublistView(binary);
  view.setUint32(4, _version, Endian.little);
  view.setUint32(8, sorted.length, Endian.little);
  for (var index = 0; index < offsets.length; index++) {
    view.setUint32(12 + index * 4, offsets[index], Endian.little);
  }

  var cursor = headerLength;
  for (final record in records) {
    binary.setRange(cursor, cursor + record.length, record);
    cursor += record.length;
  }

  final output = File(path)..parent.createSync(recursive: true);
  final compressed = GZipCodec(level: 9).encode(binary);
  output.writeAsBytesSync(compressed, flush: true);
  return compressed;
}

String _plainText(String xml) {
  final withoutTags = xml.replaceAll(RegExp(r'<[^>]+>'), '');
  return withoutTags
      .replaceAllMapped(RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'), (match) {
        final token = match.group(1)!;
        final radix = token.startsWith('x') ? 16 : 10;
        final digits = token.startsWith('x') ? token.substring(1) : token;
        final value = int.tryParse(digits, radix: radix);
        return value == null ? match.group(0)! : String.fromCharCode(value);
      })
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
