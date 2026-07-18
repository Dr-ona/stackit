import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/dictionary_result.dart';
import '../models/language_pair.dart';
import '../models/vocabulary_sense.dart';
import 'dictionary_normalization.dart';

class OfflineDictionary {
  static const contentRevision = 7;
  static const _curatedPath = 'assets/dictionaries/en_ar.json';
  static const _binaryPaths = {
    'en_ar': 'assets/dictionaries/freedict_en_ar.stkdict.gz',
    'ar_en': 'assets/dictionaries/freedict_ar_en.stkdict.gz',
    'en_fr': 'assets/dictionaries/freedict_en_fr.stkdict.gz',
    'fr_en': 'assets/dictionaries/freedict_fr_en.stkdict.gz',
  };

  final Map<String, Map<String, DictionaryResult>> _curatedByPair = {};
  final Map<String, _BinaryDictionary> _binaryByPair = {};

  int get freeDictEntryCount =>
      _binaryByPair[LanguagePair.englishToArabic.id]?.recordCount ?? 0;

  int entryCountFor(LanguagePair pair) =>
      _binaryByPair[pair.id]?.recordCount ?? 0;

  Future<bool> recognizesSource(
    String selection,
    VocabularyLanguage source,
  ) async {
    for (final pair in LanguagePair.supported) {
      if (pair.source != source || !_binaryPaths.containsKey(pair.id)) continue;
      if (await lookup(selection, pair) != null) return true;
    }
    return false;
  }

  Future<void> load([LanguagePair pair = LanguagePair.englishToArabic]) async {
    await _loadCurated();
    if (_binaryByPair.containsKey(pair.id)) return;
    final path = _binaryPaths[pair.id];
    if (path == null) {
      throw UnsupportedError('Unsupported language pair: ${pair.id}');
    }
    final binaryData = await rootBundle.load(path);
    final compressed = Uint8List.sublistView(binaryData);
    final binary = Uint8List.fromList(gzip.decode(compressed));
    _binaryByPair[pair.id] = _BinaryDictionary(binary);
  }

  Future<DictionaryResult?> lookup(
    String selection, [
    LanguagePair pair = LanguagePair.englishToArabic,
  ]) async {
    await _loadCurated();
    final normalized = _normalize(selection, pair.source);
    if (normalized.isEmpty) return null;
    if (pair.source == pair.target) {
      return _sameLanguageResult(selection.trim(), normalized, pair);
    }
    if (!_binaryPaths.containsKey(pair.id)) return null;
    await load(pair);
    final candidates = <String>{
      normalized,
      if (pair.source == VocabularyLanguage.english)
        ...englishBaseFormCandidates(normalized),
    };

    final curated = _curatedByPair[pair.id] ?? const {};
    final exactCurated = curated[normalized];
    if (exactCurated != null) {
      return _withTranslations(exactCurated, exactCurated.translations);
    }
    final curatedTranslations = <String>{};
    DictionaryResult? curatedResult;
    for (final candidate in candidates.skip(1)) {
      final result = curated[candidate];
      if (result != null) {
        curatedResult ??= result;
        curatedTranslations.addAll(result.translations);
      }
    }
    if (curatedResult != null) {
      return _withTranslations(curatedResult, curatedTranslations);
    }

    final binary = _binaryByPair[pair.id]!;
    final exactBinary = binary.lookup(normalized);
    if (exactBinary != null) {
      return _binaryResult(exactBinary.$1, exactBinary.$2, pair);
    }
    final binaryGroups = <List<String>>[];
    String? matchedSource;
    for (final candidate in candidates.skip(1)) {
      final result = binary.lookup(candidate);
      if (result != null) {
        matchedSource ??= result.$1;
        binaryGroups.addAll(result.$2);
      }
    }
    if (matchedSource == null) return null;
    return _binaryResult(matchedSource, binaryGroups, pair);
  }

  DictionaryResult _sameLanguageResult(
    String sourceText,
    String normalized,
    LanguagePair pair,
  ) {
    DictionaryResult? curated;
    if (pair.source == VocabularyLanguage.english) {
      final forward =
          _curatedByPair[LanguagePair.englishToArabic.id] ?? const {};
      curated = forward[normalized];
      if (curated == null) {
        for (final candidate in englishBaseFormCandidates(normalized).skip(1)) {
          curated = forward[candidate];
          if (curated != null) break;
        }
      }
    }
    final senses = curated?.senses
        .map(
          (sense) => VocabularySense(
            id: sense.id,
            translations: [curated!.sourceText],
            definition: sense.definition,
            partOfSpeech: sense.partOfSpeech,
            examples: sense.examples,
          ),
        )
        .toList(growable: false);
    return DictionaryResult.withSenses(
      sourceText: sourceText,
      senses: senses == null || senses.isEmpty
          ? [
              VocabularySense(
                id: VocabularySense.legacyId,
                translations: [sourceText],
                definition:
                    'Same-language study entry. Use Find all meanings for definitions, synonyms, and examples.',
              ),
            ]
          : senses,
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
    );
  }

