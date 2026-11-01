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
const _englishFrenchSourcePath =
    'third_party/freedict/eng-fra-0.1.6/eng-fra/eng-fra.tei';
const _frenchEnglishSourcePath =
    'third_party/freedict/fra-eng-0.4.1/fra-eng/fra-eng.tei';
const _englishFrenchOutputPath =
    'assets/dictionaries/freedict_en_fr.stkdict.gz';
const _frenchEnglishOutputPath =
    'assets/dictionaries/freedict_fr_en.stkdict.gz';
const _englishFrenchLicenseSourcePath =
    'third_party/freedict/eng-fra-0.1.6/eng-fra/COPYING';
const _frenchEnglishLicenseSourcePath =
    'third_party/freedict/fra-eng-0.4.1/fra-eng/COPYING';
const _magic = 'STKD';
const _version = 3;

void main() {
  final source = File(_sourcePath);
  if (!source.existsSync()) {
    stderr.writeln('Missing FreeDict source: $_sourcePath');
    exitCode = 2;
    return;
  }

  final xml = source.readAsStringSync();
  final entries = <String, List<List<String>>>{};
  final reverseEntries = <String, List<List<String>>>{};
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

    final senseGroups = _extractSenseGroups(block, quotePattern);
    final storedGroups = entries.putIfAbsent(term, () => <List<String>>[]);
    for (final group in senseGroups) {
      _addUniqueGroup(storedGroups, group);
      for (final translation in group) {
        final normalizedArabic = normalizeArabicTerm(translation);
        if (normalizedArabic.isNotEmpty) {
          _addUniqueGroup(
            reverseEntries.putIfAbsent(
              normalizedArabic,
              () => <List<String>>[],
            ),
            [term],
          );
        }
      }
    }
    if (storedGroups.isEmpty) entries.remove(term);
  }

  final englishArabic = _writeDictionary(_englishArabicOutputPath, entries);
  final arabicEnglish = _writeDictionary(
    _arabicEnglishOutputPath,
    reverseEntries,
  );
  final licenseOutput = File(_licenseOutputPath)
    ..parent.createSync(recursive: true);
  File(_licenseSourcePath).copySync(licenseOutput.path);

  final englishFrenchEntries = _readTeiEntries(
    _englishFrenchSourcePath,
    normalizeEnglishTerm,
  );
  final frenchEnglishEntries = _readTeiEntries(
    _frenchEnglishSourcePath,
    normalizeFrenchTerm,
  );
  final englishFrench = _writeDictionary(
    _englishFrenchOutputPath,
    englishFrenchEntries,
  );
  final frenchEnglish = _writeDictionary(
    _frenchEnglishOutputPath,
    frenchEnglishEntries,
  );
  File(
    _englishFrenchLicenseSourcePath,
  ).copySync('assets/licenses/freedict-eng-fra-COPYING.txt');
  File(
    _frenchEnglishLicenseSourcePath,
  ).copySync('assets/licenses/freedict-fra-eng-COPYING.txt');

  stdout.writeln('English → Arabic records: ${entries.length}');
  stdout.writeln('English → Arabic compressed bytes: ${englishArabic.length}');
  stdout.writeln('Arabic → English records: ${reverseEntries.length}');
  stdout.writeln('Arabic → English compressed bytes: ${arabicEnglish.length}');
  stdout.writeln('Licence: ${licenseOutput.path}');
  stdout.writeln('English → French records: ${englishFrenchEntries.length}');
  stdout.writeln('English → French compressed bytes: ${englishFrench.length}');
  stdout.writeln('French → English records: ${frenchEnglishEntries.length}');
  stdout.writeln('French → English compressed bytes: ${frenchEnglish.length}');
}

Map<String, List<List<String>>> _readTeiEntries(
  String path,
  String Function(String) normalizeSource,
) {
  final source = File(path);
  if (!source.existsSync()) {
    throw StateError('Missing FreeDict source: $path');
  }
  final xml = source.readAsStringSync();
  final entries = <String, List<List<String>>>{};
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
    final term = normalizeSource(_plainText(orthMatch.group(1)!));
    if (term.isEmpty) continue;
    final groups = entries.putIfAbsent(term, () => <List<String>>[]);
    for (final group in _extractSenseGroups(block, quotePattern)) {
      _addUniqueGroup(groups, group);
    }
    if (groups.isEmpty) entries.remove(term);
  }
  return entries;
}

List<int> _writeDictionary(
  String path,
  Map<String, List<List<String>>> entries,
) {
  final sorted = entries.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final records = <Uint8List>[];
  final offsets = <int>[0];
  var dataLength = 0;

  for (final entry in sorted) {
    final key = utf8.encode(entry.key);
    final value = utf8.encode(jsonEncode(entry.value));
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

List<List<String>> _extractSenseGroups(String block, RegExp quotePattern) {
  final sensePattern = RegExp(
    r'<sense(?:\s[^>]*)?>(.*?)</sense>',
    dotAll: true,
  );
  final senseBlocks = sensePattern
      .allMatches(block)
      .map((match) => match.group(1)!)
      .toList(growable: false);
  final sourceBlocks = senseBlocks.isEmpty ? [block] : senseBlocks;
  final groups = <List<String>>[];
  for (final sourceBlock in sourceBlocks) {
    final translations = quotePattern
        .allMatches(sourceBlock)
        .map((quote) => _plainText(quote.group(1)!))
        .where((translation) => translation.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (translations.isNotEmpty) _addUniqueGroup(groups, translations);
  }
  return groups;
}

void _addUniqueGroup(List<List<String>> groups, List<String> candidate) {
  final signature = candidate.join('\u0001');
  if (groups.any((group) => group.join('\u0001') == signature)) return;
  groups.add(candidate);
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
