# Stackit Privacy Policy

Effective date: July 23, 2026

Stackit is an offline-first vocabulary collection and review app. This policy
explains what information Stackit processes and the choices available to you.

## Information we process

- Account information: when you create an account, Firebase Authentication
  processes your email address and sign-in credentials, or your Google account
  identity when you choose Google Sign-In.
- Vocabulary data: selected words or phrases, translations, examples, review
  history, language choices, and optional source or sentence context are stored
  locally on your device. When you are signed in, this data is also synchronized
  to a private Cloud Firestore path assigned to your Firebase user ID.
  Source app name, URL, and surrounding sentence context are stored locally by
  default and are only synced to the cloud when you explicitly enable the consent
  toggle for that entry. Each entry may also store a capture timestamp.
- AI requests: when you explicitly choose an AI action, data is sent through
  Firebase AI Logic to Google's Gemini service. The specific data depends on
  the action:
  - "Explain with Gemini": the selected term, language direction, offline
    meanings, and any context you choose to enter.
  - "Find all meanings": the word and language pair, used to generate IPA,
    transliteration, gender, inflections, and additional senses. The original
    sentence may optionally be included to rank senses by relevance.
  - Bilingual example enrichment: when you save a sense that lacks examples,
    a sentence and its translation are generated automatically.
  Stackit does not send your full vocabulary library in any AI request.
- Technical security data: Firebase App Check may process device and app
  attestation signals to help prevent abuse of backend and AI services.

Stackit does not sell personal information and does not use vocabulary content
for advertising.

## Offline use and notifications

Dictionary lookup, local saving, and review work without an internet connection.
If you enable review reminders, Stackit schedules a local notification on your
device. It does not upload notification contents to a messaging service.

## Storage, retention, and security

Local data remains on your device until you delete it, clear app data, or delete
your account. Cloud vocabulary remains until you delete individual entries or
use the in-app "Delete account and cloud data" action. Firestore access is
restricted to the authenticated owner of each vocabulary path. No internet
service can guarantee absolute security.

## Your choices

You can:

- use dictionary and review features offline;
- choose whether to submit a term or context to Gemini;
- choose whether source app name, URL, and context are synced to the cloud (off by default);
- disable local review reminders;
- export your vocabulary as JSON;
- delete saved entries (with undo support);
- permanently delete your Stackit account and associated cloud vocabulary from
  Account & settings; and
- disable product analytics at any time.

## Service providers

Stackit uses Google Firebase services, including Authentication, Cloud Firestore,
App Check, and Firebase AI Logic. Google's handling of data is also governed by
the applicable Google and Firebase terms and privacy documentation.

## Children

Stackit is not directed to children under 13, and we do not knowingly collect
personal information from children under 13.

## Changes and contact

We may update this policy as Stackit evolves. Material changes will be reflected
by updating the effective date. Questions or privacy requests can be sent to
khalidona.bk@gmail.com.
