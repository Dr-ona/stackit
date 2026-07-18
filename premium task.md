# Stackit Premium Product Roadmap

Last updated: 2026-07-17

## Product promise

> Highlight anywhere → understand the exact meaning → remember it permanently.

Every premium task should strengthen at least one part of this loop. Features
that do not improve capture reliability, meaning quality, retention, trust, or
paid-user value should remain below the current priorities.

## Current foundation

- [x] Android PROCESS_TEXT and Share capture entry points.
- [x] Offline English ↔ Arabic dictionaries.
- [x] Offline English ↔ French dictionaries.
- [x] Scalable language metadata and all nine English/Arabic/French routes.
- [x] Automatic source detection with dictionary probing.
- [x] Per-capture translation-route override.
- [x] Two-sided wheel picker for source and target languages.
- [x] Separate interface and preferred translation languages.
- [x] English, Arabic, and French core interface localization.
- [x] Multiple meanings with expandable Library cards.
- [x] Preserve FreeDict sense boundaries and show examples in Inbox.
- [x] Manual word/phrase entry preserves the complete input, opens its full
  detail view after saving, and expands its Library senses by default.
- [x] Add the explicit “Find all meanings” UI and persistence path for
  thin/manual entries while preserving review history.
- [ ] Complete live “Find all meanings” verification after the current App
  Check debug token is allow-listed in Firebase; the on-device request is
  currently rejected with HTTP 403.
- [x] Contextual Gemini explanation on explicit user request.
- [x] Basic spaced review, reminders, authentication, cloud sync, export, and
  account deletion.
- [x] Sixty automated tests and clean static analysis.
- [x] Build, install, and physically verify the latest multilingual APK. The
  2026-07-16 debug build was verified on a Xiaomi 25078RA3EY with Arabic,
  English, and French offline route choices visible on-device.

## Execution principles

1. Preserve existing vocabulary and preferences during every migration.
2. Keep interface language, learning profile, and translation route separate.
3. Prefer direct, attributable language data; never silently pivot through an
   intermediate language when meaning may degrade.
4. Offline capture, lookup, Library, and review must remain useful without an
   account or network.
5. AI submission must always be explicit, scoped, explainable, and optional.
6. Add analytics only with clear consent and without storing captured text in
   product analytics.
7. Every milestone requires tests, accessibility checks, and physical-device
   verification before it is marked complete.

## Milestone 1 — Private user and learning profile

### Profile foundation

- [x] Confirm the target Firestore database and read the required Enterprise
  data-model, Flutter SDK, security-rules, and indexes guidance.
- [x] Add a versioned `UserProfile` domain model with safe migration defaults.
- [x] Store the private profile at an owner-only user path.
- [x] Add strict Firestore validation for permitted fields, types, enum values,
  timestamps, and document ownership.
- [x] Add profile load, create, update, merge, offline/error, and deletion tests.
- [x] Keep local profile preferences usable when signed out.

### Identity profile

- [x] Display name.
- [ ] Optional avatar with safe storage and deletion behavior.
- [x] Verified account email from Firebase Auth.
- [x] Plan/entitlement summary.
- [ ] Account creation date and last profile update.

### Learning profile

- [x] Native language.
- [x] Interface language or “follow device.”
- [x] One or more learning languages.
- [x] Proficiency per learning language.
- [x] Preferred translation language.
- [ ] Pronunciation/accent preference per language.
- [x] Daily word/review goal.
- [x] Review intensity.
- [x] Interests and learning purposes.
- [x] AI, notification, and privacy preferences.

### Profile experience

- [ ] First-run onboarding creates the learning profile.
- [ ] Existing users receive a non-destructive migration prompt.
- [x] Dedicated Profile screen with identity, languages, goals, and settings.
- [ ] Progress summary: collected, learning, mastered, due, streak, and
  estimated retention.
- [ ] Edit, export, and delete profile controls.
- [x] Profile completion never blocks offline capture.

## Milestone 2 — Premium beta trust and release gate

