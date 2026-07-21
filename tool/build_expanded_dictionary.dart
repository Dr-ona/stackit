import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stackit/data/dictionary_normalization.dart';

/// Builds expanded offline dictionaries by merging:
/// 1. FreeDict TEI sources (existing)
/// 2. Wiktionary JSONL via Wiktextract (new)
/// 3. PanLex bilingual pairs (new)
///
/// Usage:
///   dart run tool/build_expanded_dictionary.dart [--download] [--skip-wiktionary] [--skip-panlex]
///
/// Downloaded data is cached in third_party/wiktionary/ and third_party/panlex/.
const _magic = 'STKD';
const _version = 3;

const _wiktionaryEnUrl =
    'https://kaikki.org/dictionary/raw-wiktextract-data.jsonl.gz';
const _wiktionaryFrUrl =
    'https://kaikki.org/dictionary/downloads/fr/fr-extract.jsonl.gz';
const _wiktionaryEnPath = 'third_party/wiktionary/en-extract.jsonl.gz';
const _wiktionaryFrPath = 'third_party/wiktionary/fr-extract.jsonl.gz';

const _freedictEnArPath =
    'third_party/freedict/eng-ara-0.6.3/eng-ara/eng-ara.tei';
const _freedictEnFrPath =
    'third_party/freedict/eng-fra-0.1.6/eng-fra/eng-fra.tei';
const _freedictFrEnPath =
    'third_party/freedict/fra-eng-0.4.1/fra-eng/fra-eng.tei';

const _outputEnAr = 'assets/dictionaries/freedict_en_ar.stkdict.gz';
const _outputArEn = 'assets/dictionaries/freedict_ar_en.stkdict.gz';
const _outputEnFr = 'assets/dictionaries/freedict_en_fr.stkdict.gz';
const _outputFrEn = 'assets/dictionaries/freedict_fr_en.stkdict.gz';

bool _download = false;
bool _skipWiktionary = false;
bool _skipPanlex = false;
String? _pairsDir;

