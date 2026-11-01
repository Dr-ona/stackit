import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/meaning_discovery_provider.dart';
import 'package:stackit/models/capture_payload.dart';
import 'package:stackit/models/dictionary_result.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  group('context-aware ranking', () {
    test('context parameter is accepted by the interface', () async {
      final service = _RankingMeaningService();
      final result = await service.discoverAllMeanings(
        'bank',
        pair: LanguagePair.englishToArabic,
        context: 'I went to the bank to deposit money.',
      );
      expect(result.senses, isNotEmpty);
      expect(result.senses.first.id, 'financial');
    });

    test('without context, senses are returned in default order', () async {
      final service = _RankingMeaningService();
      final result = await service.discoverAllMeanings(
        'bank',
        pair: LanguagePair.englishToArabic,
      );
      expect(result.senses, isNotEmpty);
      expect(result.senses.first.id, 'default');
    });

    test('context parameter can be passed as null', () async {
      final service = _RankingMeaningService();
      final result = await service.discoverAllMeanings(
        'bank',
        pair: LanguagePair.englishToArabic,
        context: null,
      );
      expect(result.senses.first.id, 'default');
    });

    test('empty context is treated as null', () async {
      final service = _RankingMeaningService();
      final result = await service.discoverAllMeanings(
        'bank',
        pair: LanguagePair.englishToArabic,
        context: '   ',
      );
      expect(result.senses.first.id, 'default');
    });
  });

  group('CapturePayload context', () {
    test('context field is preserved through fromMap', () {
      final payload = CapturePayload.fromMap({
        'text': 'bank',
        'source': 'share',
        'context': 'I went to the bank to deposit money.',
      });
      expect(payload.context, 'I went to the bank to deposit money.');
    });

    test('manual payload has null context', () {
      const payload = CapturePayload.manual(text: 'test');
      expect(payload.context, isNull);
    });

    test('missing context in map results in null', () {
      final payload = CapturePayload.fromMap({'text': 'hello'});
      expect(payload.context, isNull);
    });
  });
}

class _RankingMeaningService implements MeaningDiscoveryService {
  @override
  Future<DictionaryResult> discoverAllMeanings(
    String text, {
    required LanguagePair pair,
    DictionaryResult? offlineResult,
    String? context,
  }) async {
    final hasContext = context != null && context.trim().isNotEmpty;
    return DictionaryResult.withSenses(
      sourceText: text,
      senses: [
        VocabularySense(
          id: hasContext ? 'financial' : 'default',
          translations: [hasContext ? 'بنك' : 'ضفاف'],
          definition: hasContext
              ? 'A financial institution.'
              : 'The land alongside a body of water.',
          partOfSpeech: 'noun',
        ),
        VocabularySense(
          id: 'riverbank',
          translations: ['ضفاف النهر'],
          definition: 'The land alongside a body of water.',
          partOfSpeech: 'noun',
        ),
      ],
      sourceLanguage: pair.source,
      targetLanguage: pair.target,
    );
  }
}
