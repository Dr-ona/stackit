import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/dictionary_result.dart';
import '../models/language_pair.dart';
import '../models/vocabulary_sense.dart';
import 'dictionary_normalization.dart';

class GeminiDictionaryService {
  GeminiDictionaryService()
    : _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-3.5-flash');

  final GenerativeModel _model;

  static final _schema = Schema.array(
    items: Schema.object(
      properties: {
        'translations': Schema.array(
          items: Schema.string(
            description: 'Translated word/phrase in the target language',
          ),
        ),
        'definition': Schema.string(description: 'Clear definition in English'),
        'partOfSpeech': Schema.string(
          description: 'noun, verb, adjective, etc.',
        ),
        'examples': Schema.array(
          items: Schema.string(
            description: 'Example sentence in source language',
          ),
        ),
        'registers': Schema.array(
          items: Schema.string(
            description: 'formal, colloquial, archaic, etc.',
          ),
        ),
      },
    ),
  );

  Future<DictionaryResult?> lookup(String word, LanguagePair pair) async {
    final normalised = _normalise(word, pair.source);
    if (normalised.isEmpty) return null;

    final prompt =
        'Translate "$normalised" from ${pair.source.label} to ${pair.target.label}. '
        'Return JSON: array of senses, each with translations (array of target-language words), '
        'definition (English), partOfSpeech, optional examples and registers. '
        'Return at most 3 senses.';

    try {
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _schema,
        ),
      );
      final text = response.text;
      if (text == null || text.isEmpty) return null;

      final parsed = _parseResponse(text);
      if (parsed.isEmpty) return null;

      return DictionaryResult.withSenses(
        sourceText: normalised,
        senses: parsed,
        sourceLanguage: pair.source,
        targetLanguage: pair.target,
      );
    } catch (_) {
      return null;
    }
  }

  List<VocabularySense> _parseResponse(String json) {
    try {
      final decoded = jsonDecode(json);
      final List<Map<String, Object?>> raw;
      if (decoded is List) {
        raw = decoded.cast<Map<String, Object?>>();
      } else if (decoded is Map<String, Object?> &&
          decoded.containsKey('senses')) {
        raw = (decoded['senses'] as List).cast<Map<String, Object?>>();
      } else {
        return const [];
      }

      return raw
          .map((item) {
            final translations =
                (item['translations'] as List?)?.cast<String>() ?? const [];
            final definition = item['definition']?.toString() ?? '';
            final partOfSpeech = item['partOfSpeech']?.toString();
            final examples =
                (item['examples'] as List?)?.cast<String>() ?? const [];
            final registers =
                (item['registers'] as List?)?.cast<String>() ?? const [];

            final normalisedExamples = examples
                .map((e) => VocabularyExample(sourceText: e))
                .toList(growable: false);

            return VocabularySense(
              id: 'gemini-${translations.first}-$partOfSpeech',
              translations: translations
                  .where((t) => t.isNotEmpty)
                  .toList(growable: false),
              definition: definition,
              partOfSpeech: partOfSpeech,
              examples: normalisedExamples,
              registers: registers,
            );
          })
          .where((s) => s.translations.isNotEmpty && s.definition.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static String _normalise(String text, VocabularyLanguage lang) {
    switch (lang) {
      case VocabularyLanguage.english:
        return normalizeEnglishTerm(text);
      case VocabularyLanguage.arabic:
        return normalizeArabicTerm(text);
      case VocabularyLanguage.french:
        return normalizeFrenchTerm(text);
    }
  }
}