void main(List<String> args) async {
  _download = args.contains('--download');
  _skipWiktionary = args.contains('--skip-wiktionary');
  _skipPanlex = args.contains('--skip-panlex');
  final pairsIdx = args.indexOf('--pairs-dir');
  _pairsDir = pairsIdx >= 0 ? args[pairsIdx + 1] : null;

  stdout.writeln('=== Expanded Dictionary Builder ===');
  stdout.writeln(
    'Flags: download=$_download, skipWiktionary=$_skipWiktionary, '
    'skipPanlex=$_skipPanlex, pairsDir=$_pairsDir',
  );

  if (_download) {
    _downloadData();
  }

  // Phase 1: Load FreeDict
  stdout.writeln('\n--- Phase 1: FreeDict ---');
  final enArFree = _readFreeDictTei(_freedictEnArPath, normalizeEnglishTerm);
  final arEnFree = _buildReverse(enArFree, normalizeArabicTerm);
  final enFrFree = _readFreeDictTei(_freedictEnFrPath, normalizeEnglishTerm);
  final frEnFree = _readFreeDictTei(_freedictFrEnPath, normalizeFrenchTerm);
  stdout.writeln('FreeDict EN→AR: ${enArFree.length} entries');
  stdout.writeln('FreeDict AR→EN: ${arEnFree.length} entries');
  stdout.writeln('FreeDict EN→FR: ${enFrFree.length} entries');
  stdout.writeln('FreeDict FR→EN: ${frEnFree.length} entries');

  // Phase 2: Merge Wiktionary
  final enAr = Map<String, List<List<String>>>.from(enArFree);
  final arEn = Map<String, List<List<String>>>.from(arEnFree);
  final enFr = Map<String, List<List<String>>>.from(enFrFree);
  final frEn = Map<String, List<List<String>>>.from(frEnFree);
  final arFr = <String, List<List<String>>>{};
  final frAr = <String, List<List<String>>>{};

  if (!_skipWiktionary || _pairsDir != null) {
    stdout.writeln('\n--- Phase 2: Wiktionary ---');
    if (_pairsDir != null) {
      _mergePairsDir(_pairsDir!, enAr, arEn, enFr, frEn, arFr, frAr);
    } else if (!_skipWiktionary) {
      await _mergeWiktionaryEn(_wiktionaryEnPath, enAr, arEn, enFr, arFr);
      await _mergeWiktionaryFr(_wiktionaryFrPath, frEn, frAr);
    }
  }

  // Phase 3: Merge PanLex (placeholder for now)
  if (!_skipPanlex) {
    stdout.writeln('\n--- Phase 3: PanLex ---');
    stdout.writeln('PanLex integration: pending data download setup');
  }

  // Phase 4: Build output
  stdout.writeln('\n--- Phase 4: Building dictionaries ---');
  final enArBytes = _writeDictionary(_outputEnAr, enAr);
  final arEnBytes = _writeDictionary(_outputArEn, arEn);
  final enFrBytes = _writeDictionary(_outputEnFr, enFr);
  final frEnBytes = _writeDictionary(_outputFrEn, frEn);

  stdout.writeln('\n=== Results ===');
  stdout.writeln('EN→AR: ${enAr.length} entries (${enArBytes.length} bytes)');
  stdout.writeln('AR→EN: ${arEn.length} entries (${arEnBytes.length} bytes)');
  stdout.writeln('EN→FR: ${enFr.length} entries (${enFrBytes.length} bytes)');
  stdout.writeln('FR→EN: ${frEn.length} entries (${frEnBytes.length} bytes)');
  if (arFr.isNotEmpty) {
    stdout.writeln('AR→FR: ${arFr.length} entries (pivot, not persisted)');
  }
  if (frAr.isNotEmpty) {
    stdout.writeln('FR→AR: ${frAr.length} entries (pivot, not persisted)');
  }

  // Compare with FreeDict-only
  stdout.writeln('\n=== Improvement over FreeDict alone ===');
  stdout.writeln(
    'EN→AR: ${enArFree.length} → ${enAr.length} '
    '(+${enAr.length - enArFree.length})',
  );
  stdout.writeln(
    'AR→EN: ${arEnFree.length} → ${arEn.length} '
    '(+${arEn.length - arEnFree.length})',
  );
  stdout.writeln(
    'EN→FR: ${enFrFree.length} → ${enFr.length} '
    '(+${enFr.length - enFrFree.length})',
  );
  stdout.writeln(
    'FR→EN: ${frEnFree.length} → ${frEn.length} '
    '(+${frEn.length - frEnFree.length})',
  );
}

void _downloadData() {
  stdout.writeln('\n--- Downloading data ---');
  Directory('third_party/wiktionary').createSync(recursive: true);

  _downloadFile(_wiktionaryEnUrl, _wiktionaryEnPath);
  _downloadFile(_wiktionaryFrUrl, _wiktionaryFrPath);
}

void _downloadFile(String url, String path) {
  if (File(path).existsSync()) {
    stdout.writeln('  Already exists: $path');
    return;
  }
  stdout.writeln('  Downloading: $url');
  stdout.writeln('  To: $path');
  final curlCmd = Platform.isWindows ? 'curl.exe' : 'curl';
  final result = Process.runSync(curlCmd, ['-L', '-o', path, url]);
  if (result.exitCode != 0) {
    stderr.writeln('  FAILED to download $url');
    stderr.writeln('  ${result.stderr}');
  } else {
    stdout.writeln('  Done: ${File(path).lengthSync()} bytes');
  }
}

// ---------------------------------------------------------------------------
// FreeDict TEI reader (reused from existing build tool)
// ---------------------------------------------------------------------------

