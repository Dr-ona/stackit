import 'dart:convert';

abstract class SenseErrorStore {
  Future<Map<String, int>> loadErrorCounts();
  Future<void> recordError(String senseId);
  Future<void> clearErrors(String senseId);
  Future<void> clearAll();
}

class LocalSenseErrorStore implements SenseErrorStore {
  LocalSenseErrorStore({required this._saveLoad});

  final SaveLoadFunction _saveLoad;

  Map<String, int> _counts = {};

  @override
  Future<Map<String, int>> loadErrorCounts() async {
    final raw = await _saveLoad.load();
    if (raw == null || raw.isEmpty) {
      _counts = {};
      return _counts;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      _counts = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      _counts = {};
    }
    return _counts;
  }

  @override
  Future<void> recordError(String senseId) async {
    _counts[senseId] = (_counts[senseId] ?? 0) + 1;
    await _save();
  }

  @override
  Future<void> clearErrors(String senseId) async {
    _counts.remove(senseId);
    await _save();
  }

  @override
  Future<void> clearAll() async {
    _counts = {};
    await _save();
  }

  Future<void> _save() async {
    await _saveLoad.save(jsonEncode(_counts));
  }
}

class SaveLoadFunction {
  const SaveLoadFunction({required this.load, required this.save});

  final Future<String?> Function() load;
  final Future<void> Function(String data) save;
}
