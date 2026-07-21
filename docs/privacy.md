# Privacy Policy for Stackit

**Last updated:** July 23, 2026

Stackit ("we", "our", or "the app") is an open-source vocabulary collector built with Flutter. This privacy policy explains what data we handle, how it is used, and your rights.

## Data we store

### On your device
- Vocabulary entries you save (words, translations, definitions, examples)
- Source app name, URL, and capture timestamp for each entry (when available) — stored locally by default
- Surrounding sentence context captured from the source app (when available) — stored locally by default
- Your learning profile (languages, proficiency, goals, preferences, accent preferences)
- Review history and spaced-repetition schedule
- Collections and tags you create

Source app name, URL, and surrounding sentence are only synced to the cloud when you explicitly enable the consent toggle on that entry. All other data remains on your device and is never transmitted unless you sign in.

### In the cloud (optional, requires sign-in)
When you sign in with email/password or Google Sign-In, the following is synced to your private Firebase account:
- Your vocabulary entries
- Your learning profile
- Your profile photo (if uploaded)

Source app name, URL, and surrounding sentence context are **not synced** unless you explicitly enable the consent toggle for each entry. This toggle is off by default.

This data is **private to your account**. No other user can access it.

## Data we send

### AI features
When you explicitly request an AI action, the following data may be sent to Google Gemini:

- **Explain in context** — the selected word and the sentence you choose to submit.
- **Find all meanings** — the word and its language pair. Gemini generates IPA, transliteration, gender, inflections, and additional senses. Optionally, the original sentence may be included to rank senses by relevance.
- **Bilingual example enrichment** — when you save a sense that lacks examples, a sentence in the source language and its translation are generated automatically.

AI requests are only made when you explicitly request them. We do **not** send your full vocabulary library, browsing history, or surrounding text beyond what you submit.

### Analytics (opt-in only)
If you enable "Private product analytics" in your profile settings, anonymous usage events are logged (e.g., first capture, first save, first review, session completion, return-rate timestamps). These events contain **no vocabulary text, no personal information, and no content from your captures**. Session completion events record cards reviewed, accuracy, and duration — never the words themselves. Analytics can be disabled at any time from your profile settings.

### Crash reporting
Firebase Crashlytics may record anonymous crash logs and non-fatal errors to help us fix bugs. Crash logs do not contain your vocabulary or personal data.

### App verification
Firebase App Check verifies that requests to our backend come from a legitimate copy of Stackit. This does not collect personal information.

## Data we never collect
- Your captured or saved vocabulary text (outside of your private cloud sync)
- Your browsing history or app usage outside Stackit
- Your clipboard contents (clipboard is read only when you explicitly tap "Paste from clipboard")
- Your location
- Your contacts or files
- Any data for advertising or sale to third parties
- Source app name, URL, or surrounding sentence in the cloud (unless you explicitly enable the consent toggle per entry)

## Third-party services

| Service | Purpose | Privacy policy |
|---|---|---|
| Firebase (Google) | Authentication, cloud sync, storage, analytics, crash reporting, app check | https://firebase.google.com/support/privacy |
| Google Gemini | AI-powered translations and explanations | https://policies.google.com/privacy |
| FreeDict | Offline dictionary data (open-source, no tracking) | https://freedict.org |

## Data deletion

You can delete your account and all cloud data at any time from **Account and settings > Delete account and cloud data**. This permanently removes your Firebase account, cloud vocabulary, profile, and profile photo. Local data on your device is also cleared.

You can also delete individual entries from the Library. Deleted entries show an undo option briefly, allowing you to restore them before they are permanently removed.

You can export your vocabulary as JSON before deleting.

## Children's privacy

Stackit is not directed at children under 13. We do not knowingly collect information from children.

## Changes to this policy

If we update this policy, the "Last updated" date at the top will be revised. Continued use of the app after changes constitutes acceptance of the updated policy.

## Contact

If you have questions about this privacy policy, contact us at:

**Email:** khalidona.bk@gmail.com

## Open source

Stackit is released under the GNU General Public License v3.0. The full source code is available on GitHub.
