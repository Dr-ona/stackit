import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/offline_dictionary.dart';
import 'package:stackit/data/platform_bridge.dart';
import 'package:stackit/data/vocabulary_cloud_store.dart';
import 'package:stackit/features/vocabulary/vocabulary_controller.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'sign-in merges local and cloud vocabulary then uploads the union',
    () async {
      final local = _entry('local', DateTime.utc(2026, 1, 2));
      final remote = _entry('remote', DateTime.utc(2026, 1, 1));
      final bridge = _MemoryPlatformBridge()..stored = [local];
      final cloud = _MemoryCloudStore()..remote = [remote];
      final controller = VocabularyController(
        OfflineDictionary(),
        bridge,
        cloud,
      );

      await controller.initialize();
      await controller.syncForUser('user-a');

      expect(controller.entries.map((entry) => entry.id), ['local', 'remote']);
      expect(cloud.uploaded.map((entry) => entry.id).toSet(), {
        'local',
        'remote',
      });
      expect(controller.cloudSyncError, isNull);
    },
  );

  test('newer local revision wins when cloud has the same entry id', () async {
    final createdAt = DateTime.utc(2026, 1, 1);
    final bridge = _MemoryPlatformBridge()
      ..stored = [
        _entry(
          'shared',
          createdAt,
          term: 'newer',
          updatedAt: DateTime.utc(2026, 1, 3),
        ),
      ];
    final cloud = _MemoryCloudStore()
      ..remote = [
        _entry(
          'shared',
          createdAt,
          term: 'older',
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ];
    final controller = VocabularyController(OfflineDictionary(), bridge, cloud);

    await controller.initialize();
    await controller.syncForUser('user-a');

    expect(controller.entries.single.sourceText, 'newer');
  });

  test('signed-in saves go to cloud and sign-out clears device data', () async {
    final bridge = _MemoryPlatformBridge();
    final cloud = _MemoryCloudStore();
    final controller = VocabularyController(OfflineDictionary(), bridge, cloud);

    await controller.initialize();
    await controller.syncForUser('user-a');
    final result = await controller.lookup('elusive');
    await controller.save(const CapturePayload(text: 'elusive'), result);
    await Future<void>.delayed(Duration.zero);

    expect(cloud.upserted, hasLength(1));
    expect(cloud.upserted.single.sourceText, 'elusive');

    await controller.clearAfterSignOut();
    expect(controller.entries, isEmpty);
    expect(bridge.stored, isEmpty);
  });
}

VocabularyEntry _entry(
  String id,
  DateTime createdAt, {
  String? term,
  DateTime? updatedAt,
}) {
  return VocabularyEntry(
    id: id,
    sourceText: term ?? id,
    translations: const ['معنى'],
    sourceLanguage: VocabularyLanguage.english,
    targetLanguage: VocabularyLanguage.arabic,
    definition: 'Definition',
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
  );
}

class _MemoryCloudStore implements VocabularyCloudStore {
  List<VocabularyEntry> remote = const [];
  List<VocabularyEntry> uploaded = const [];
  final List<VocabularyEntry> upserted = [];
  final List<String> deleted = [];

  @override
  Future<List<VocabularyEntry>> loadEntries(String userId) async => remote;

  @override
  Future<void> upsertEntries(
    String userId,
    Iterable<VocabularyEntry> entries,
  ) async {
    uploaded = List.unmodifiable(entries);
  }

  @override
  Future<void> upsertEntry(String userId, VocabularyEntry entry) async {
    upserted.add(entry);
  }

  @override
  Future<void> deleteEntry(String userId, String entryId) async {
    deleted.add(entryId);
  }

  @override
  Future<void> deleteAllEntries(String userId) async {
    remote = const [];
    uploaded = const [];
    upserted.clear();
  }
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
  Future<void> speak(String text, VocabularyLanguage language) async {}
}
