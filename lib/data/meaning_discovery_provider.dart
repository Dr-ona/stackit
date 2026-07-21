import '../models/dictionary_result.dart';
import '../models/language_pair.dart';

abstract interface class MeaningDiscoveryService {
  Future<DictionaryResult> discoverAllMeanings(
    String text, {
    required LanguagePair pair,
    DictionaryResult? offlineResult,
    String? context,
  });
}

class MeaningDiscoveryException implements Exception {
  const MeaningDiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}