- [ ] Set the production Android application ID.
- [ ] Configure protected release signing outside source control.
- [ ] Add Play Store internal-testing automation and reproducible builds.
- [ ] Add Crashlytics and performance monitoring.
- [ ] Add consent-aware product analytics with no captured vocabulary text.
- [x] Wire Firebase App Check to a local Dart-defined debug token for debug
  builds and Play Integrity for Android release builds.
- [ ] Allow-list and physically verify the developer App Check debug token.
- [ ] Add Firebase quota and abuse alerts.
- [ ] Add end-to-end integration tests.
- [ ] Test a physical device matrix: Pixel, Samsung, Xiaomi, and at least one
  low-memory Android device.
- [ ] Audit TalkBack, RTL, dynamic text, contrast, focus order, and touch sizes.
- [ ] Complete localization of dialogs, errors, notifications, privacy, and
  account-deletion flows in English, Arabic, and French.
- [ ] Add visible sync retry, last-sync time, conflict handling, and recovery.
- [ ] Add localized support and in-app feedback/reporting.
- [ ] Enable Firestore delete protection and evaluate point-in-time recovery
  before paid launch.

## Milestone 3 — Capture that feels magical

- [ ] Capture surrounding sentence when the source app/platform allows it.
- [ ] Preserve app name, title, author, URL, and capture timestamp.
- [ ] Detect word versus multiword expression and preserve the exact selection.
- [x] Add manual word/phrase entry with standard text-field paste support.
- [ ] Add optional proactive clipboard capture.
- [ ] Validate capture behavior across browsers, news apps, social apps, Kindle,
  office documents, and common PDF readers.
- [ ] Add clear recovery when Stackit is missing from PROCESS_TEXT or Share.
- [ ] Add duplicate detection before saving.
- [ ] Add camera/OCR capture with an editable recognition preview.
- [ ] Add voice search and pronunciation capture.
- [ ] Add browser extension capture.
- [ ] Add iOS Share/Action extension when the iOS product begins.

### Capture quality gates

- [ ] Median first successful capture under two minutes after install.
- [ ] Capture sheet opens successfully in at least 99.5% of supported flows.
- [ ] Captured source/context is never uploaded without explicit consent.

## Milestone 4 — Meaning intelligence

- [x] Keep the complete manually entered word or phrase visible in capture,
  Library, and full-detail views.
- [ ] Rank meanings using the captured sentence.
- [ ] Review and save each meaning as an independent sense.
- [ ] Group meanings by part of speech.
- [ ] Add bilingual examples for each saved sense.
- [ ] Add register/domain labels: formal, informal, technical, regional,
  offensive, legal, medical, and similar categories.
- [ ] Add IPA, transliteration, and native-quality audio where licensed.
- [ ] Add inflections, gender, plural forms, verb conjugation, and morphology.
- [ ] Add synonyms, antonyms, collocations, idioms, and related phrases.
- [ ] Show dictionary source, confidence, and offline/online provenance.
- [ ] Add “report incorrect meaning” with a reviewable correction pipeline.
- [ ] Add direct Arabic ↔ French data only when a trustworthy source is found.
- [ ] Establish a repeatable route-onboarding process for future languages.

### Meaning quality gates

- [ ] Offline lookup hit rate above 95% for the supported target corpus.
- [ ] No truncated primary meanings in the curated regression set.
- [ ] Human-reviewed benchmark for top-frequency words and ambiguous senses.

## Milestone 5 — Adaptive learning engine

- [ ] Evaluate and adopt FSRS or another measurable recall-probability model.
- [ ] Schedule meanings independently instead of treating a word as one card.
- [ ] Add cloze, translation, multiple-choice, listening, spelling, and speaking
  exercises.
- [ ] Accept typed and spoken answers before reveal.
- [ ] Detect weak meanings and recurring error patterns.
- [ ] Personalize sessions into new, weak, overdue, listening, and quick-review
  modes.
- [ ] Let users select session duration and daily workload.
- [ ] Add daily goals, streaks, mastery, retention estimates, and progress by
  language.
- [ ] Add accessible review alternatives for users who cannot use audio/speech.

### Learning quality gates

- [ ] Review completion rate and seven-day return rate are measured.
- [ ] Scheduler behavior is simulation-tested across long histories.
- [ ] Users can understand why a card is due and adjust workload safely.