Map<String, List<List<String>>> _readFreeDictTei(
  String path,
  String Function(String) normalizeSource,
) {
  final source = File(path);
  if (!source.existsSync()) {
    stderr.writeln('Missing FreeDict source: $path');
    return {};
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

// ---------------------------------------------------------------------------
// Wiktionary JSONL merge
// ---------------------------------------------------------------------------

Future<void> _mergeWiktionaryEn(
  String path,
  Map<String, List<List<String>>> enAr,
  Map<String, List<List<String>>> arEn,
  Map<String, List<List<String>>> enFr,
  Map<String, List<List<String>>> arFr,
) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('  Skipping Wiktionary EN: file not found at $path');
    return;
  }
  stdout.writeln('  Processing $path ...');
  var lineCount = 0;
  var enArAdded = 0;
  var arEnAdded = 0;
  var enFrAdded = 0;
  var arFrAdded = 0;

  final inputStream = file.openRead();
  final gzStream = inputStream.transform(gzip.decoder);
  final lines = gzStream.transform(utf8.decoder).transform(
        const LineSplitter(),
      );

  await for (final line in lines) {
    if (line.isEmpty) continue;
    lineCount++;
    if (lineCount % 500000 == 0) {
      stdout.writeln(
        '    Processed $lineCount lines '
        '(EN→AR: $enArAdded, AR→EN: $arEnAdded, '
        'EN→FR: $enFrAdded, AR→FR: $arFrAdded)',
      );
    }

    // Fast pre-filter: skip lines that can't contain our target languages.
    // We need lines with lang_code en|ar|fr AND translations referencing ar|fr|en.
    final hasAr = line.contains('"ar"');
    final hasFr = line.contains('"fr"');
    final hasEn = line.contains('"en"');
    // Lines must have lang_code en, ar, or fr (all contain quotes around code)
    // AND have at least one cross-language translation target.
    final hasLang = line.contains('"lang_code"');
    if (!hasLang) continue;
    // Quick heuristic: must have "translations" key AND at least one target
    if (!line.contains('"translations"')) continue;
    // Must have at least one relevant cross-pair
    if (!(hasAr || hasFr)) continue;

    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }

    final langCode = obj['lang_code'] as String?;
    if (langCode == null) continue;
    final word = obj['word'] as String?;
    if (word == null || word.isEmpty) continue;

    final translations = obj['translations'] as List?;
    if (translations == null || translations.isEmpty) continue;

    // Process English entries → extract AR and FR translations
    if (langCode == 'en') {
      final normalizedEn = normalizeEnglishTerm(word);
      if (normalizedEn.isEmpty) continue;

      for (final t in translations) {
        if (t is! Map) continue;
        final tCode = t['lang_code'] as String? ?? t['code'] as String?;
        final tWord = t['word'] as String?;
        if (tCode == null || tWord == null || tWord.isEmpty) continue;

        if (tCode == 'ar') {
          final normalizedAr = normalizeArabicTerm(tWord);
          if (normalizedAr.isEmpty) continue;
          _addToMap(enAr, normalizedEn, [normalizedAr]);
          _addToMap(arEn, normalizedAr, [normalizedEn]);
          enArAdded++;
          arEnAdded++;
        } else if (tCode == 'fr') {
          final normalizedFr = normalizeFrenchTerm(tWord);
          if (normalizedFr.isEmpty) continue;
          _addToMap(enFr, normalizedEn, [normalizedFr]);
          enFrAdded++;
        }
      }
    }

    // Process Arabic entries → extract EN translations and FR for AR→FR pivot
    if (langCode == 'ar') {
      final normalizedAr = normalizeArabicTerm(word);
      if (normalizedAr.isEmpty) continue;

      for (final t in translations) {
        if (t is! Map) continue;
        final tCode = t['lang_code'] as String? ?? t['code'] as String?;
        final tWord = t['word'] as String?;
        if (tCode == null || tWord == null || tWord.isEmpty) continue;

        if (tCode == 'en') {
          final normalizedEn = normalizeEnglishTerm(tWord);
          if (normalizedEn.isEmpty) continue;
          _addToMap(arEn, normalizedAr, [normalizedEn]);
          arEnAdded++;
        } else if (tCode == 'fr') {
          final normalizedFr = normalizeFrenchTerm(tWord);
          if (normalizedFr.isEmpty) continue;
          _addToMap(arFr, normalizedAr, [normalizedFr]);
          arFrAdded++;
        }
      }
    }
  }

  stdout.writeln('  Done: $lineCount lines processed');
  stdout.writeln(
    '  Added: EN→AR=$enArAdded, AR→EN=$arEnAdded, '
    'EN→FR=$enFrAdded, AR→FR=$arFrAdded',
  );
}

