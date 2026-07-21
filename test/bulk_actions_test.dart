import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/duplicate_detector.dart';
import 'package:stackit/data/bulk_action_service.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';

VocabularyEntry _entry(
  String id, {
  String text = 'hello',
  VocabularyLanguage source = VocabularyLanguage.english,
  VocabularyLanguage target = VocabularyLanguage.arabic,
  int reviewCount = 0,
  bool favorite = false,
  List<String> tags = const [],
  List<String> collectionIds = const [],
  DateTime? createdAt,
}) {
  return VocabularyEntry(
    id: id,
    sourceText: text,
    translations: const ['مرحبا'],
    sourceLanguage: source,
    targetLanguage: target,
    definition: 'greeting',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    reviewCount: reviewCount,
    favorite: favorite,
    tags: tags,
    collectionIds: collectionIds,
  );
}

void main() {
  group('DuplicateDetector', () {
    final detector = DuplicateDetector();

    test('finds no duplicates for unique entries', () {
      final entries = [_entry('1', text: 'hello'), _entry('2', text: 'world')];
      expect(detector.findDuplicates(entries), isEmpty);
    });

    test('finds duplicates by normalized text', () {
      final entries = [
        _entry('1', text: 'hello'),
        _entry('2', text: 'Hello'),
        _entry('3', text: 'hello '),
        _entry('4', text: 'world'),
      ];
      final groups = detector.findDuplicates(entries);
      expect(groups.length, 1);
      expect(groups.first.entries.length, 3);
    });

    test('finds multiple duplicate groups', () {
      final entries = [
        _entry('1', text: 'hello'),
        _entry('2', text: 'hello'),
        _entry('3', text: 'world'),
        _entry('4', text: 'world'),
      ];
      final groups = detector.findDuplicates(entries);
      expect(groups.length, 2);
    });

    test('merges group keeping all tags', () {
      final group = DuplicateGroup(
        entries: [
          _entry('1', text: 'hello', tags: ['a'], favorite: true),
          _entry('2', text: 'Hello', tags: ['b']),
        ],
      );
      final merged = detector.mergeGroup(group, keepNewest: true);
      expect(merged.tags, containsAll(['a', 'b']));
      expect(merged.favorite, true);
    });

    test('merges group combining review counts', () {
      final group = DuplicateGroup(
        entries: [
          _entry('1', text: 'hello', reviewCount: 3),
          _entry('2', text: 'Hello', reviewCount: 5),
        ],
      );
      final merged = detector.mergeGroup(group, keepNewest: true);
      expect(merged.reviewCount, 8);
    });

    test('merges group keeping newest by default', () {
      final group = DuplicateGroup(
        entries: [
          _entry('1', text: 'hello', createdAt: DateTime(2026, 1, 1)),
          _entry('2', text: 'Hello', createdAt: DateTime(2026, 6, 1)),
        ],
      );
      final merged = detector.mergeGroup(group, keepNewest: true);
      expect(merged.id, '2');
    });

    test('merges group keeping oldest when requested', () {
      final group = DuplicateGroup(
        entries: [
          _entry('1', text: 'hello', createdAt: DateTime(2026, 1, 1)),
          _entry('2', text: 'Hello', createdAt: DateTime(2026, 6, 1)),
        ],
      );
      final merged = detector.mergeGroup(group, keepNewest: false);
      expect(merged.id, '1');
    });

    test('merges collection ids', () {
      final group = DuplicateGroup(
        entries: [
          _entry('1', text: 'hello', collectionIds: ['col-1']),
          _entry('2', text: 'Hello', collectionIds: ['col-2']),
        ],
      );
      final merged = detector.mergeGroup(group, keepNewest: true);
      expect(merged.collectionIds, containsAll(['col-1', 'col-2']));
    });
  });

  group('BulkActionService', () {
    final service = BulkActionService();

    test('addToCollection adds to all entries', () {
      final entries = [_entry('1'), _entry('2'), _entry('3')];
      final result = service.addToCollection(entries, 'col-1');
      expect(result.affected, 3);
      expect(entries.every((e) => e.collectionIds.contains('col-1')), true);
    });

    test('removeFromCollection removes from all entries', () {
      final entries = [
        _entry('1', collectionIds: ['col-1']),
        _entry('2', collectionIds: ['col-1']),
      ];
      final result = service.removeFromCollection(entries, 'col-1');
      expect(result.affected, 2);
      expect(entries.every((e) => e.collectionIds.isEmpty), true);
    });

    test('addTag adds to all entries', () {
      final entries = [_entry('1'), _entry('2')];
      final result = service.addTag(entries, 'tag-1');
      expect(result.affected, 2);
      expect(entries.every((e) => e.tags.contains('tag-1')), true);
    });

    test('removeTag removes from all entries', () {
      final entries = [
        _entry('1', tags: ['tag-1']),
        _entry('2', tags: ['tag-1']),
      ];
      final result = service.removeTag(entries, 'tag-1');
      expect(result.affected, 2);
      expect(entries.every((e) => e.tags.isEmpty), true);
    });

    test('toggleFavorite toggles all entries', () {
      final entries = [
        _entry('1', favorite: false),
        _entry('2', favorite: true),
      ];
      service.toggleFavorite(entries);
      expect(entries[0].favorite, true);
      expect(entries[1].favorite, false);
    });

    test('delete removes entries by id', () {
      final entries = [_entry('1'), _entry('2'), _entry('3')];
      final remaining = service.removeByIds(entries, {'1', '3'});
      expect(remaining.length, 1);
      expect(remaining.first.id, '2');
    });

    test('removeFromCollection clears collection id from all entries', () {
      final entries = [
        _entry('1', collectionIds: ['c1', 'c2']),
        _entry('2', collectionIds: ['c1']),
        _entry('3', collectionIds: []),
      ];
      service.removeFromCollection(entries, 'c1');
      expect(entries[0].collectionIds, contains('c2'));
      expect(entries[0].collectionIds, isNot(contains('c1')));
      expect(entries[1].collectionIds, isEmpty);
      expect(entries[2].collectionIds, isEmpty);
    });

    test('removeByIds preserves all entries not in the id set', () {
      final entries = [
        _entry('1', collectionIds: ['c1']),
        _entry('2', collectionIds: ['c1']),
        _entry('3', collectionIds: ['c1']),
      ];
      final remaining = service.removeByIds(entries, {'1'});
      expect(remaining.length, 2);
      expect(remaining.map((e) => e.id), containsAll(['2', '3']));
      expect(remaining.every((e) => e.collectionIds.contains('c1')), isTrue);
    });
  });
}
