import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/features/vocabulary/capture_preview_sheet.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/dictionary_result.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/user_profile.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cold and resumed platform captures are both polled into the queue',
    () async {
      final bridge = _CaptureBridge()
        ..pending.add(const CapturePayload(text: 'meticulous'));
      final controller = VocabularyController(_Dictionary(), bridge);

      await controller.initialize();
      expect(controller.pendingCapture?.text, 'meticulous');
      expect(controller.takePendingCapture()?.text, 'meticulous');

      bridge.pending.add(const CapturePayload(text: 'resilient'));
      await controller.pollPlatformCapture();
      expect(controller.pendingCapture?.text, 'resilient');
    },
  );

  testWidgets('capture save closes safely and returns a saved result', (
    tester,
  ) async {
    final bridge = _CaptureBridge();
    final controller = VocabularyController(_Dictionary(), bridge);
    await controller.initialize();
    bool? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                unawaited(
                  showModalBottomSheet<bool>(
                    context: context,
                    builder: (_) => CapturePreviewSheet(
                      capture: const CapturePayload(text: 'elusive'),
                      controller: controller,
                    ),
                  ).then((value) => saved = value),
                );
              },
              child: const Text('Open capture'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open capture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    final saveButton = find.text('Save for review');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(saved, isTrue);
    expect(controller.entries.single.sourceText, 'elusive');
    expect(tester.takeException(), isNull);
  });
}

class _Dictionary extends OfflineDictionary {
  @override
  Future<bool> recognizesSource(
    String selection,
    VocabularyLanguage source,
  ) async => source == VocabularyLanguage.english;

  @override
  Future<DictionaryResult?> lookup(
    String selection, [
    LanguagePair pair = LanguagePair.englishToArabic,
  ]) async => null;
}

class _CaptureBridge extends PlatformBridge {
  final List<CapturePayload> pending = [];
  List<VocabularyEntry> entries = const [];

  @override
  Future<VocabularyLanguage?> loadInterfaceLanguage() async => null;

  @override
  Future<LanguagePair?> loadLanguagePair() async => null;

  @override
  Future<CapturePayload?> takeInitialSelection() async {
    return pending.isEmpty ? null : pending.removeAt(0);
  }

  @override
  Future<List<VocabularyEntry>> loadEntries() async => entries;

  @override
  Future<void> saveEntries(List<VocabularyEntry> entries) async {
    this.entries = List.unmodifiable(entries);
  }

  @override
  Future<VocabularyLanguage?> loadPreferredTargetLanguage() async =>
      VocabularyLanguage.arabic;

  @override
  Future<bool> loadReviewReminders() async => false;

  @override
  Future<UserProfile?> loadUserProfile({String? userId}) async => null;
}
