import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/example_enrichment_provider.dart';
import 'package:stackit/models/language_pair.dart';
import 'package:stackit/models/vocabulary_sense.dart';

void main() {
  group('ExampleEnrichmentService', () {
    test('enrichExamples skips senses that already have examples', () async {
      final service = _StubEnrichmentService();
      final senses = [
        VocabularySense(
          id: 'sense-1',
          translations: ['curious'],
          definition: 'eager to know',
          examples: [
            VocabularyExample(
              sourceText: 'The cat is curious.',
              translation: '',
            ),
          ],
        ),
        VocabularySense(
          id: 'sense-2',
          translations: ['inquisitive'],
          definition: 'wanting to learn',
          examples: [],
        ),
      ];
      final result = await service.enrichExamples(
        sourceText: 'curious',
        senses: senses,
        pair: LanguagePair.englishToArabic,
      );
      // First sense untouched, second enriched.
      expect(result[0].examples.length, 1);
      expect(result[1].examples.length, 1);
      expect(result[1].examples.first.sourceText, 'Generated example');
      expect(service.requestedSenseIds, ['sense-2']);
    });

    test('returns original senses when all already have examples', () async {
      final service = _StubEnrichmentService();
      final senses = [
        VocabularySense(
          id: 'sense-1',
          translations: ['happy'],
          definition: 'feeling joy',
          examples: [
            VocabularyExample(sourceText: 'She is happy.', translation: ''),
          ],
        ),
      ];
      final result = await service.enrichExamples(
        sourceText: 'happy',
        senses: senses,
        pair: LanguagePair.englishToArabic,
      );
      expect(result, senses);
      expect(service.callCount, 0);
    });

    test('throws ExampleEnrichmentException on failure', () async {
      final service = _StubEnrichmentService(shouldFail: true);
      final senses = [
        VocabularySense(
          id: 'sense-1',
          translations: ['test'],
          definition: 'a trial',
          examples: [],
        ),
      ];
      expect(
        () => service.enrichExamples(
          sourceText: 'test',
          senses: senses,
          pair: LanguagePair.englishToArabic,
        ),
        throwsA(isA<ExampleEnrichmentException>()),
      );
    });

    test('enrichExamples attaches translation when provided', () async {
      final service = _StubEnrichmentService(
        response: [
          {
            'id': 'sense-1',
            'example': 'A simple sentence.',
            'exampleTranslation': 'جملة بسيطة',
          },
        ],
      );
      final senses = [
        VocabularySense(
          id: 'sense-1',
          translations: ['simple'],
          definition: 'easy',
          examples: [],
        ),
      ];
      final result = await service.enrichExamples(
        sourceText: 'simple',
        senses: senses,
        pair: LanguagePair.englishToArabic,
      );
      expect(result[0].examples.first.translation, 'جملة بسيطة');
    });

    test('enrichExamples skips empty example in response', () async {
      final service = _StubEnrichmentService(
        response: [
          {'id': 'sense-1', 'example': '', 'exampleTranslation': ''},
        ],
      );
      final senses = [
        VocabularySense(
          id: 'sense-1',
          translations: ['test'],
          definition: 'a trial',
          examples: [],
        ),
      ];
      final result = await service.enrichExamples(
        sourceText: 'test',
        senses: senses,
        pair: LanguagePair.englishToArabic,
      );
      expect(result[0].examples, isEmpty);
    });

    test('enrichExamples handles multiple senses at once', () async {
      final service = _StubEnrichmentService(
        response: [
          {'id': 'sense-1', 'example': 'First.', 'exampleTranslation': 'أولى'},
          {
            'id': 'sense-2',
            'example': 'Second.',
            'exampleTranslation': 'ثانية',
          },
        ],
      );
      final senses = [
        VocabularySense(
          id: 'sense-1',
          translations: ['a'],
          definition: 'one',
          examples: [],
        ),
        VocabularySense(
          id: 'sense-2',
          translations: ['b'],
          definition: 'two',
          examples: [],
        ),
      ];
      final result = await service.enrichExamples(
        sourceText: 'word',
        senses: senses,
        pair: LanguagePair.englishToArabic,
      );
      expect(result[0].examples.length, 1);
      expect(result[1].examples.length, 1);
      expect(result[0].examples.first.sourceText, 'First.');
      expect(result[1].examples.first.sourceText, 'Second.');
    });
  });
}

class _StubEnrichmentService implements ExampleEnrichmentService {
  _StubEnrichmentService({this.shouldFail = false, this.response});

  final bool shouldFail;
  final List<Map<String, String>>? response;
  int callCount = 0;
  List<String> requestedSenseIds = [];

  @override
  Future<List<VocabularySense>> enrichExamples({
    required String sourceText,
    required List<VocabularySense> senses,
    required LanguagePair pair,
  }) async {
    final emptySenses = senses.where((s) => s.examples.isEmpty).toList();
    if (emptySenses.isEmpty) return senses;
    callCount++;
    requestedSenseIds = emptySenses.map((s) => s.id).toList();
    if (shouldFail) {
      throw const ExampleEnrichmentException('Failed');
    }
    final items =
        response ??
        [
          for (final s in emptySenses)
            {
              'id': s.id,
              'example': 'Generated example',
              'exampleTranslation': '',
            },
        ];
    final enrichedById = <String, VocabularyExample>{};
    for (final item in items) {
      final example = item['example'] ?? '';
      if (example.isEmpty) continue;
      enrichedById[item['id']!] = VocabularyExample(
        sourceText: example,
        translation: (item['exampleTranslation'] ?? '').isEmpty
            ? null
            : item['exampleTranslation'],
      );
    }
    return senses.map((sense) {
      final enriched = enrichedById[sense.id];
      if (enriched == null) return sense;
      return sense.addExample(enriched);
    }).toList();
  }
}