## Milestone 6 — Personal language Library

- [ ] User-created Collections, tags, favorites, and archived items.
- [ ] Let one vocabulary entry belong to zero, one, or multiple Collections
  without duplicating its meanings or review history.
- [ ] Add a quick **Add to Collection** action from capture, word detail, and
  Library screens.
- [ ] Support multi-select add/remove/move actions and safe Collection deletion
  that never deletes vocabulary unless the user explicitly requests it.
- [ ] Provide smart groups for language, source, favorites, new, due, weak, and
  mastered entries alongside user-created Collections.
- [ ] Keep Collection membership offline-first, sync-safe, and ready for future
  shared Collections.
- [ ] Filters by language, status, source, date, mastery, and due state.
- [ ] Edit/delete individual meanings, definitions, examples, and source data.
- [ ] Merge duplicate captures without losing review history.
- [ ] Bulk selection, movement, tagging, export, and deletion.
- [ ] Search words, translations, definitions, examples, and related phrases.
- [ ] Import JSON, CSV, Anki-compatible data, and supported third-party exports.
- [ ] Export JSON, CSV, Anki-compatible data, and printable study sheets.
- [ ] Restore/recovery flow and visible sync history.

## Milestone 7 — Premium reach

- [ ] Production iOS app and capture extension.
- [ ] Chrome/Edge/Firefox capture extension.
- [ ] Optional web Library and review client.
- [ ] OCR for signs, menus, books, and documents.
- [ ] Video/subtitle capture where platform policies permit it.
- [ ] Cross-platform deep links and conflict-safe synchronization.

## Milestone 8 — Responsible monetization

### Proposed free value

- [ ] Reliable capture.
- [ ] Offline dictionary lookup.
- [ ] Basic review.
- [ ] A useful vocabulary allowance and core sync.

### Proposed premium value

- [ ] Unlimited vocabulary and lists.
- [ ] Contextual AI explanations with clear usage controls.
- [ ] Rich examples, enhanced audio, and meaning intelligence.
- [ ] Adaptive exercises and advanced progress analytics.
- [ ] OCR/voice capture and advanced import/export.
- [ ] Expanded cross-device and cross-platform experience.

### Billing and entitlement

- [ ] Google Play Billing and Apple subscriptions.
- [ ] Server-verified entitlements.
- [ ] Restore purchases, grace period, cancellation, and account deletion.
- [ ] Trial after the user experiences a successful capture/review loop.
- [ ] Transparent AI limits and usage meter.
- [ ] Annual, monthly, and education pricing experiments.
- [ ] Never paywall the first successful capture.

## Product analytics and operating metrics

- [ ] Activation: first capture, first save, and first review.
- [ ] Funnel: capture opened → meaning found → saved → reviewed.
- [ ] D1, D7, and D30 retention.
- [ ] Review completion and overdue-card recovery.
- [ ] Lookup hit rate and route-unavailable rate by language pair.
- [ ] Crash-free sessions target above 99.8%.
- [ ] Successful sync operations target above 99.9%.
- [ ] Capture success target above 99.5% on the supported device/app matrix.
- [ ] AI request success, latency, opt-in, and cost without recording submitted
  text in analytics.
- [ ] Support response process and translation-correction turnaround.

## Ordered execution

1. Private user/learning profile foundation and onboarding.
2. Premium beta trust, release, accessibility, and observability gate.
3. Capture context and reliability.
4. Meaning-level contextual intelligence.
5. Adaptive learning and progress.
6. Library organization, import, export, and recovery.
7. iOS/browser/OCR reach.
8. Monetization after activation and retention are demonstrated.

## Definition of a premium beta

- [ ] A new user completes onboarding and their first successful capture in less
  than two minutes without external help.
- [ ] The selected meaning is clear, contextual, editable, and attributable.
- [ ] Review automatically exercises the saved sense at an appropriate time.
- [ ] Profile, progress, sync, privacy, and subscription state are understandable.
- [ ] Core capture, lookup, Library, and review remain useful offline.
- [ ] No known P0/P1 security, privacy, data-loss, accessibility, or release
  defects remain.