Future<void> _mergeWiktionaryFr(
  String path,
  Map<String, List<List<String>>> frEn,
  Map<String, List<List<String>>> frAr,
) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('  Skipping Wiktionary FR: file not found at $path');
    return;
  }
  stdout.writeln('  Processing $path ...');
  var lineCount = 0;
  var frEnAdded = 0;
  var frArAdded = 0;

  final inputStream = file.openRead();
  final gzStream = inputStream.transform(gzip.decoder);
  final lines = gzStream.transform(utf8.decoder).transform(
        const LineSplitter(),
      );

  await for (final line in lines) {
    if (line.isEmpty) continue;
    lineCount++;
    if (lineCount % 500000 == 0) {
      stdout.writeln(
        '    Processed $lineCount lines '
        '(FR→EN: $frEnAdded, FR→AR: $frArAdded)',
      );
    }

    // Fast pre-filter: only process FR entries with EN or AR translations
    if (!line.contains('"lang_code":"fr"')) continue;
    if (!line.contains('"translations"')) continue;

    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }

    final langCode = obj['lang_code'] as String?;
    if (langCode != 'fr') continue;
    final word = obj['word'] as String?;
    if (word == null || word.isEmpty) continue;
    final normalizedFr = normalizeFrenchTerm(word);
    if (normalizedFr.isEmpty) continue;

    final translations = obj['translations'] as List?;
    if (translations == null || translations.isEmpty) continue;

    for (final t in translations) {
      if (t is! Map) continue;
      final tCode = t['lang_code'] as String? ?? t['code'] as String?;
      final tWord = t['word'] as String?;
      if (tCode == null || tWord == null || tWord.isEmpty) continue;

      if (tCode == 'en') {
        final normalizedEn = normalizeEnglishTerm(tWord);
        if (normalizedEn.isEmpty) continue;
        _addToMap(frEn, normalizedFr, [normalizedEn]);
        frEnAdded++;
      } else if (tCode == 'ar') {
        final normalizedAr = normalizeArabicTerm(tWord);
        if (normalizedAr.isEmpty) continue;
        _addToMap(frAr, normalizedFr, [normalizedAr]);
        frArAdded++;
      }
    }
  }

  stdout.writeln('  Done: $lineCount lines processed');
  stdout.writeln('  Added: FR→EN=$frEnAdded, FR→AR=$frArAdded');
}

// ---------------------------------------------------------------------------
// Merge from pre-extracted JSON pair files
// ---------------------------------------------------------------------------