  DictionaryResult _binaryResult(
    String sourceText,
    List<List<String>> groups,
    LanguagePair pair,
  ) {
    final senses = <VocabularySense>[];
    final seen = <String>{};
    for (final group in groups) {
      final translations = group
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .take(16)
          .toList(growable: false);
      if (translations.isEmpty || !seen.add(translations.join('\u0001'))) {
        continue;
      }
      senses.add(
        VocabularySense(
          id: 'sense-${senses.length + 1}',
          translations: translations,
          definition:
              'Offline ${pair.source.label}–${pair.target.label} translation.',
        ),
      );
      if (senses.length == 8) break;
    }
    if (senses.isEmpty) {
      throw const FormatException('Dictionary record has no translations.');
    }
    return DictionaryResult.withSenses(
      sourceText: sourceText,
      senses: senses,
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
    );
  }

  DictionaryResult _withTranslations(
    DictionaryResult result,
    Iterable<String> translations,
  ) {
    return result.copyWithPrimaryTranslations(translations);
  }

  Future<void> _loadCurated() async {
    if (_curatedByPair.isNotEmpty) return;
    final raw = await rootBundle.loadString(_curatedPath);
    final decoded = jsonDecode(raw) as List<Object?>;
    final forward = <String, DictionaryResult>{};
    final reverse = <String, LinkedHashSet<String>>{};

    for (final item in decoded) {
      final json = (item! as Map<Object?, Object?>).cast<String, Object?>();
      final result = DictionaryResult.fromLegacyJson(json);
      forward[normalizeEnglishTerm(result.sourceText)] = result;
      for (final alias in (json['aliases'] as List<Object?>? ?? const [])) {
        if (alias case final String value) {
          final normalizedAlias = normalizeEnglishTerm(value);
          if (normalizedAlias.isNotEmpty) forward[normalizedAlias] = result;
        }
      }
      for (final translation in result.senses.expand(
        (sense) => sense.translations,
      )) {
        final key = normalizeArabicTerm(translation);
        if (key.isNotEmpty) {
          reverse
              .putIfAbsent(key, LinkedHashSet<String>.new)
              .add(result.sourceText);
        }
      }
    }

    _curatedByPair[LanguagePair.englishToArabic.id] = forward;
    _curatedByPair[LanguagePair.arabicToEnglish.id] = {
      for (final entry in reverse.entries)
        entry.key: DictionaryResult(
          sourceText: entry.key,
          translations: entry.value.toList(growable: false),
          sourceLanguage: VocabularyLanguage.arabic,
          targetLanguage: VocabularyLanguage.english,
          definition: 'Offline Arabic–English translation.',
        ),
    };
  }

  String _normalize(String value, VocabularyLanguage language) {
    return switch (language) {
      VocabularyLanguage.english => normalizeEnglishTerm(value),
      VocabularyLanguage.arabic => normalizeArabicTerm(value),
      VocabularyLanguage.french => normalizeFrenchTerm(value),
    };
  }
}

class _BinaryDictionary {
  _BinaryDictionary(this.binary) : view = ByteData.sublistView(binary) {
    if (binary.length < 16 || ascii.decode(binary.sublist(0, 4)) != 'STKD') {
      throw const FormatException('Invalid Stackit dictionary header.');
    }
    version = view.getUint32(4, Endian.little);
    if (version != 1 && version != 2 && version != 3) {
      throw FormatException('Unsupported Stackit dictionary version: $version');
    }
    recordCount = view.getUint32(8, Endian.little);
    dataStart = 12 + (recordCount + 1) * 4;
    if (dataStart > binary.length) {
      throw const FormatException('Truncated Stackit dictionary index.');
    }
  }

  final Uint8List binary;
  final ByteData view;
  late final int version;
  late final int recordCount;
  late final int dataStart;

  (String, List<List<String>>)? lookup(String target) {
    var low = 0;
    var high = recordCount - 1;
    while (low <= high) {
      final middle = low + ((high - low) >> 1);
      final bounds = _recordBounds(middle);
      final separator = _findSeparator(bounds.$1, bounds.$2);
      final key = utf8.decode(binary.sublist(bounds.$1, separator));
      final comparison = key.compareTo(target);
      if (comparison == 0) {
        final encoded = utf8.decode(binary.sublist(separator + 1, bounds.$2));
        final groups = switch (version) {
          3 =>
            (jsonDecode(encoded) as List<Object?>)
                .whereType<List<Object?>>()
                .map(
                  (group) => group.whereType<String>().toList(growable: false),
                )
                .where((group) => group.isNotEmpty)
                .toList(growable: false),
          2 => [
            (jsonDecode(encoded) as List<Object?>).whereType<String>().toList(
              growable: false,
            ),
          ],
          _ => [splitLegacyTranslations(encoded)],
        };
        return (key, groups);
      }
      if (comparison < 0) {
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return null;
  }

  (int, int) _recordBounds(int index) {
    final start = view.getUint32(12 + index * 4, Endian.little);
    final end = view.getUint32(12 + (index + 1) * 4, Endian.little);
    return (dataStart + start, dataStart + end);
  }

  int _findSeparator(int start, int end) {
    for (var cursor = start; cursor < end; cursor++) {
      if (binary[cursor] == 0) return cursor;
    }
    throw const FormatException('Invalid Stackit dictionary record.');
  }
}
