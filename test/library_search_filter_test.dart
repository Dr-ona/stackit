import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/models/collection.dart';
import 'package:stackit/models/tag.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_entry.dart';
import 'package:stackit/data/library_service.dart';
import 'package:stackit/data/search_service.dart';
import 'package:stackit/data/filter_service.dart';

VocabularyEntry _entry(
  String id, {
  String text = 'hello',
  String definition = 'greeting',
  List<String> translations = const ['مرحبا'],
  VocabularyLanguage source = VocabularyLanguage.english,
  VocabularyLanguage target = VocabularyLanguage.arabic,
  int reviewCount = 0,
  int intervalDays = 0,
  String fsrsState = 'new',
  bool favorite = false,
  List<String> tags = const [],
  List<String> collectionIds = const [],
  String? sourceAppName,
  DateTime? createdAt,
  DateTime? nextReviewAt,
}) {
  return VocabularyEntry(
    id: id,
    sourceText: text,
    translations: translations,
    sourceLanguage: source,
    targetLanguage: target,
    definition: definition,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    reviewCount: reviewCount,
    intervalDays: intervalDays,
    fsrsState: fsrsState,
    favorite: favorite,
    tags: tags,
    collectionIds: collectionIds,
    sourceAppName: sourceAppName,
    nextReviewAt: nextReviewAt,
  );
}

