import '../../models/collection.dart';
import '../../models/tag.dart';
import '../../models/vocabulary_entry.dart';

class LibraryService {
  const LibraryService();

  List<Collection> collectionsFromJson(Map<String, Object?> json) {
    final raw = json['collections'] as List<Object?>?;
    if (raw == null) return const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((m) => Collection.fromJson(m.cast<String, Object?>()))
        .toList(growable: false);
  }

  List<Tag> tagsFromJson(Map<String, Object?> json) {
    final raw = json['tags'] as List<Object?>?;
    if (raw == null) return const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((m) => Tag.fromJson(m.cast<String, Object?>()))
        .toList(growable: false);
  }

  Map<String, Object?> encodeLibrary({
    required List<Collection> collections,
    required List<Tag> tags,
  }) {
    return {
      'collections': collections.map((c) => c.toJson()).toList(growable: false),
      'tags': tags.map((t) => t.toJson()).toList(growable: false),
    };
  }

  Collection createCollection(String name, {String description = ''}) {
    final now = DateTime.now();
    return Collection(
      id: 'col_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  Tag createTag(String name, {int color = 0xFF356859}) {
    return Tag(
      id: 'tag_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      color: color,
    );
  }

  VocabularyEntry toggleFavorite(VocabularyEntry entry) {
    return entry.copyWith(favorite: !entry.favorite);
  }

  VocabularyEntry addTagToEntry(VocabularyEntry entry, String tagId) {
    if (entry.tags.contains(tagId)) return entry;
    return entry.copyWith(tags: [...entry.tags, tagId]);
  }

  VocabularyEntry removeTagFromEntry(VocabularyEntry entry, String tagId) {
    return entry.copyWith(
      tags: entry.tags.where((t) => t != tagId).toList(growable: false),
    );
  }

  VocabularyEntry addToCollection(VocabularyEntry entry, String collectionId) {
    if (entry.collectionIds.contains(collectionId)) return entry;
    return entry.copyWith(
      collectionIds: [...entry.collectionIds, collectionId],
    );
  }

  VocabularyEntry removeFromCollection(
    VocabularyEntry entry,
    String collectionId,
  ) {
    return entry.copyWith(
      collectionIds: entry.collectionIds
          .where((c) => c != collectionId)
          .toList(growable: false),
    );
  }

  List<VocabularyEntry> inCollection(
    List<VocabularyEntry> entries,
    String collectionId,
  ) {
    return entries
        .where((e) => e.collectionIds.contains(collectionId))
        .toList(growable: false);
  }

  List<VocabularyEntry> withTag(List<VocabularyEntry> entries, String tagId) {
    return entries.where((e) => e.tags.contains(tagId)).toList(growable: false);
  }

  List<VocabularyEntry> favorites(List<VocabularyEntry> entries) {
    return entries.where((e) => e.favorite).toList(growable: false);
  }

  List<Collection> collectionsContainingEntry(
    List<Collection> collections,
    VocabularyEntry entry,
  ) {
    return collections
        .where((c) => entry.collectionIds.contains(c.id))
        .toList(growable: false);
  }
}