void _mergePairsDir(
  String dir,
  Map<String, List<List<String>>> enAr,
  Map<String, List<List<String>>> arEn,
  Map<String, List<List<String>>> enFr,
  Map<String, List<List<String>>> frEn,
  Map<String, List<List<String>>> arFr,
  Map<String, List<List<String>>> frAr,
) {
  final enPairsPath = '$dir/en-wikt-pairs.json';
  final frPairsPath = '$dir/fr-wikt-pairs.json';

  if (File(enPairsPath).existsSync()) {
    stdout.writeln('  Loading EN Wiktionary pairs from $enPairsPath ...');
    final data = jsonDecode(File(enPairsPath).readAsStringSync())
        as Map<String, dynamic>;

    final enArPairs = data['en_ar'] as Map<String, dynamic>? ?? {};
    final arEnPairs = data['ar_en'] as Map<String, dynamic>? ?? {};
    final enFrPairs = data['en_fr'] as Map<String, dynamic>? ?? {};
    var added = 0;
    for (final entry in enArPairs.entries) {
      final normalized = normalizeEnglishTerm(entry.key);
      if (normalized.isEmpty) continue;
      final targets = (entry.value as List)
          .map((t) => normalizeArabicTerm(t.toString()))
          .where((t) => t.isNotEmpty)
          .toList();
      if (targets.isNotEmpty) {
        _addToMap(enAr, normalized, targets);
        added++;
      }
    }
    stdout.writeln('    EN→AR: +$added entries from Wiktionary');

    added = 0;
    for (final entry in arEnPairs.entries) {
      final normalized = normalizeArabicTerm(entry.key);
      if (normalized.isEmpty) continue;
      final targets = (entry.value as List)
          .map((t) => normalizeEnglishTerm(t.toString()))
          .where((t) => t.isNotEmpty)
          .toList();
      if (targets.isNotEmpty) {
        _addToMap(arEn, normalized, targets);
        added++;
      }
    }
    stdout.writeln('    AR→EN: +$added entries from Wiktionary');

    added = 0;
    for (final entry in enFrPairs.entries) {
      final normalized = normalizeEnglishTerm(entry.key);
      if (normalized.isEmpty) continue;
      final targets = (entry.value as List)
          .map((t) => normalizeFrenchTerm(t.toString()))
          .where((t) => t.isNotEmpty)
          .toList();
      if (targets.isNotEmpty) {
        _addToMap(enFr, normalized, targets);
        added++;
      }
    }
    stdout.writeln('    EN→FR: +$added entries from Wiktionary');
  } else {
    stdout.writeln('  EN pairs not found at $enPairsPath, skipping');
  }

  if (File(frPairsPath).existsSync()) {
    stdout.writeln('  Loading FR Wiktionary pairs from $frPairsPath ...');
    final data = jsonDecode(File(frPairsPath).readAsStringSync())
        as Map<String, dynamic>;

    final frEnPairs = data['fr_en'] as Map<String, dynamic>? ?? {};
    final frArPairs = data['fr_ar'] as Map<String, dynamic>? ?? {};
    var added = 0;
    for (final entry in frEnPairs.entries) {
      final normalized = normalizeFrenchTerm(entry.key);
      if (normalized.isEmpty) continue;
      final targets = (entry.value as List)
          .map((t) => normalizeEnglishTerm(t.toString()))
          .where((t) => t.isNotEmpty)
          .toList();
      if (targets.isNotEmpty) {
        _addToMap(frEn, normalized, targets);
        added++;
      }
    }
    stdout.writeln('    FR→EN: +$added entries from Wiktionary');

    added = 0;
    for (final entry in frArPairs.entries) {
      final normalized = normalizeFrenchTerm(entry.key);
      if (normalized.isEmpty) continue;
      final targets = (entry.value as List)
          .map((t) => normalizeArabicTerm(t.toString()))
          .where((t) => t.isNotEmpty)
          .toList();
      if (targets.isNotEmpty) {
        _addToMap(frAr, normalized, targets);
        added++;
      }
    }
    stdout.writeln('    FR→AR: +$added entries from Wiktionary');
  } else {
    stdout.writeln('  FR pairs not found at $frPairsPath, skipping');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, List<List<String>>> _buildReverse(
  Map<String, List<List<String>>> forward,
  String Function(String) normalizeTarget,
) {
  final reverse = <String, List<List<String>>>{};
  for (final entry in forward.entries) {
    for (final group in entry.value) {
      for (final translation in group) {
        final normalized = normalizeTarget(translation);
        if (normalized.isNotEmpty) {
          _addToMap(reverse, normalized, [entry.key]);
        }
      }
    }
  }
  return reverse;
}

void _addToMap(
  Map<String, List<List<String>>> map,
  String key,
  List<String> group,
) {
  final existing = map[key];
  if (existing == null) {
    map[key] = [group];
  } else {
    _addUniqueGroup(existing, group);
  }
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

// ---------------------------------------------------------------------------
// Binary dictionary writer (same format as existing build tool)
// ---------------------------------------------------------------------------

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