void main() {
  final library = LibraryService();
  final search = SearchService();
  final filter = FilterService();

  group('Collection model', () {
    test('round-trips through JSON', () {
      final now = DateTime(2026, 7, 20);
      final col = Collection(
        id: 'col-1',
        name: 'Travel',
        description: 'Words for travel',
        createdAt: now,
        updatedAt: now,
      );
      final json = col.toJson();
      final restored = Collection.fromJson(json);
      expect(restored.id, 'col-1');
      expect(restored.name, 'Travel');
      expect(restored.description, 'Words for travel');
    });

    test('copyWith preserves id', () {
      final col = Collection(
        id: 'col-1',
        name: 'Travel',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final updated = col.copyWith(name: 'Work');
      expect(updated.id, 'col-1');
      expect(updated.name, 'Work');
    });
  });

  group('Tag model', () {
    test('round-trips through JSON', () {
      final tag = Tag(id: 'tag-1', name: 'urgent', color: 0xFFFF0000);
      final json = tag.toJson();
      final restored = Tag.fromJson(json);
      expect(restored.id, 'tag-1');
      expect(restored.name, 'urgent');
      expect(restored.color, 0xFFFF0000);
    });

    test('copyWith preserves id', () {
      final tag = Tag(id: 'tag-1', name: 'old');
      final updated = tag.copyWith(name: 'new');
      expect(updated.id, 'tag-1');
      expect(updated.name, 'new');
    });
  });

  group('VocabularyEntry new fields', () {
    test('favorite defaults to false', () {
      final e = _entry('1');
      expect(e.favorite, false);
    });

    test('tags default to empty', () {
      final e = _entry('1');
      expect(e.tags, isEmpty);
    });

    test('collectionIds default to empty', () {
      final e = _entry('1');
      expect(e.collectionIds, isEmpty);
    });

    test('favorite survives JSON round-trip', () {
      final e = _entry('1', favorite: true);
      final json = e.toJson();
      final restored = VocabularyEntry.fromJson(json);
      expect(restored.favorite, true);
    });

    test('tags survive JSON round-trip', () {
      final e = _entry('1', tags: ['tag-a', 'tag-b']);
      final json = e.toJson();
      final restored = VocabularyEntry.fromJson(json);
      expect(restored.tags, ['tag-a', 'tag-b']);
    });

    test('collectionIds survive JSON round-trip', () {
      final e = _entry('1', collectionIds: ['col-1']);
      final json = e.toJson();
      final restored = VocabularyEntry.fromJson(json);
      expect(restored.collectionIds, ['col-1']);
    });

    test('sourceAppName survives JSON round-trip', () {
      final e = _entry('1', sourceAppName: 'Kindle');
      final json = e.toJson();
      final restored = VocabularyEntry.fromJson(json);
      expect(restored.sourceAppName, 'Kindle');
    });

    test('copyWith toggles favorite', () {
      final e = _entry('1', favorite: false);
      final toggled = e.copyWith(favorite: true);
      expect(toggled.favorite, true);
    });

    test('copyWith adds tags', () {
      final e = _entry('1', tags: ['a']);
      final updated = e.copyWith(tags: ['a', 'b']);
      expect(updated.tags, ['a', 'b']);
    });

    test('fromJson handles missing new fields gracefully', () {
      final json = {
        'id': '1',
        'sourceText': 'hello',
        'translations': ['مرحبا'],
        'sourceLanguage': 'en',
        'targetLanguage': 'ar',
        'definition': 'greeting',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };
      final e = VocabularyEntry.fromJson(json);
      expect(e.favorite, false);
      expect(e.tags, isEmpty);
      expect(e.collectionIds, isEmpty);
      expect(e.sourceAppName, isNull);
    });
  });

  group('LibraryService', () {
    test('createCollection generates id with prefix', () {
      final c1 = library.createCollection('A');
      expect(c1.id, startsWith('col_'));
      expect(c1.name, 'A');
    });

    test('createTag generates id with prefix', () {
      final t1 = library.createTag('red');
      expect(t1.id, startsWith('tag_'));
    });

    test('toggleFavorite toggles', () {
      final e = _entry('1', favorite: false);
      final toggled = library.toggleFavorite(e);
      expect(toggled.favorite, true);
      final back = library.toggleFavorite(toggled);
      expect(back.favorite, false);
    });

    test('addTagToEntry adds tag', () {
      final e = _entry('1');
      final tagged = library.addTagToEntry(e, 'tag-1');
      expect(tagged.tags, ['tag-1']);
    });

    test('addTagToEntry deduplicates', () {
      final e = _entry('1', tags: ['tag-1']);
      final tagged = library.addTagToEntry(e, 'tag-1');
      expect(tagged.tags, ['tag-1']);
    });

    test('removeTagFromEntry removes tag', () {
      final e = _entry('1', tags: ['tag-1', 'tag-2']);
      final untagged = library.removeTagFromEntry(e, 'tag-1');
      expect(untagged.tags, ['tag-2']);
    });

    test('addToCollection adds', () {
      final e = _entry('1');
      final added = library.addToCollection(e, 'col-1');
      expect(added.collectionIds, ['col-1']);
    });

    test('addToCollection deduplicates', () {
      final e = _entry('1', collectionIds: ['col-1']);
      final added = library.addToCollection(e, 'col-1');
      expect(added.collectionIds, ['col-1']);
    });

    test('removeFromCollection removes', () {
      final e = _entry('1', collectionIds: ['col-1', 'col-2']);
      final removed = library.removeFromCollection(e, 'col-1');
      expect(removed.collectionIds, ['col-2']);
    });

    test('inCollection filters entries', () {
      final entries = [
        _entry('1', collectionIds: ['col-1']),
        _entry('2', collectionIds: ['col-2']),
        _entry('3', collectionIds: ['col-1', 'col-2']),
      ];
      expect(library.inCollection(entries, 'col-1').length, 2);
      expect(library.inCollection(entries, 'col-2').length, 2);
      expect(library.inCollection(entries, 'col-3').length, 0);
    });

    test('withTag filters entries', () {
      final entries = [
        _entry('1', tags: ['t1']),
        _entry('2', tags: ['t2']),
        _entry('3', tags: ['t1', 't2']),
      ];
      expect(library.withTag(entries, 't1').length, 2);
      expect(library.withTag(entries, 't2').length, 2);
    });

    test('favorites filters entries', () {
      final entries = [
        _entry('1', favorite: true),
        _entry('2', favorite: false),
        _entry('3', favorite: true),
      ];
      expect(library.favorites(entries).length, 2);
    });

    test('encodeLibrary round-trips collections and tags', () {
      final collections = [
        Collection(
          id: 'c1',
          name: 'A',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];
      final tags = [Tag(id: 't1', name: 'red')];
      final encoded = library.encodeLibrary(
        collections: collections,
        tags: tags,
      );
      final decodedCollections = library.collectionsFromJson(encoded);
      final decodedTags = library.tagsFromJson(encoded);
      expect(decodedCollections.length, 1);
      expect(decodedCollections.first.name, 'A');
      expect(decodedTags.length, 1);
      expect(decodedTags.first.name, 'red');
    });
  });

  group('SearchService', () {
    test('empty query returns all', () {
      final entries = [_entry('1'), _entry('2')];
      expect(search.search(entries, ''), entries);
      expect(search.search(entries, '   '), entries);
    });

    test('finds by sourceText', () {
      final entries = [_entry('1', text: 'hello'), _entry('2', text: 'world')];
      expect(search.search(entries, 'hello').length, 1);
    });

    test('finds by definition', () {
      final entries = [
        _entry('1', definition: 'a greeting'),
        _entry('2', definition: 'a farewell'),
      ];
      expect(search.search(entries, 'greeting').length, 1);
    });

    test('finds by translation', () {
      final entries = [
        _entry('1', translations: ['مرحبا']),
        _entry('2', translations: ['وداعا']),
      ];
      expect(search.search(entries, 'مرحبا').length, 1);
    });

    test('case-insensitive', () {
      final entries = [_entry('1', text: 'Hello')];
      expect(search.search(entries, 'hello').length, 1);
      expect(search.search(entries, 'HELLO').length, 1);
    });

    test('partial match works', () {
      final entries = [_entry('1', text: 'uncomfortable')];
      expect(search.search(entries, 'comfort').length, 1);
    });

    test('no match returns empty', () {
      final entries = [_entry('1', text: 'hello')];
      expect(search.search(entries, 'xyz'), isEmpty);
    });

    test('searches across multiple fields', () {
      final entries = [
        _entry('1', text: 'bank', definition: 'financial institution'),
        _entry('2', text: 'bank', definition: 'river bank'),
      ];
      final results = search.search(entries, 'river');
      expect(results.length, 1);
      expect(results.first.id, '2');
    });
  });

  group('FilterService', () {
    test('empty filter returns all', () {
      final entries = [_entry('1'), _entry('2')];
      expect(filter.apply(entries, const LibraryFilter()), entries);
    });

    test('filters by language', () {
      final entries = [
        _entry('1', source: VocabularyLanguage.english),
        _entry('2', source: VocabularyLanguage.french),
      ];
      final f = LibraryFilter(languages: [VocabularyLanguage.english]);
      expect(filter.apply(entries, f).length, 1);
    });

    test('filters by source', () {
      final entries = [
        _entry('1', sourceAppName: 'Kindle'),
        _entry('2', sourceAppName: 'Browser'),
      ];
      final f = LibraryFilter(sources: ['Kindle']);
      expect(filter.apply(entries, f).length, 1);
    });

    test('filters by status newEntry', () {
      final entries = [
        _entry('1', reviewCount: 0),
        _entry('2', reviewCount: 3, intervalDays: 7, fsrsState: 'review'),
      ];
      final f = LibraryFilter(statuses: [EntryStatus.newEntry]);
      expect(filter.apply(entries, f).length, 1);
      expect(filter.apply(entries, f).first.id, '1');
    });

    test('filters by status mastered', () {
      final entries = [
        _entry('1', reviewCount: 6, intervalDays: 15, fsrsState: 'review'),
        _entry('2', reviewCount: 2, intervalDays: 3, fsrsState: 'learning'),
      ];
      final f = LibraryFilter(statuses: [EntryStatus.mastered]);
      expect(filter.apply(entries, f).length, 1);
      expect(filter.apply(entries, f).first.id, '1');
    });

    test('filters by due state', () {
      final now = DateTime.now();
      final entries = [
        _entry(
          '1',
          reviewCount: 3,
          nextReviewAt: now.subtract(const Duration(days: 1)),
        ),
        _entry(
          '2',
          reviewCount: 3,
          nextReviewAt: now.add(const Duration(days: 5)),
        ),
      ];
      final f = LibraryFilter(statuses: [EntryStatus.due]);
      expect(filter.apply(entries, f).length, 1);
      expect(filter.apply(entries, f).first.id, '1');
    });

    test('sortOrder newest puts recent first', () {
      final entries = [
        _entry('1', createdAt: DateTime(2026, 1, 1)),
        _entry('2', createdAt: DateTime(2026, 6, 1)),
      ];
      final f = LibraryFilter(sortOrder: SortOrder.newest);
      final sorted = filter.apply(entries, f);
      expect(sorted.first.id, '2');
    });

    test('sortOrder alpha sorts alphabetically', () {
      final entries = [_entry('1', text: 'banana'), _entry('2', text: 'apple')];
      final f = LibraryFilter(sortOrder: SortOrder.alpha);
      final sorted = filter.apply(entries, f);
      expect(sorted.first.id, '2');
    });

    test('sortOrder dueFirst puts due entries first', () {
      final now = DateTime.now();
      final entries = [
        _entry('1', nextReviewAt: now.add(const Duration(days: 5))),
        _entry('2', nextReviewAt: now.subtract(const Duration(days: 1))),
      ];
      final f = LibraryFilter(sortOrder: SortOrder.dueFirst);
      final sorted = filter.apply(entries, f);
      expect(sorted.first.id, '2');
    });

    test('LibraryFilter.isEmpty is true when no filters set', () {
      expect(const LibraryFilter().isEmpty, true);
    });

    test('LibraryFilter.isEmpty is false when any filter set', () {
      expect(
        LibraryFilter(languages: [VocabularyLanguage.english]).isEmpty,
        false,
      );
    });

    test('multiple filters combine (AND)', () {
      final entries = [
        _entry('1', text: 'hello', source: VocabularyLanguage.english),
        _entry('2', text: 'bonjour', source: VocabularyLanguage.french),
        _entry('3', text: 'world', source: VocabularyLanguage.english),
      ];
      final f = LibraryFilter(
        languages: [VocabularyLanguage.english],
        searchQuery: 'hello',
      );
      // Both language AND search must match.
      expect(filter.apply(entries, f).length, 1);
    });
  });
}
