# Context: Dictionary Expansion with Wiktionary Data

## Summary
Successfully merged FreeDict + Wiktionary data into the offline dictionaries. The FR directions saw massive improvements while EN→AR/AR→EN saw minimal gains (FreeDict already covers most Wiktionary entries).

## Results
| Direction | FreeDict | + Wiktionary | Improvement |
|-----------|----------|-------------|-------------|
| EN→AR | 87,412 | 87,417 | +5 |
| AR→EN | 52,843 | 52,846 | +3 |
| EN→FR | 8,767 | 57,788 | **+49,021 (6.6x)** |
| FR→EN | 8,248 | 142,475 | **+134,227 (17.3x)** |
| FR→AR | - | 16,063 | New pivot data |

## Files Modified
- `tool/build_expanded_dictionary.dart` - Added `--pairs-dir` flag, `_mergePairsDir()`, fixed URLs
- `test/offline_dictionary_test.dart` - Updated expected counts for expanded dictionaries

## Files Created
- `third_party/wiktionary/en-extract.jsonl.gz` - EN Wiktionary raw data (2.8GB)
- `third_party/wiktionary/fr-extract.jsonl.gz` - FR Wiktionary raw data (676MB)
- `third_party/wiktionary/en-wikt-pairs.json` - Extracted EN translation pairs (6.1MB)
- `third_party/wiktionary/fr-wikt-pairs.json` - Extracted FR translation pairs (7.2MB)
- `tool/extract_en_wikt_fast.py` - Fast regex extractor for EN Wiktionary
- `tool/parse_en_relevant.py` - Parser for filtered EN Wiktionary lines
- `tool/download_wiktionary.ps1` - PowerShell download script
- `tool/prefilter_wiktionary.ps1` - PowerShell pre-filter script
- `tool/prefilter_wiktionary.py` - Python pre-filter script
- `tool/extract_en_wikt.py` - Python streaming extractor (original)
- `tool/extract_en_wikt_decompressed.py` - Python decompressed file processor

## Build Command
```bash
dart run tool/build_expanded_dictionary.dart --skip-wiktionary --skip-panlex --pairs-dir third_party/wiktionary
```

## Notes
- EN Wiktionary file (2.8GB compressed, 23GB decompressed) is very slow to process end-to-end
- Partial extraction from ~65% of the file captured most useful data
- FR Wiktionary (676MB) processed fully in ~3 minutes
- Next step: PanLex integration for additional coverage
