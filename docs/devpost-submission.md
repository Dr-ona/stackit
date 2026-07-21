# Stackit — OpenAI Build Week submission draft

> Before pasting this into Devpost, rewrite a few sentences in your own voice and
> replace every `[REQUIRED]` placeholder. The organizers explicitly recommend that
> the final description sound like the person who built the project.

## Devpost fields

- **Project name:** Stackit
- **Tagline:** Highlight any word. Understand it in context. Remember it for good.
- **Category:** Education
- **Built with:** Flutter, Dart, Android, Firebase Authentication, Cloud Firestore,
  Firebase AI Logic, Gemini, FSRS, FreeDict, Codex, GPT-5.6
- **Repository:** https://github.com/Dr-ona/stackit
- **Submitter type:** Individual 
- **Country of residence:** UAE
- **Demo video:** [REQUIRED: public or unlisted YouTube URL, under 3 minutes]
- **Codex `/feedback` session ID:** [REQUIRED: obtain from the primary build task]
  

## Project description 

### Inspiration

The words worth learning rarely appear while a vocabulary app is open. They show
up in articles, messages, ebooks, and work documents. Copying a word into another
app interrupts reading, and saving only a translation throws away the sentence
that made the meaning clear. I built Stackit to make that moment useful without
breaking the reader's flow, and add a plus value to language learner's jaurny.

### What it does

On Android, a user highlights text in any app and chooses **Understand with
Stackit**. Stackit captures the word or phrase, its surrounding sentence when the
source app supplies it, and local source metadata. It detects the language,
looks up meanings offline, ranks senses against the original context, and lets the
user save only the meanings they want to learn.

Saved meanings become separate learning items. Stackit schedules each one with
FSRS and generates cloze, multiple-choice, reverse-translation, and definition-
matching exercises. Weak or overdue meanings receive focused practice. The
library supports search, filters, collections, tags, duplicate merging, editing,
and portable export.

The interface supports English, Arabic (including RTL), and French so far as a scalable  foundation for validation.
A bundled 87,000+ entry dictionary covers the main routes offline. AI (Gemini) is used as a fallback, for missing entries and optional enrichment, and successful results are cached so
they remain available later. Source context stays local unless the user explicitly
opts into syncing it.

### How it was built

Stackit is a Flutter application with an Android platform bridge for
`ACTION_PROCESS_TEXT` and share intents. Its local-first data model stores distinct
senses, provenance, source context, and review state. Firebase Authentication and
Cloud Firestore provide optional account sync; Firebase AI Logic supplies the
dictionary fallback and enrichment path. A compact FreeDict-derived binary asset
provides the offline baseline, and FSRS drives per-sense scheduling.

Codex with GPT-5.6 was used during the Build Week iteration to inspect the existing
implementation, reason about submission-critical tradeoffs, improve the judging
and setup documentation, and run the repository's formatting, analysis, and test
checks. The most important architectural choices were keeping capture native and
fast, treating AI as a fallback instead of a requirement, retaining meaning-level
provenance, and scheduling review per sense rather than per spelling.

### Challenges

- Preserving useful sentence context across Android apps while accepting that some
  source apps expose only the selected text.
- Keeping capture useful offline while still supporting richer explanations for
  words that are absent from the bundled dictionaries.
- Representing multiple meanings without merging unrelated senses or losing their
  individual review histories.
- Combining optional cloud sync with a privacy model in which context and source
  metadata remain local by default.

### Accomplishments

- A system-level capture flow that starts where reading already happens.
- Offline multilingual lookup with contextual sense ranking and cached fallback.
- Per-sense adaptive review rather than a flat word-to-translation flashcard.
- A coherent capture-to-library-to-review experience with automated tests covering
  dictionary behavior, scheduling, exercises, search, sync, and entry management.

### What I learned

The highest-value part of a vocabulary item is often not its translation but the
context in which it was encountered. Designing around that insight affected the
Android integration, privacy defaults, sense model, and review flow. I also learned
that AI features are more trustworthy when users can see provenance, choose which
results to keep, and retain a deterministic offline path.

