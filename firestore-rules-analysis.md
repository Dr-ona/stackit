# Firestore rules analysis (temporary, untracked)

## Target

- Firebase project: `stackit-368da` (from `.firebaserc` and generated options)
- Firestore database: `stackit` (named database, `firebase.json`)
- Configured edition: Enterprise

## Application access patterns

- Authentication: Firebase Auth email/password and Google sign-in. Firestore paths use `currentUser.uid` as `{userId}`.
- `users/{userId}/vocabulary/{entryId}`
  - Collection read with no filters or ordering.
  - Full-document create/update (`set`, `merge: false`).
  - Batched full-library upserts in chunks of 400.
  - Single and batched deletes.
- `users/{userId}/profile/main`
  - Single-document read.
  - Full-document create/update (`set`, `merge: false`).
  - Delete during account deletion.
- No other Firestore collections or queries are used by the Dart application.

## Schema findings

- Vocabulary v2 serialization includes a strict primary-sense projection plus 1-8 sense maps.
- The app supports exactly nine vocabulary language routes: every English, Arabic, and French source/target combination, including `en/en`, `ar/ar`, and `fr/fr`.
- The current vocabulary rule rejects all same-language routes with `sourceLanguage != targetLanguage`. A single rejected entry aborts the atomic full-library batch.
- Profile serialization matches the local v2 rule schema and type/length bounds.
- Profile synchronization can choose a newer local profile over an existing remote profile and then overwrite the remote immutable `createdAt`, which the update rule correctly rejects.

## Least-privilege fix

- Keep owner, strict-schema, size, type, timestamp, and immutable-field checks.
- Permit vocabulary language codes only from `['en', 'ar', 'fr']`; allow all combinations of those supported codes, including same-language study.
- Preserve the existing remote profile `createdAt` whenever a local profile wins a merge.

## Devil's-advocate matrix

- Unauthenticated read/write: must remain denied.
- Cross-user read/write: must remain denied by UID path ownership.
- Client `uid` field injection or modification: must remain denied.
- Unknown vocabulary/profile fields: must remain denied.
- Oversized strings/lists/maps and invalid types: must remain denied.
- Unsupported vocabulary language codes: must be denied.
- Supported same-language vocabulary (`en/en`, `ar/ar`, `fr/fr`): must be allowed for the owner.
- Cross-language supported vocabulary: must remain allowed for the owner.
- Vocabulary/profile `createdAt` mutation on update: must remain denied.
- Monotonic `updatedAt`: must remain required.
- Profile path other than `main`: must remain denied.

## Verification

- Focused Firestore contract, profile synchronization, and vocabulary cloud synchronization tests: 12/12 passed.
- `git diff --check` passed; the only output was Git's informational LF-to-CRLF warning for two working-tree files.
- Full `dart analyze` produced no diagnostics before the local command timed out at two minutes.
- Firebase CLI rule validation and deployment could not be completed in this session because CLI initialization timed out and the environment subsequently blocked the isolated retry at its tool-usage limit. The local rule change is therefore not live until it is deployed.

## 2026-07-23 schema v3 — contextConsented

- New nullable bool field `contextConsented` added to the vocabulary schema.
- When `contextConsented` is `true`, `sourceAppName`, `sourceUrl`, and
  `contextText` are synced. When `false` or absent, these three fields are
  set to `null` in the Firestore document.
- `hasOnlyVocabularyFields` accepts `contextConsented`.
- `isValidVocabulary` validates it as optional bool.
- No changes to access patterns, ownership, or query behavior.
- All devil's-advocate properties from the v2 review remain valid.
