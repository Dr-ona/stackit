import '../../models/language_pair.dart';
import '../../models/vocabulary_entry.dart';

enum EntryStatus { newEntry, learning, reviewing, mastered, due }

enum SortOrder { newest, oldest, alpha, dueFirst, mostReviewed }

class LibraryFilter {
  const LibraryFilter({
    this.languages = const [],
    this.sources = const [],
    this.statuses = const [],
    this.collectionIds = const [],
    this.tagIds = const [],
    this.favorite,
    this.masteryMin,
    this.masteryMax,
    this.dueBefore,
    this.dueAfter,
    this.sortOrder = SortOrder.newest,
    this.searchQuery = '',
  });

  final List<VocabularyLanguage> languages;
  final List<String> sources;
  final List<EntryStatus> statuses;
  final List<String> collectionIds;
  final List<String> tagIds;
  final bool? favorite;
  final int? masteryMin;
  final int? masteryMax;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final SortOrder sortOrder;
  final String searchQuery;

  bool get isEmpty =>
      languages.isEmpty &&
      sources.isEmpty &&
      statuses.isEmpty &&
      collectionIds.isEmpty &&
      tagIds.isEmpty &&
      favorite == null &&
      masteryMin == null &&
      masteryMax == null &&
      dueBefore == null &&
      dueAfter == null &&
      searchQuery.isEmpty;

  LibraryFilter copyWith({
    List<VocabularyLanguage>? languages,
    List<String>? sources,
    List<EntryStatus>? statuses,
    List<String>? collectionIds,
    List<String>? tagIds,
    bool? favorite,
    int? masteryMin,
    int? masteryMax,
    DateTime? dueBefore,
    DateTime? dueAfter,
    SortOrder? sortOrder,
    String? searchQuery,
  }) {
    return LibraryFilter(
      languages: languages ?? this.languages,
      sources: sources ?? this.sources,
      statuses: statuses ?? this.statuses,
      collectionIds: collectionIds ?? this.collectionIds,
      tagIds: tagIds ?? this.tagIds,
      favorite: favorite ?? this.favorite,
      masteryMin: masteryMin ?? this.masteryMin,
      masteryMax: masteryMax ?? this.masteryMax,
      dueBefore: dueBefore ?? this.dueBefore,
      dueAfter: dueAfter ?? this.dueAfter,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FilterService {
  const FilterService();

  List<VocabularyEntry> apply(
    List<VocabularyEntry> entries,
    LibraryFilter filter,
  ) {
    var result = entries.where((e) => _matchesFilters(e, filter)).toList();
    result = _sort(result, filter.sortOrder);
    return result;
  }

  bool _matchesFilters(VocabularyEntry entry, LibraryFilter filter) {
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchesText = entry.sourceText.toLowerCase().contains(q);
      final matchesTranslations = entry.allTranslations.any(
        (t) => t.toLowerCase().contains(q),
      );
      final matchesDefinition = entry.definition.toLowerCase().contains(q);
      if (!matchesText && !matchesTranslations && !matchesDefinition) {
        return false;
      }
    }
    if (filter.languages.isNotEmpty &&
        !filter.languages.contains(entry.sourceLanguage) &&
        !filter.languages.contains(entry.targetLanguage)) {
      return false;
    }
    if (filter.sources.isNotEmpty) {
      final source = entry.sourceAppName ?? entry.meaningSource;
      if (!filter.sources.contains(source)) return false;
    }
    if (filter.statuses.isNotEmpty) {
      final status = _statusOf(entry);
      if (!filter.statuses.contains(status)) return false;
    }
    if (filter.collectionIds.isNotEmpty) {
      if (!filter.collectionIds.any((id) => entry.collectionIds.contains(id))) {
        return false;
      }
    }
    if (filter.tagIds.isNotEmpty) {
      if (!filter.tagIds.any((id) => entry.tags.contains(id))) {
        return false;
      }
    }
    if (filter.favorite == true && !entry.favorite) {
      return false;
    }
    if (filter.dueBefore != null) {
      if (entry.nextReviewAt == null ||
          entry.nextReviewAt!.isAfter(filter.dueBefore!)) {
        return false;
      }
    }
    if (filter.dueAfter != null) {
      if (entry.nextReviewAt != null &&
          entry.nextReviewAt!.isBefore(filter.dueAfter!)) {
        return false;
      }
    }
    return true;
  }

  EntryStatus _statusOf(VocabularyEntry entry) {
    if (entry.reviewCount == 0) return EntryStatus.newEntry;
    if (entry.nextReviewAt != null &&
        entry.nextReviewAt!.isBefore(DateTime.now())) {
      return EntryStatus.due;
    }
    if (entry.intervalDays >= 14 && entry.reviewCount >= 5) {
      return EntryStatus.mastered;
    }
    if (entry.fsrsState == 'review') return EntryStatus.reviewing;
    return EntryStatus.learning;
  }

  List<VocabularyEntry> _sort(List<VocabularyEntry> entries, SortOrder order) {
    final sorted = List<VocabularyEntry>.from(entries);
    switch (order) {
      case SortOrder.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOrder.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOrder.alpha:
        sorted.sort(
          (a, b) =>
              a.sourceText.toLowerCase().compareTo(b.sourceText.toLowerCase()),
        );
      case SortOrder.dueFirst:
        final now = DateTime.now();
        sorted.sort((a, b) {
          final aDue = a.isDue(now) ? 0 : 1;
          final bDue = b.isDue(now) ? 0 : 1;
          if (aDue != bDue) return aDue - bDue;
          final aNext = a.nextReviewAt ?? DateTime(2099);
          final bNext = b.nextReviewAt ?? DateTime(2099);
          return aNext.compareTo(bNext);
        });
      case SortOrder.mostReviewed:
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return sorted;
  }

  List<EntryStatus> statusesForEntry(VocabularyEntry entry) {
    final statuses = <EntryStatus>[];
    statuses.add(_statusOf(entry));
    if (entry.isDue(DateTime.now()) && _statusOf(entry) != EntryStatus.due) {
      statuses.add(EntryStatus.due);
    }
    return statuses;
  }
}