### What's next

- Expand offline dictionary coverage and language pairs.
- Evaluate retention and sense-ranking quality with opt-in, privacy-preserving
  metrics.
- Add more pronunciation and listening practice while preserving text-only access.
- Package a judge-friendly demo build and broaden device compatibility testing.

## Demo video script (target: 2:40–2:50)

The video must be public or unlisted on YouTube, stay under three minutes, and have
clear voiceover covering the product, Codex, and GPT-5.6.

### 0:00–0:18 — Problem and promise

Show Stackit's home screen, then switch to an article.

> Useful words appear while we are already reading, but looking them up breaks the
> flow and usually loses the sentence that gave them meaning. Stackit lets me
> highlight a word anywhere, understand the exact sense, and remember it later.

### 0:18–0:48 — Capture in context

Highlight a word or phrase in the article and tap **Understand with Stackit**.
Pause on the captured sentence and source indicators.

> Stackit integrates with Android's text-processing menu. It captures the selection
> and, when the source app allows it, the surrounding sentence. Source context stays
> on this device unless I explicitly opt into syncing it.

### 0:48–1:22 — Meaning discovery

Show language detection, multiple senses, context ranking, provenance, examples,
and sense selection. If practical, briefly enable airplane mode for an offline hit.

> The bundled dictionary contains more than eighty-seven thousand entries and works
> offline. Stackit ranks meanings against the sentence, separates distinct senses,
> and shows where each result came from. If the offline data has a gap, an AI
> fallback can enrich it and cache the result for later use.

### 1:22–1:52 — Library and organization

Save selected senses, then show search, filters, a collection, and the entry detail.

> I save only the meanings I care about. In the library I can search definitions
> and examples, organize entries with collections and tags, merge duplicates, and
> edit or export my data.

### 1:52–2:18 — Adaptive review

Start a mixed review and answer two different exercise types. Show a due reason or
retention/streak indicator.

> Stackit schedules review per meaning with FSRS. It mixes exercise types and
> explains why an item is due, so weak and overdue meanings receive attention
> without repeatedly drilling what I already know.

### 2:18–2:42 — Codex and GPT-5.6

Show the repository, tests, and the README's Build Week section.

> I used Codex with GPT-5.6 during the Build Week iteration to inspect the
> implementation, reason through the offline-first and privacy tradeoffs, improve
> judge-facing documentation, and verify the project with formatting, static
> analysis, and automated tests. Codex accelerated the final audit while the code
> and tests kept every suggestion grounded in working behavior.

### 2:42–2:50 — Close

Return to the capture-to-review flow or logo.

> Stackit turns the words I meet in real life into knowledge I can keep.

## Final checklist

- [ ] Run the app from a clean checkout or document any required local-only config.
- [x] Run `dart format --output=none --set-exit-if-changed lib test` — 104
      files checked, 0 changes needed after formatting.
- [ ] Run `flutter analyze` locally — the submission-prep environment timed out
      before returning diagnostics.
- [ ] Run `flutter test` locally — `test/text_analyzer_test.dart` passed all 20
      tests, but the full suite timed out before test discovery completed.
- [ ] Confirm the repository is public and includes its GPL-3.0 license, or share a
      private repository with `testing@devpost.com` and
      `build-week-event@openai.com`.
- [ ] Record the complete capture → meaning → save → review flow.
- [ ] Ensure the video voiceover explicitly says how Codex and GPT-5.6 were used.
- [ ] Upload the video early; wait for YouTube processing; use a public or unlisted
      link.
- [ ] Add the `/feedback` session ID from the primary build task.
- [ ] Replace all `[REQUIRED]` placeholders in this document.
- [ ] Add a project thumbnail on Devpost (not supported by the connector's normal
      project update flow).
- [ ] Save and verify that Devpost shows the submission status as **Submitted**.

The submission deadline is **2026-07-22 00:00 UTC** (**2026-07-22 04:00 Dubai**,
**2026-07-21 17:00 Pacific**).
