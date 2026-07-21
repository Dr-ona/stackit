import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/language_pair.dart';
import '../models/vocabulary_sense.dart';
import 'example_enrichment_provider.dart';

class FirebaseExampleEnrichmentService implements ExampleEnrichmentService {
  FirebaseExampleEnrichmentService({GenerativeModel? model})
    : _model = model ?? _createModel();

  final GenerativeModel _model;

  static GenerativeModel _createModel() {
    final senseSchema = Schema.object(
      properties: {
        'id': Schema.string(),
        'example': Schema.string(),
        'exampleTranslation': Schema.string(),
      },
    );
    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {'enrichedSenses': Schema.array(items: senseSchema)},
        ),
        maxOutputTokens: 2000,
        temperature: 0.2,
      ),
      systemInstruction: Content.system(
        'You are a multilingual lexicographer. For each dictionary sense, '
        'generate one natural, concise example sentence in the source language '
        'and an accurate translation in the target language. '
        'Keep examples realistic and short.',
      ),
    );
  }

  @override
  Future<List<VocabularySense>> enrichExamples({
    required String sourceText,
    required List<VocabularySense> senses,
    required LanguagePair pair,
  }) async {
    final emptySenses = senses.where((s) => s.examples.isEmpty).toList();
    if (emptySenses.isEmpty) return senses;

    final sensesPayload = emptySenses
        .map(
          (s) => {
            'id': s.id,
            'translations': s.translations,
            'definition': s.definition,
            'partOfSpeech': s.partOfSpeech,
          },
        )
        .toList();

    final prompt =
        '''
Term: $sourceText
Source language: ${pair.source.label}
Target language: ${pair.target.label}

Senses that need examples:
${const JsonEncoder.withIndent('  ').convert(sensesPayload)}

For each sense above, return one natural example sentence in ${pair.source.label}
and its accurate translation in ${pair.target.label}. Return the sense id unchanged.
''';

    final GenerateContentResponse response;
    try {
      response = await _model.generateContent([Content.text(prompt)]);
    } catch (_) {
      throw const ExampleEnrichmentException(
        'Examples could not be generated right now.',
      );
    }

    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) return senses;

    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      final items = decoded['enrichedSenses'] as List<Object?>? ?? const [];
      final enrichedById = <String, VocabularyExample>{};
      for (final item in items) {
        if (item is! Map) continue;
        final json = item.cast<String, Object?>();
        final id = (json['id'] as String? ?? '').trim();
        final example = (json['example'] as String? ?? '').trim();
        final exampleTranslation = (json['exampleTranslation'] as String? ?? '')
            .trim();
        if (id.isEmpty || example.isEmpty) continue;
        enrichedById[id] = VocabularyExample(
          sourceText: example,
          translation: exampleTranslation.isEmpty ? null : exampleTranslation,
        );
      }
      if (enrichedById.isEmpty) return senses;
      return senses
          .map((sense) {
            final enriched = enrichedById[sense.id];
            if (enriched == null) return sense;
            return sense.addExample(enriched);
          })
          .toList(growable: false);
    } catch (_) {
      return senses;
    }
  }
}
