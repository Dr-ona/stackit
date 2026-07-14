import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/dictionary_result.dart';
import 'dictionary_normalization.dart';

class OfflineDictionary {
  static const _binaryPath = 'assets/dictionaries/freedict_en_ar.stkdict.gz';
  static const _curatedPath = 'assets/dictionaries/en_ar.json';

  Map<String, DictionaryResult>? _curatedEntries;
  Uint8List? _binary;
  ByteData? _view;
  int _recordCount = 0;
  int _dataStart = 0;

  int get freeDictEntryCount => _recordCount;

  Future<void> load() async {
    if (_curatedEntries != null) return;
    final curatedRaw = await rootBundle.loadString(_curatedPath);
    final binaryData = await rootBundle.load(_binaryPath);

    final decoded = jsonDecode(curatedRaw) as List<Object?>;
    final curated = <String, DictionaryResult>{};
    for (final item in decoded) {
      final json = (item! as Map<Object?, Object?>).cast<String, Object?>();
      curated[normalizeEnglishTerm(json['term']! as String)] =
          DictionaryResult.fromJson(json);
    }

    final compressed = Uint8List.sublistView(binaryData);
    final binary = Uint8List.fromList(gzip.decode(compressed));
    _validateAndIndex(binary);
    _curatedEntries = curated;
  }

  Future<DictionaryResult?> lookup(String selection) async {
    await load();
    final normalized = normalizeEnglishTerm(selection);
    final candidates = <String>[
      normalized,
      ...englishBaseFormCandidates(normalized),
    ];

    for (final candidate in candidates) {
      final curated = _curatedEntries![candidate];
      if (curated != null) return curated;
    }
    for (final candidate in candidates) {
      final freeDict = _lookupBinary(candidate);
      if (freeDict != null) {
        return DictionaryResult(
          term: freeDict.$1,
          arabic: freeDict.$2,
          definition: 'Offline English–Arabic translation.',
        );
      }
    }
    return null;
  }

  void _validateAndIndex(Uint8List binary) {
    if (binary.length < 16 || ascii.decode(binary.sublist(0, 4)) != 'STKD') {
      throw const FormatException('Invalid Stackit dictionary header.');
    }
    final view = ByteData.sublistView(binary);
    final version = view.getUint32(4, Endian.little);
    if (version != 1) {
      throw FormatException('Unsupported Stackit dictionary version: $version');
    }
    final count = view.getUint32(8, Endian.little);
    final dataStart = 12 + (count + 1) * 4;
    if (dataStart > binary.length) {
      throw const FormatException('Truncated Stackit dictionary index.');
    }
    _binary = binary;
    _view = view;
    _recordCount = count;
    _dataStart = dataStart;
  }

  (String, String)? _lookupBinary(String target) {
    var low = 0;
    var high = _recordCount - 1;
    while (low <= high) {
      final middle = low + ((high - low) >> 1);
      final bounds = _recordBounds(middle);
      final separator = _findSeparator(bounds.$1, bounds.$2);
      final key = utf8.decode(_binary!.sublist(bounds.$1, separator));
      final comparison = key.compareTo(target);
      if (comparison == 0) {
        final value = utf8.decode(_binary!.sublist(separator + 1, bounds.$2));
        return (key, value);
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
    final start = _view!.getUint32(12 + index * 4, Endian.little);
    final end = _view!.getUint32(12 + (index + 1) * 4, Endian.little);
    return (_dataStart + start, _dataStart + end);
  }

  int _findSeparator(int start, int end) {
    for (var cursor = start; cursor < end; cursor++) {
      if (_binary![cursor] == 0) return cursor;
    }
    throw const FormatException('Invalid Stackit dictionary record.');
  }
}
