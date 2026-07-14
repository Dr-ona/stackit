import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/features/review/review_page.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('review hides the word until reveal and accepts a rating', (
    tester,
  ) async {
    final controller = VocabularyController(
      OfflineDictionary(),
      _MemoryPlatformBridge(),
    );
    await controller.initialize();
    final result = await controller.lookup('elusive');
    await controller.save(const CapturePayload(text: 'elusive'), result);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReviewPage(controller: controller)),
      ),
    );

    expect(find.textContaining('________'), findsOneWidget);
    expect(find.text('صعب المنال'), findsNothing);

    await tester.tap(find.text('Reveal meaning'));
    await tester.pumpAndSettle();

    expect(find.textContaining('صعب المنال'), findsOneWidget);
    expect(find.text('Remembered'), findsOneWidget);

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(find.text('SESSION COMPLETE'), findsOneWidget);
    expect(controller.entries.single.reviewCount, 1);
    expect(controller.entries.single.intervalDays, 3);
  });
}

class _MemoryPlatformBridge extends PlatformBridge {
  List<VocabularyEntry> stored = const [];

  @override
  Future<CapturePayload?> takeInitialSelection() async => null;

  @override
  Future<List<VocabularyEntry>> loadEntries() async => stored;

  @override
  Future<void> saveEntries(List<VocabularyEntry> entries) async {
    stored = List.unmodifiable(entries);
  }

  @override
  Future<void> speak(String text) async {}
}
