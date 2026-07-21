import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/features/review/review_scheduler.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('controller records a remembered review', () async {
    final entry = VocabularyEntry(
      id: 'elusive',
      sourceText: 'elusive',
      translations: const ['صعب المنال'],
      sourceLanguage: VocabularyLanguage.english,
      targetLanguage: VocabularyLanguage.arabic,
      definition: 'Difficult to find, catch, or achieve.',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      dictionaryRevision: OfflineDictionary.contentRevision,
    );
    final controller = VocabularyController(
      OfflineDictionary(),
      _MemoryPlatformBridge()..stored = [entry],
    );
    await controller.initialize();

    await controller.review(
      controller.entries.single,
      ReviewRating.remembered,
      now: DateTime(2026, 1, 2),
    );

    expect(controller.entries.single.reviewCount, 1);
    expect(controller.entries.single.intervalDays, greaterThanOrEqualTo(0));
    expect(controller.entries.single.nextReviewAt, isNotNull);
    expect(controller.entries.single.fsrsState, isNotEmpty);
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
  Future<void> speak(
    String text,
    VocabularyLanguage language, {
    String? localeTag,
  }) async {}
}
