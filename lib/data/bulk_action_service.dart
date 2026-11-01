import '../models/vocabulary_entry.dart';
import 'library_service.dart';

class BulkActionResult {
  const BulkActionResult({required this.affected});

  final int affected;
}

class BulkActionService {
  const BulkActionService({LibraryService? library})
    : _library = library ?? const LibraryService();

  final LibraryService _library;

  BulkActionResult addToCollection(
    List<VocabularyEntry> entries,
    String collectionId,
  ) {
    var count = 0;
    for (var i = 0; i < entries.length; i++) {
      entries[i] = _library.addToCollection(entries[i], collectionId);
      count++;
    }
    return BulkActionResult(affected: count);
  }

  BulkActionResult removeFromCollection(
    List<VocabularyEntry> entries,
    String collectionId,
  ) {
    var count = 0;
    for (var i = 0; i < entries.length; i++) {
      entries[i] = _library.removeFromCollection(entries[i], collectionId);
      count++;
    }
    return BulkActionResult(affected: count);
  }

  BulkActionResult addTag(List<VocabularyEntry> entries, String tagId) {
    var count = 0;
    for (var i = 0; i < entries.length; i++) {
      entries[i] = _library.addTagToEntry(entries[i], tagId);
      count++;
    }
    return BulkActionResult(affected: count);
  }

  BulkActionResult removeTag(List<VocabularyEntry> entries, String tagId) {
    var count = 0;
    for (var i = 0; i < entries.length; i++) {
      entries[i] = _library.removeTagFromEntry(entries[i], tagId);
      count++;
    }
    return BulkActionResult(affected: count);
  }

  BulkActionResult toggleFavorite(List<VocabularyEntry> entries) {
    var count = 0;
    for (var i = 0; i < entries.length; i++) {
      entries[i] = _library.toggleFavorite(entries[i]);
      count++;
    }
    return BulkActionResult(affected: count);
  }

  List<VocabularyEntry> delete(List<VocabularyEntry> entries) {
    final ids = entries.map((e) => e.id).toSet();
    return entries.where((e) => !ids.contains(e.id)).toList(growable: false);
  }

  List<VocabularyEntry> removeByIds(
    List<VocabularyEntry> all,
    Set<String> ids,
  ) {
    return all.where((e) => !ids.contains(e.id)).toList(growable: false);
  }
}
