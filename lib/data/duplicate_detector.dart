import '../models/vocabulary_entry.dart';

class DuplicateGroup {
  const DuplicateGroup({required this.entries});

  final List<VocabularyEntry> entries;

  VocabularyEntry get keeper => entries.first;

  List<VocabularyEntry> get duplicates =>
      entries.skip(1).toList(growable: false);
}

class DuplicateDetector {
  const DuplicateDetector();

  List<DuplicateGroup> findDuplicates(List<VocabularyEntry> entries) {
    final byText = <String, List<VocabularyEntry>>{};
    for (final entry in entries) {
      final key = _normalize(entry.sourceText);
      byText.putIfAbsent(key, () => []).add(entry);
    }
    return byText.values
        .where((group) => group.length > 1)
        .map((group) => DuplicateGroup(entries: group))
        .toList(growable: false);
  }

  VocabularyEntry mergeGroup(DuplicateGroup group, {required bool keepNewest}) {
    final sorted = List<VocabularyEntry>.from(group.entries)
      ..sort(
        (a, b) => keepNewest
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt),
      );
    final primary = sorted.first;
    final others = sorted.skip(1);
    // Merge senses, tags, collections, and favorites
    final mergedTags = <String>{...primary.tags};
    final mergedCollections = <String>{...primary.collectionIds};
    var mergedFavorite = primary.favorite;
    for (final other in others) {
      mergedTags.addAll(other.tags);
      mergedCollections.addAll(other.collectionIds);
      mergedFavorite = mergedFavorite || other.favorite;
    }
    return primary.copyWith(
      tags: mergedTags.toList(growable: false),
      collectionIds: mergedCollections.toList(growable: false),
      favorite: mergedFavorite,
      reviewCount: sorted
          .map((e) => e.reviewCount)
          .fold<int>(0, (a, b) => a + b),
    );
  }

  static String _normalize(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
