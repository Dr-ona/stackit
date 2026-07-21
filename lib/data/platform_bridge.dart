import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/capture_payload.dart';
import '../models/language_pair.dart';
import '../models/user_profile.dart';
import '../models/vocabulary_entry.dart';

class PlatformBridge {
  static const _channel = MethodChannel('app.stackit/capture');

  Future<void> Function(CapturePayload payload)? onSelectionReceived;
  List<VocabularyEntry> _memoryEntries = const [];
  String? _memoryLanguagePair;
  String? _memoryPreferredTargetLanguage;
  String? _memoryInterfaceLanguage;
  String? _memoryUserProfile;
  bool _memoryReviewReminders = false;

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

  Future<Map<String, Object?>?> loadLibrary() async {
    try {
      final raw = await _channel.invokeMethod<String>('loadLibrary');
      if (raw == null || raw.isEmpty) return null;
      return (jsonDecode(raw) as Map<Object?, Object?>).cast<String, Object?>();
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> saveLibrary(Map<String, Object?> data) async {
    final encoded = jsonEncode(data);
    try {
      await _channel.invokeMethod<void>('saveLibrary', encoded);
    } on MissingPluginException {
      // The in-memory fallback keeps widget tests and unsupported platforms usable.
    }
  }

  Future<LanguagePair?> loadLanguagePair() async {
    try {
      final id = await _channel.invokeMethod<String>('loadLanguagePair');
      return LanguagePair.tryParse(id);
    } on MissingPluginException {
      return LanguagePair.tryParse(_memoryLanguagePair);
    }
  }

  Future<void> saveLanguagePair(LanguagePair pair) async {
    _memoryLanguagePair = pair.id;
    try {
      await _channel.invokeMethod<void>('saveLanguagePair', pair.id);
    } on MissingPluginException {
      // The in-memory fallback keeps tests and unsupported platforms usable.
    }
  }

  Future<VocabularyLanguage?> loadPreferredTargetLanguage() async {
    try {
      final code = await _channel.invokeMethod<String>(
        'loadPreferredTargetLanguage',
      );
      return VocabularyLanguage.tryFromCode(code);
    } on MissingPluginException {
      return VocabularyLanguage.tryFromCode(_memoryPreferredTargetLanguage);
    }
  }

  Future<void> savePreferredTargetLanguage(VocabularyLanguage language) async {
    _memoryPreferredTargetLanguage = language.code;
    try {
      await _channel.invokeMethod<void>(
        'savePreferredTargetLanguage',
        language.code,
      );
    } on MissingPluginException {
      // The in-memory fallback keeps tests and unsupported platforms usable.
    }
  }

  Future<VocabularyLanguage?> loadInterfaceLanguage() async {
    try {
      final code = await _channel.invokeMethod<String>('loadInterfaceLanguage');
      return VocabularyLanguage.tryFromCode(code);
    } on MissingPluginException {
      return VocabularyLanguage.tryFromCode(_memoryInterfaceLanguage);
    }
  }

  Future<void> saveInterfaceLanguage(VocabularyLanguage? language) async {
    _memoryInterfaceLanguage = language?.code;
    try {
      await _channel.invokeMethod<void>(
        'saveInterfaceLanguage',
        language?.code,
      );
    } on MissingPluginException {
      // The in-memory fallback keeps tests and unsupported platforms usable.
    }
  }

  Future<bool> loadReviewReminders() async {
    try {
      return await _channel.invokeMethod<bool>('loadReviewReminders') ?? false;
    } on MissingPluginException {
      return _memoryReviewReminders;
    }
  }

  Future<void> saveReviewReminders(bool enabled) async {
    _memoryReviewReminders = enabled;
    try {
      await _channel.invokeMethod<void>('saveReviewReminders', enabled);
    } on MissingPluginException {
      // The in-memory fallback keeps tests and unsupported platforms usable.
    }
  }

  Future<UserProfile?> loadUserProfile({String? userId}) async {
    try {
      final raw = await _channel.invokeMethod<String>('loadUserProfile');
      return _decodeUserProfile(raw, userId: userId);
    } on MissingPluginException {
      return _decodeUserProfile(_memoryUserProfile, userId: userId);
    }
  }

  Future<void> saveUserProfile(UserProfile profile, {String? userId}) async {
    final encoded = jsonEncode({'userId': userId, 'profile': profile.toJson()});
    _memoryUserProfile = encoded;
    try {
      await _channel.invokeMethod<void>('saveUserProfile', encoded);
    } on MissingPluginException {
      // The in-memory fallback keeps tests and unsupported platforms usable.
    }
  }

  Future<void> clearUserProfile() async {
    _memoryUserProfile = null;
    try {
      await _channel.invokeMethod<void>('clearUserProfile');
    } on MissingPluginException {
      // The in-memory fallback keeps tests and unsupported platforms usable.
    }
  }

  Future<void> speak(
    String text,
    VocabularyLanguage language, {
    String? localeTag,
  }) async {
    try {
      await _channel.invokeMethod<void>('speak', {
        'text': text,
        'localeTag': localeTag ?? language.localeTag,
      });
    } on MissingPluginException {
      // Pronunciation is an optional platform capability.
    }
  }

  Future<CapturePayload?> readClipboard() async {
    try {
      final raw = await _channel.invokeMethod<Map>('readClipboard');
      if (raw == null) return null;
      final payload = CapturePayload.fromMap(raw.cast<Object?, Object?>());
      return payload.text.isEmpty ? null : payload;
    } on MissingPluginException {
      return null;
    }
  }

  CapturePayload? _payloadFrom(Object? value) {
    if (value is! Map) return null;
    final payload = CapturePayload.fromMap(value.cast<Object?, Object?>());
    return payload.text.isEmpty ? null : payload;
  }

  UserProfile? _decodeUserProfile(String? raw, {String? userId}) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, Object?>;
      final storedUserId = envelope['userId'] as String?;
      if (userId != null && storedUserId != userId) return null;
      final profile = envelope['profile'];
      if (profile is! Map<Object?, Object?>) return null;
      return UserProfile.fromJson(profile.cast<String, Object?>());
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
