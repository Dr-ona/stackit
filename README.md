# Stackit

[![Flutter CI](https://github.com/Dr-ona/stackit/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/Dr-ona/stackit/actions/workflows/flutter-ci.yml)

> Highlight anywhere → understand the exact meaning → remember it permanently.

Stackit is an offline-first multilingual vocabulary collector for Android. Select
text in any app, tap **Understand with Stackit**, and get instant translations
with spaced-repetition review — all without leaving your current app.

## Features

### Capture
- Android `ACTION_PROCESS_TEXT` and Share intent integration
- Manual word/phrase entry with full detail expansion
- Automatic source language detection (English, Arabic, French)
- Per-capture translation route override with wheel picker
- All 9 language routes: EN↔AR, EN↔FR, AR↔FR, and same-language study

### Meaning
- 87,000+ entry offline dictionary (EN↔AR, EN↔FR, FR↔EN)
- Multi-sense vocabulary model with translations, definitions, and examples
- **Find all meanings** — Gemini AI expands entries into distinct senses
- **Contextual explanation** — AI explains a word in its original sentence context

### Review
- Spaced repetition: Forgot (10 min) → Almost (1 day) → Remembered (3→60 days)
- Five-word flashcard sessions with reveal-first cards
- Daily review reminders via local notifications

### Profile & Sync
- Firebase Authentication (email/password + Google Sign-In)
- Cloud sync with Firestore (bidirectional merge, conflict-safe)
- Learning profile: languages, proficiency, goals, interests
- Profile avatar upload and management
- JSON vocabulary export

### Languages
- Full interface in English, Arabic (RTL), and French
- Follows device language or manual override

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3.12+) |
| Auth | Firebase Auth |
| Database | Cloud Firestore (named DB) |
| AI | Firebase AI Logic (Gemini 3.5 Flash) |
| Storage | Firebase Storage |
| Safety | Firebase App Check, Crashlytics |
| Offline | Custom binary `.stkdict.gz` with FreeDict data |
| TTS | Android platform channel |

## Getting Started

### Prerequisites
- Flutter SDK 3.12+
- Android Studio or VS Code with Android tooling
- A Firebase project with the `google-services.json` placed in `android/app/`

### Run

```sh
flutter pub get
flutter run
```

### Build release APK

```sh
flutter build apk --release
```

The signed APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Rebuilding the offline dictionary

After downloading and extracting FreeDict 0.6.3 to the documented third-party
path, rebuild the compact asset with:

```sh
dart run tool/build_offline_dictionary.dart
```

## Try the capture flow

1. Run the app on an Android device.
2. Open any app that supports text selection (browser, news, e-reader).
3. Highlight a word or phrase.
4. Choose **Understand with Stackit** from the action menu.
5. Read the meaning and tap **Save for review**.

## Review schedule

- **Forgot:** return in 10 minutes
- **Almost:** return in 1 day
- **Remembered:** begin at 3 days, then double up to 60 days

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Legal

- [Privacy Policy](docs/privacy.md)
- [Terms of Service](docs/terms.md)
- [License](LICENSE) (GPL-3.0)

## Contact

**Email:** khalidona.bk@gmail.com
