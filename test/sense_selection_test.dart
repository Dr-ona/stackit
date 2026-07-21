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
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checkboxes appear when multiple senses exist', (tester) async {
    final bridge = _TestBridge();
    final controller = VocabularyController(_Dictionary(), bridge);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showModalBottomSheet<CaptureResult>(
                  context: context,
                  builder: (_) => CapturePreviewSheet(
                    capture: const CapturePayload(text: 'bank'),
                    controller: controller,
                  ),
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

    // Checkboxes should be present for multi-sense results
    expect(find.byType(Checkbox), findsWidgets);
  });

  testWidgets('unchecking a sense excludes it from save', (tester) async {
    final bridge = _TestBridge();
    final controller = VocabularyController(_Dictionary(), bridge);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showModalBottomSheet<CaptureResult>(
                  context: context,
                  builder: (_) => CapturePreviewSheet(
                    capture: const CapturePayload(text: 'bank'),
                    controller: controller,
                  ),
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

    // Uncheck the first checkbox
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsWidgets);
    await tester.tap(checkboxes.first);
    await tester.pump();

    // Save
    final saveButton = find.text('Save for review');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Entry should be saved with only the selected senses
    expect(controller.entries, hasLength(1));
    final entry = controller.entries.first;
    // Should have 1 sense (the second one, since we unchecked the first)
    expect(entry.senses.length, 1);
  });

  testWidgets('no checkbox when only one sense', (tester) async {
    final bridge = _TestBridge(singleSense: true);
    final controller = VocabularyController(
      _Dictionary(singleSense: true),
      bridge,
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showModalBottomSheet<CaptureResult>(
                  context: context,
                  builder: (_) => CapturePreviewSheet(
                    capture: const CapturePayload(text: 'hello'),
                    controller: controller,
                  ),
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

    // No checkboxes for single sense
    expect(find.byType(Checkbox), findsNothing);
  });
}

class _TestBridge extends PlatformBridge {
  _TestBridge({this.singleSense = false});

  final bool singleSense;
  List<VocabularyEntry> entries = const [];

  @override
  Future<VocabularyLanguage?> loadInterfaceLanguage() async => null;

  @override
  Future<LanguagePair?> loadLanguagePair() async => null;

  @override
  Future<CapturePayload?> takeInitialSelection() async => null;

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

class _Dictionary extends OfflineDictionary {
  _Dictionary({this.singleSense = false});

  final bool singleSense;

  @override
  Future<bool> recognizesSource(
    String selection,
    VocabularyLanguage source,
  ) async => source == VocabularyLanguage.english;

  @override
  Future<DictionaryResult?> lookup(
    String selection, [
    LanguagePair pair = LanguagePair.englishToArabic,
  ]) async {
    if (!singleSense) {
      return DictionaryResult.withSenses(
        sourceText: selection,
        senses: const [
          VocabularySense(
            id: 'sense-1',
            translations: ['بنك'],
            definition: 'A financial institution.',
            partOfSpeech: 'noun',
          ),
          VocabularySense(
            id: 'sense-2',
            translations: ['ضفاف النهر'],
            definition: 'The land alongside a body of water.',
            partOfSpeech: 'noun',
          ),
        ],
        sourceLanguage: pair.source,
        targetLanguage: pair.target,
      );
    }
    return DictionaryResult.withSenses(
      sourceText: selection,
      senses: const [
        VocabularySense(
          id: 'sense-1',
          translations: ['مرحبا'],
          definition: 'A greeting.',
          partOfSpeech: 'interjection',
        ),
      ],
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
    );
  }
}
