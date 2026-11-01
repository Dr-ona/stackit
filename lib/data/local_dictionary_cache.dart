import 'dart:convert';
import 'dart:io';

import '../models/dictionary_result.dart';
import '../models/language_pair.dart';
import '../models/vocabulary_sense.dart';

/// A JSON-file-backed cache for Gemini-generated dictionary results.
///
/// Stores `DictionaryResult` objects keyed by `pairId + normalised term`
/// so that repeated lookups for the same word hit disk instead of the API.
class LocalDictionaryCache {
  LocalDictionaryCache({String? path})
    : _path = path ?? 'local_dictionary_cache.json';

  final String _path;
  Map<String, Map<String, Object?>> _data = {};
  bool _loaded = false;

  File get _file => File(_path);

  // ── Read ──────────────────────────────────────────────────────────────

  /// Returns the cached result for [text] in [pair], or `null`.
  Future<DictionaryResult?> lookup(String text, LanguagePair pair) async {
    await _ensureLoaded();
    final normalised = _normaliseKey(text);
    final bucket = _data[pair.id];
    if (bucket == null) return null;
    final raw = bucket[normalised];
    if (raw == null) return null;
    return _deserialise(raw as Map<String, Object?>, pair);
  }

  // ── Write ─────────────────────────────────────────────────────────────

  /// Persists [result] for future offline use.
  Future<void> store(DictionaryResult result, LanguagePair pair) async {
    await _ensureLoaded();
    final normalised = _normaliseKey(result.sourceText);
    final bucket = _data.putIfAbsent(pair.id, () => {});
    bucket[normalised] = _serialise(result);
    await _flush();
  }

  /// Bulk-store many results (used by the pre-cache service).
  Future<void> storeAll(
    List<DictionaryResult> results,
    LanguagePair pair,
  ) async {
    await _ensureLoaded();
    final bucket = _data.putIfAbsent(pair.id, () => {});
    for (final result in results) {
      final normalised = _normaliseKey(result.sourceText);
      bucket[normalised] = _serialise(result);
    }
    await _flush();
  }

  int get entryCount {
    var count = 0;
    for (final bucket in _data.values) {
      count += bucket.length;
    }
    return count;
  }

  // ── Internal ──────────────────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final file = _file;
    if (await file.exists()) {
      try {
        final content = await file.readAsString(encoding: utf8);
        final decoded = jsonDecode(content) as Map<String, Object?>;
        _data = decoded.map(
          (pairId, bucket) => MapEntry(
            pairId,
            (bucket as Map<String, Object?>).cast<String, Object?>(),
          ),
        );
      } catch (_) {
        _data = {};
      }
    }
    _loaded = true;
  }

  Future<void> _flush() async {
    final file = _file;
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(_data), encoding: utf8);
  }

  static String _normaliseKey(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static Map<String, Object?> _serialise(DictionaryResult result) => {
    'senses': result.senses.map((s) => s.toJson()).toList(growable: false),
    'sourceLanguage': result.sourceLanguage.code,
    'targetLanguage': result.targetLanguage.code,
  };

  static DictionaryResult? _deserialise(
    Map<String, Object?> json,
    LanguagePair pair,
  ) {
    final sensesRaw = json['senses'] as List<Object?>? ?? const [];
    final senses = sensesRaw
        .whereType<Map>()
        .map((s) => VocabularySense.fromJson(s.cast<String, Object?>()))
        .where((s) => s.translations.isNotEmpty && s.definition.isNotEmpty)
        .toList(growable: false);
    if (senses.isEmpty) return null;
    return DictionaryResult.withSenses(
      sourceText: '', // caller knows the term
      senses: senses,
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
    );
  }
}
