# Context: Gemini Dictionary Fallback & Pre-Cache

## Summary
Implemented a three-tier dictionary lookup system: offline → local cache → Gemini API. When a word isn't found in the offline dictionary, the app checks a JSON-file cache of previously generated Gemini translations, then falls back to a live Gemini API call. Results are auto-persisted to cache for future offline use. A pre-cache service runs in the background on app start to populate common words.

## Architecture
```
OfflineDictionary.lookup()
  → LocalDictionaryCache.lookup()
    → GeminiDictionaryService.lookup()
      → LocalDictionaryCache.store()  [persist for next time]
```

## Files Created
- `lib/data/local_dictionary_cache.dart` — JSON-file-backed cache for Gemini translations
- `lib/data/gemini_dictionary_service.dart` — Calls Gemini `gemini-3.5-flash` for single word+pair
- `lib/data/dictionary_pre_cache_service.dart` — Batch pre-caches common words (40 EN, 37 AR, 39 FR)

## Files Modified
- `lib/features/vocabulary/vocabulary_controller.dart` — Added fallback chain in `lookup()`, added `_startPreCache()` triggered on init and language pair change
- `lib/features/vocabulary/capture_preview_sheet.dart` — "AI lookup in progress…" UI state with `_geminiLookup` flag
- `lib/main.dart` — Instantiates `LocalDictionaryCache`, `GeminiDictionaryService`, `DictionaryPreCacheService`
- `lib/l10n/app_localizations.dart` — Added `aiLookupInProgress` string (EN/AR/FR)

## Key Details
- `GeminiDictionaryService` uses structured JSON output (`responseMimeType: 'application/json'`) with a `Schema.array` of senses
- `DictionaryPreCacheService` rate-limits to 10 RPM (configurable), skips already-cached entries
- `VocabularySense.id` for Gemini results follows format `'gemini-{firstTranslation}-{partOfSpeech}'`
- Pre-cache triggers: (1) on `controller.initialize()`, (2) on `controller.setLanguagePair()`
- All 60 core tests pass; `_preCacheService` defaults to `null` so existing test mocks are unaffected

## Gemini API Usage
- Model: `gemini-3.5-flash` via `FirebaseAI.googleAI()`
- Prompt asks for ≤3 senses with translations, definition (English), partOfSpeech, optional examples and registers
- Response parsed into `DictionaryResult.withSenses()` → `VocabularySense` objects

## Remaining Work
- Wire pre-cache into a persistent background isolate for large word lists
- Add analytics tracking for cache hit rate vs Gemini API calls
- Consider adding "No results found" UI when all three tiers miss
- Consider user preference to disable Gemini fallback (data/cost control)

## Documentation
- `docs/gemini-dictionary-fallback.md` — Full developer documentation
