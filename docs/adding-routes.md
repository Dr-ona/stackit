# Adding a New Language Route

This document describes the process for adding support for a new language pair
or route in Stackit.

## Overview

Each route requires:
1. A `LanguagePair` constant in `lib/models/language_pair.dart`
2. An offline dictionary binary (`.stkdict.gz`) in `assets/dictionaries/`
3. An entry in `OfflineDictionary._binaryPaths`
4. Language-specific curated corrections (optional)
5. UI localization strings for the new language

## Step-by-step

### 1. Add the LanguagePair constant

In `lib/models/language_pair.dart`, add a new static constant to the
`LanguagePair` class and include it in the `supported` list.

```dart
static const spanishToEnglish = LanguagePair(
  source: VocabularyLanguage.spanish,
  target: VocabularyLanguage.english,
);
```

### 2. Build the offline dictionary binary

Download the FreeDict data for the new language pair and build the compact
binary asset:

```sh
dart run tool/build_offline_dictionary.dart
```

This produces a `.stkdict.gz` file in `assets/dictionaries/`.

### 3. Register the binary path

In `lib/data/offline_dictionary.dart`, add the new pair ID to `_binaryPaths`:

```dart
static const _binaryPaths = {
  'en_ar': 'assets/dictionaries/freedict_en_ar.stkdict.gz',
  // ... existing entries ...
  'es_en': 'assets/dictionaries/freedict_es_en.stkdict.gz',
};
```

### 4. Add curated corrections (optional)

If you have curated corrections for the new route, add them to the
`_loadCurated` method in `offline_dictionary.dart`.

### 5. Pivot routes

For routes without a direct binary (e.g., Arabic ↔ French), Stackit
automatically pivots through English:
- AR→FR: AR→EN → EN→FR
- FR→AR: FR→EN → EN→AR

No additional binary files are needed for pivoted routes. The pivot lookup
is handled by `OfflineDictionary._pivotLookup`.

### 6. Add UI localization

Add translation strings for the new language in `lib/l10n/app_localizations.dart`
using the `_pick` helper.

### 7. Add tests

Add test cases in `test/language_pair_test.dart` to validate:
- The route is in the `supported` list
- Source detection works for the new language
- The pivot lookup produces results for pivoted routes

## Route validation checklist

- [ ] LanguagePair constant added
- [ ] Binary asset built and placed in assets/dictionaries/
- [ ] Binary path registered in _binaryPaths
- [ ] Curated corrections added (if applicable)
- [ ] UI localization strings added
- [ ] Language detection works for the new language
- [ ] Pivot lookup works for cross-route translations
- [ ] All existing tests pass
- [ ] Physical device verification completed
