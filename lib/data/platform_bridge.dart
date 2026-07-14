import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/capture_payload.dart';
import '../models/vocabulary_entry.dart';

class PlatformBridge {
  static const _channel = MethodChannel('app.stackit/capture');

  Future<void> Function(CapturePayload payload)? onSelectionReceived;
  List<VocabularyEntry> _memoryEntries = const [];

  PlatformBridge() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'selectionReceived') return;
      final payload = _payloadFrom(call.arguments);
      if (payload != null) await onSelectionReceived?.call(payload);
    });
  }

  Future<CapturePayload?> takeInitialSelection() async {
    try {
      return _payloadFrom(
        await _channel.invokeMethod<Object?>('takeInitialSelection'),
      );
    } on MissingPluginException {
      return null;
    }
  }

  Future<List<VocabularyEntry>> loadEntries() async {
    try {
      final raw = await _channel.invokeMethod<String>('loadEntries');
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<Object?>;
      return decoded
          .map(
            (item) => VocabularyEntry.fromJson(
              (item! as Map<Object?, Object?>).cast<String, Object?>(),
            ),
          )
          .toList();
    } on MissingPluginException {
      return _memoryEntries;
    }
  }

  Future<void> saveEntries(List<VocabularyEntry> entries) async {
    _memoryEntries = List.unmodifiable(entries);
    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    try {
      await _channel.invokeMethod<void>('saveEntries', encoded);
    } on MissingPluginException {
      // The in-memory fallback keeps widget tests and unsupported platforms usable.
    }
  }

  Future<void> speak(String text) async {
    try {
      await _channel.invokeMethod<void>('speak', text);
    } on MissingPluginException {
      // Pronunciation is an optional platform capability.
    }
  }

  CapturePayload? _payloadFrom(Object? value) {
    if (value is! Map) return null;
    final payload = CapturePayload.fromMap(value.cast<Object?, Object?>());
    return payload.text.isEmpty ? null : payload;
  }
}
