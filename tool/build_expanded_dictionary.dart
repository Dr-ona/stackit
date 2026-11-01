import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stackit/data/dictionary_normalization.dart';
import 'package:stackit/models/language_pair.dart';

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
const _freedictEnHiPath = 'third_party/freedict/eng-hin/eng-hin.tei';

const _outputEnAr = 'assets/dictionaries/freedict_en_ar.stkdict.gz';
const _outputArEn = 'assets/dictionaries/freedict_ar_en.stkdict.gz';
const _outputEnFr = 'assets/dictionaries/freedict_en_fr.stkdict.gz';
const _outputFrEn = 'assets/dictionaries/freedict_fr_en.stkdict.gz';
const _outputEnHi = 'assets/dictionaries/freedict_en_hi.stkdict.gz';
const _outputHiEn = 'assets/dictionaries/freedict_hi_en.stkdict.gz';
const _outputEnUr = 'assets/dictionaries/ai_en_ur.stkdict.gz';
const _outputUrEn = 'assets/dictionaries/ai_ur_en.stkdict.gz';
const _outputEnFa = 'assets/dictionaries/ai_en_fa.stkdict.gz';
const _outputFaEn = 'assets/dictionaries/ai_fa_en.stkdict.gz';

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
  final enHiFree = _readFreeDictTei(_freedictEnHiPath, normalizeEnglishTerm);
  stdout.writeln('FreeDict EN→AR: ${enArFree.length} entries');
  stdout.writeln('FreeDict AR→EN: ${arEnFree.length} entries');
  stdout.writeln('FreeDict EN→FR: ${enFrFree.length} entries');
  stdout.writeln('FreeDict FR→EN: ${frEnFree.length} entries');
  stdout.writeln('FreeDict EN→HI: ${enHiFree.length} entries');

  // Phase 2: Merge Wiktionary
  final enAr = Map<String, List<List<String>>>.from(enArFree);
  final arEn = Map<String, List<List<String>>>.from(arEnFree);
  final enFr = Map<String, List<List<String>>>.from(enFrFree);
  final frEn = Map<String, List<List<String>>>.from(frEnFree);
  final enHi = Map<String, List<List<String>>>.from(enHiFree);
  final hiEn = _buildReverse(enHiFree, normalizeHindiTerm);
  final enUr = <String, List<List<String>>>{};
  final urEn = <String, List<List<String>>>{};
  final enFa = <String, List<List<String>>>{};
  final faEn = <String, List<List<String>>>{};
  final arFr = <String, List<List<String>>>{};
  final frAr = <String, List<List<String>>>{};
  final urFa = <String, List<List<String>>>{};
  final faUr = <String, List<List<String>>>{};
  final hiUr = <String, List<List<String>>>{};
  final urHi = <String, List<List<String>>>{};
  final hiFa = <String, List<List<String>>>{};
  final faHi = <String, List<List<String>>>{};

  if (!_skipWiktionary || _pairsDir != null) {
    stdout.writeln('\n--- Phase 2: Wiktionary / AI pairs ---');
    if (_pairsDir != null) {
      _mergePairsDir(
        _pairsDir!,
        enAr,
        arEn,
        enFr,
        frEn,
        arFr,
        frAr,
        enHi,
        hiEn,
        enUr,
        urEn,
        enFa,
        faEn,
        urFa,
        faUr,
        hiUr,
        urHi,
        hiFa,
        faHi,
      );
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
  final enHiBytes = enHi.isNotEmpty
      ? _writeDictionary(_outputEnHi, enHi)
      : null;
  final hiEnBytes = hiEn.isNotEmpty
      ? _writeDictionary(_outputHiEn, hiEn)
      : null;
  final enUrBytes = enUr.isNotEmpty
      ? _writeDictionary(_outputEnUr, enUr)
      : null;
  final urEnBytes = urEn.isNotEmpty
      ? _writeDictionary(_outputUrEn, urEn)
      : null;
  final enFaBytes = enFa.isNotEmpty
      ? _writeDictionary(_outputEnFa, enFa)
      : null;
  final faEnBytes = faEn.isNotEmpty
      ? _writeDictionary(_outputFaEn, faEn)
      : null;

  stdout.writeln('\n=== Results ===');
  stdout.writeln('EN→AR: ${enAr.length} entries (${enArBytes.length} bytes)');
  stdout.writeln('AR→EN: ${arEn.length} entries (${arEnBytes.length} bytes)');
  stdout.writeln('EN→FR: ${enFr.length} entries (${enFrBytes.length} bytes)');
  stdout.writeln('FR→EN: ${frEn.length} entries (${frEnBytes.length} bytes)');
  if (enHiBytes != null) {
    stdout.writeln('EN→HI: ${enHi.length} entries (${enHiBytes.length} bytes)');
    stdout.writeln(
      'HI→EN: ${hiEn.length} entries (${hiEnBytes!.length} bytes)',
    );
  }
  if (enUrBytes != null) {
    stdout.writeln('EN→UR: ${enUr.length} entries (${enUrBytes.length} bytes)');
    stdout.writeln(
      'UR→EN: ${urEn.length} entries (${urEnBytes!.length} bytes)',
    );
  }
  if (enFaBytes != null) {
    stdout.writeln('EN→FA: ${enFa.length} entries (${enFaBytes.length} bytes)');
    stdout.writeln(
      'FA→EN: ${faEn.length} entries (${faEnBytes!.length} bytes)',
    );
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
  stdout.writeln(
    'EN→HI: ${enHiFree.length} → ${enHi.length} '
    '(+${enHi.length - enHiFree.length})',
  );
  if (enHi.isNotEmpty) {
    stdout.writeln('HI→EN: ${hiEn.length} entries');
  }
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
  final lines = gzStream
      .transform(utf8.decoder)
      .transform(const LineSplitter());

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
  final lines = gzStream
      .transform(utf8.decoder)
      .transform(const LineSplitter());

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

/// Language-pair normalizer lookup.
String Function(String) _normalizerFor(VocabularyLanguage lang) {
  return switch (lang) {
    VocabularyLanguage.english => normalizeEnglishTerm,
    VocabularyLanguage.arabic => normalizeArabicTerm,
    VocabularyLanguage.french => normalizeFrenchTerm,
    VocabularyLanguage.hindi => normalizeHindiTerm,
    VocabularyLanguage.urdu => normalizeUrduTerm,
    VocabularyLanguage.farsi => normalizeFarsiTerm,
  };
}

void _mergePairsDir(
  String dir,
  Map<String, List<List<String>>> enAr,
  Map<String, List<List<String>>> arEn,
  Map<String, List<List<String>>> enFr,
  Map<String, List<List<String>>> frEn,
  Map<String, List<List<String>>> arFr,
  Map<String, List<List<String>>> frAr,
  Map<String, List<List<String>>> enHi,
  Map<String, List<List<String>>> hiEn,
  Map<String, List<List<String>>> enUr,
  Map<String, List<List<String>>> urEn,
  Map<String, List<List<String>>> enFa,
  Map<String, List<List<String>>> faEn,
  Map<String, List<List<String>>> urFa,
  Map<String, List<List<String>>> faUr,
  Map<String, List<List<String>>> hiUr,
  Map<String, List<List<String>>> urHi,
  Map<String, List<List<String>>> hiFa,
  Map<String, List<List<String>>> faHi,
) {
  final allMaps = <String, Map<String, List<List<String>>>>{
    'en_ar': enAr,
    'ar_en': arEn,
    'en_fr': enFr,
    'fr_en': frEn,
    'ar_fr': arFr,
    'fr_ar': frAr,
    'en_hi': enHi,
    'hi_en': hiEn,
    'en_ur': enUr,
    'ur_en': urEn,
    'en_fa': enFa,
    'fa_en': faEn,
    'ur_fa': urFa,
    'fa_ur': faUr,
    'hi_ur': hiUr,
    'ur_hi': urHi,
    'hi_fa': hiFa,
    'fa_hi': faHi,
  };

  final dirPath = Directory(dir);
  if (!dirPath.existsSync()) {
    stdout.writeln('  Pairs directory not found: $dir, skipping');
    return;
  }

  for (final file in dirPath.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final basename = file.uri.pathSegments.last;
    final pairId = basename.replaceAll('.json', '');

    // Validate pair ID format: two lowercase letter codes separated by underscore
    final parts = pairId.split('_');
    if (parts.length != 2) {
      stdout.writeln('  Skipping $basename: expected xx_yy format');
      continue;
    }

    final targetMap = allMaps[pairId];
    if (targetMap == null) {
      stdout.writeln('  Skipping $basename: unknown pair ID $pairId');
      continue;
    }

    final sourceLang = _langFromCode(parts[0]);
    final targetLang = _langFromCode(parts[1]);
    if (sourceLang == null || targetLang == null) {
      stdout.writeln('  Skipping $basename: unknown language code');
      continue;
    }

    final normalizeSource = _normalizerFor(sourceLang);
    final normalizeTarget = _normalizerFor(targetLang);

    stdout.writeln('  Loading $basename ...');
    try {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      var added = 0;
      for (final entry in data.entries) {
        final normalizedKey = normalizeSource(entry.key);
        if (normalizedKey.isEmpty) continue;
        final targets = (entry.value as List)
            .map((t) => normalizeTarget(t.toString()))
            .where((t) => t.isNotEmpty)
            .toList();
        if (targets.isNotEmpty) {
          _addToMap(targetMap, normalizedKey, targets);
          added++;
        }
      }
      stdout.writeln('    $pairId: +$added entries from $basename');
    } catch (e) {
      stdout.writeln('    ERROR loading $basename: $e');
    }
  }
}

VocabularyLanguage? _langFromCode(String code) {
  return switch (code) {
    'en' => VocabularyLanguage.english,
    'ar' => VocabularyLanguage.arabic,
    'fr' => VocabularyLanguage.french,
    'hi' => VocabularyLanguage.hindi,
    'ur' => VocabularyLanguage.urdu,
    'fa' => VocabularyLanguage.farsi,
    _ => null,
  };
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
