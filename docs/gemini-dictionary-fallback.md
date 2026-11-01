# Gemini Dictionary Fallback

This document describes the three-tier dictionary lookup system in Stackit,
how it works, and how to maintain it.

## Overview

When a user captures a word, Stackit looks it up in this order:

1. **Offline dictionary** — compact `.stkdict.gz` binary files bundled with the
   app (FreeDict + Wiktionary data). Fast, free, works without network.
2. **Local cache** — a JSON file (`local_dictionary_cache.json`) storing
   previously generated Gemini translations. Fast, works offline.
3. **Gemini API** — live call to `gemini-3.5-flash` via Firebase AI Logic.
   Requires network. Results are auto-persisted to the local cache.

```
OfflineDictionary.lookup()
  → LocalDictionaryCache.lookup()
    → GeminiDictionaryService.lookup()
      → LocalDictionaryCache.store()
```

## Architecture

### Components

| File | Role |
|------|------|
| `lib/data/offline_dictionary.dart` | Binary dictionary lookup + pivot through English |
| `lib/data/local_dictionary_cache.dart` | JSON-file cache for Gemini translations |
| `lib/data/gemini_dictionary_service.dart` | Calls Gemini API for a single word+pair |
| `lib/data/dictionary_pre_cache_service.dart` | Batch pre-caches common words in background |

### Lookup flow

The fallback chain is wired in `VocabularyController.lookup()`:

```dart
Future<DictionaryResult?> lookup(String text, {LanguagePair? pair}) async {
  final targetPair = pair ?? languagePair;
  final offlineResult = await _dictionary.lookup(text, targetPair);
  if (offlineResult != null) return offlineResult;
  if (_localCache != null) {
    final cached = await _localCache!.lookup(text, targetPair);
    if (cached != null) return cached;
  }
  if (_geminiDictionaryService != null && _localCache != null) {
    final geminiResult = await _geminiDictionaryService!.lookup(text, targetPair);
    if (geminiResult != null) {
      await _localCache!.store(geminiResult, targetPair);
      return geminiResult;
    }
  }
  return null;
}
```

### UI states

`CapturePreviewSheet` shows different loading states:

- **Normal loading** — `CircularProgressIndicator` during offline/cache lookup
- **AI lookup** — `CircularProgressIndicator` + "AI lookup in progress…" text
  when the offline dictionary misses and Gemini is being queried

## Gemini service details

### Configuration

- **Model:** `gemini-3.5-flash`
- **API:** `FirebaseAI.googleAI()` (Firebase AI Logic)
- **Output:** Structured JSON (`responseMimeType: 'application/json'`)

### Schema

The Gemini response is a JSON array of sense objects:

```json
[
  {
    "translations": ["ترجمة1", "ترجمة2"],
    "definition": "Clear definition in English",
    "partOfSpeech": "noun",
    "examples": ["Example sentence in source language"],
    "registers": ["formal"]
  }
]
```

### Sense IDs

Gemini-generated senses use IDs in the format:
```
gemini-{firstTranslation}-{partOfSpeech}
```

For example: `gemini-كتاب-noun`

This distinguishes them from offline dictionary senses (which use FreeDict IDs)
and curated senses (`sense-1`).

### Error handling

All Gemini API errors are silently caught and return `null`, which causes the
lookup to fall through to the "No results found" state. The user sees a retry
option.

## Local cache

### Storage format

The cache is a single JSON file at the app's documents directory:

```json
{
  "en_ar": {
    "hello": { "senses": [...], "sourceLanguage": "en", "targetLanguage": "ar" },
    "water": { "senses": [...], ... }
  },
  "fr_en": {
    "bonjour": { "senses": [...], ... }
  }
}
```

Keys are normalised (lowercased, trimmed, whitespace-collapsed). Each bucket is
keyed by `LanguagePair.id` (e.g., `en_ar`, `fr_en`).

### Cache lifecycle

- **Read:** `LocalDictionaryCache.lookup(text, pair)` — deserialises from disk on
  first access, then serves from memory.
- **Write:** `LocalDictionaryCache.store(result, pair)` — appends to in-memory
  map and flushes to disk.
- **Bulk write:** `LocalDictionaryCache.storeAll(results, pair)` — used by the
  pre-cache service.

## Pre-cache service

### Purpose

Populates the local cache with common words so Gemini API calls are avoided for
high-frequency lookups. Runs automatically in the background.

### Trigger points

1. **App start** — `VocabularyController._startPreCache()` called at the end of
   `initialize()`
2. **Language pair change** — triggered at the end of `setLanguagePair()`

### Rate limiting

Default: 10 requests per minute (configurable via `requestsPerMinute`).
Each word is fetched one at a time with a delay between requests to stay within
Gemini free-tier limits.

### Word lists

The pre-cache service ships with built-in common word lists:

- **English:** 40 words (hello, goodbye, thank, water, food, …)
- **Arabic:** 37 words (مرحبا, شكرا, ماء, خبز, كتاب, …)
- **French:** 39 words (bonjour, merci, eau, pain, livre, …)

Custom word lists can be passed via `preCache(pair, words: [...])`.

### Skipping cached words

Words that already exist in the local cache are skipped, so re-running the
pre-cache is cheap.

## Adding a new language pair to the fallback

1. Ensure the `VocabularyLanguage` enum includes the new language
2. Add a common word list in `DictionaryPreCacheService._commonWords()`
3. The Gemini service and local cache work for any `LanguagePair` — no changes
   needed

## Debugging

### Check cache contents

The cache file is at the app's documents directory as `local_dictionary_cache.json`.
On a debug build you can read it via:

```sh
adb shell cat /data/data/com.stackit.app/files/local_dictionary_cache.json
```

### Force a Gemini lookup

To bypass the offline dictionary and force a Gemini call, temporarily remove the
pair from `OfflineDictionary._binaryPaths`. The lookup will miss offline and
fall through to Gemini.

## Cost considerations

- Gemini 3.5 Flash has a generous free tier (tokens per minute)
- Pre-cache runs at 10 RPM to stay within limits
- Each lookup returns ≤3 senses, keeping token usage low
- The local cache prevents repeat API calls for the same word

## Testing

All 60 core tests pass with the fallback system. The new services default to
`null` in the `VocabularyController` constructor, so existing test mocks are
unaffected. The fallback chain simply returns `null` when the services are not
provided.

## Files reference

| File | Description |
|------|-------------|
| `lib/data/local_dictionary_cache.dart` | JSON-file cache with lookup/store/storeAll |
| `lib/data/gemini_dictionary_service.dart` | Gemini API call with structured JSON schema |
| `lib/data/dictionary_pre_cache_service.dart` | Background batch pre-caching |
| `lib/features/vocabulary/vocabulary_controller.dart:315` | Fallback chain in `lookup()` |
| `lib/features/vocabulary/capture_preview_sheet.dart` | AI lookup loading UI |
| `lib/main.dart` | Service instantiation and wiring |
| `lib/l10n/app_localizations.dart` | `aiLookupInProgress` string |
