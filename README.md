# Stackit

Stackit is an offline-first English–Arabic vocabulary collector. On Android,
select English text in another app and choose **Understand with Stackit**. The
app opens a compact meaning preview and lets you save the word or phrase for
later review.

## Current vertical slice

- Android `ACTION_PROCESS_TEXT` integration for user-selected words or phrases
- Bundled 87,000+ entry English–Arabic dictionary that works in airplane mode
- English pronunciation through Android's installed text-to-speech voice
- Explicit one-tap save after the user reads the meaning
- Persistent on-device vocabulary inbox
- English and Arabic library search
- Five-word contextual review sessions with reveal-first cards
- Persistent `Forgot`, `Almost`, and `Remembered` review scheduling
- Graceful fallback when a meaning is not in the offline seed data

FreeDict provides the broad offline translation layer while Stackit's curated
entries provide richer definitions and examples. Context-sensitive and generated
examples can remain an optional online enrichment layer. See
`THIRD_PARTY_NOTICES.md` for attribution and licensing details.

The generated FreeDict asset currently contains 87,412 unique normalized
records. It is approximately 958 KB compressed and expands to approximately
2.72 MB for allocation-light binary-search lookup at runtime.

## Rebuilding the offline dictionary

After downloading and extracting FreeDict 0.6.3 to the documented third-party
path, rebuild the compact asset with:

```sh
dart run tool/build_offline_dictionary.dart
```

## Try the Android capture flow

1. Run the app once on an Android device or emulator.
2. Open an app that exposes Android's selected-text actions.
3. Highlight an English word or phrase.
4. Choose **Understand with Stackit** from the action menu.
5. Read the Arabic meaning and tap **Save for review** if you want to keep it.

Useful seed entries include `elusive`, `nuance`, `figure out`, `take off`, and
`hit the nail on the head`.

## Review schedule

- **Forgot:** return in 10 minutes
- **Almost:** return in 1 day
- **Remembered:** begin at 3 days, then double up to 60 days

Existing locally saved words migrate automatically and begin as due items.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
