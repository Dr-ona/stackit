# Capture Validation Matrix

This document tracks manual device testing of the Stackit capture flow across
different apps and content types. Each row should be physically verified on a
real device before marking as complete.

## Test Matrix

### Browsers

| App | Content Type | PROCESS_TEXT | Share | Result | Notes |
|-----|-------------|-------------|-------|--------|-------|
| Chrome | Web page word | - | - | - | |
| Chrome | Web page phrase | - | - | - | |
| Chrome | PDF in browser | - | - | - | |
| Firefox | Web page word | - | - | - | |
| Edge | Web page word | - | - | - | |
| Samsung Internet | Web page word | - | - | - | |

### News & Reading

| App | Content Type | PROCESS_TEXT | Share | Result | Notes |
|-----|-------------|-------------|-------|--------|-------|
| Google News | Article headline | - | - | - | |
| Google News | Article body word | - | - | - | |
| Kindle app | Book text | - | - | - | |
| Google Play Books | Book text | - | - | - | |
| Pocket | Saved article word | - | - | - | |

### Social & Messaging

| App | Content Type | PROCESS_TEXT | Share | Result | Notes |
|-----|-------------|-------------|-------|--------|-------|
| WhatsApp | Chat message word | - | - | - | |
| Telegram | Message word | - | - | - | |
| Twitter/X | Tweet word | - | - | - | |
| Instagram | Caption word | - | - | - | |
| Facebook | Post word | - | - | - | |

### Productivity

| App | Content Type | PROCESS_TEXT | Share | Result | Notes |
|-----|-------------|-------------|-------|--------|-------|
| Google Docs | Document word | - | - | - | |
| Google Docs | Document phrase | - | - | - | |
| Microsoft Word | Document word | - | - | - | |
| Notion | Page word | - | - | - | |
| Obsidian | Note word | - | - | - | |
| Adobe Acrobat | PDF text | - | - | - | |
| WPS Office | Document word | - | - | - | |

### Email

| App | Content Type | PROCESS_TEXT | Share | Result | Notes |
|-----|-------------|-------------|-------|--------|-------|
| Gmail | Email body word | - | - | - | |
| Outlook | Email body word | - | - | - | |

### Other

| App | Content Type | PROCESS_TEXT | Share | Result | Notes |
|-----|-------------|-------------|-------|--------|-------|
| Google Translate | Translation text | - | - | - | |
| Dictionary app | Definition text | - | - | - | |
| Wikipedia | Article word | - | - | - | |

## How to Test

1. Open the target app and navigate to content with selectable text
2. Long-press to select a word or phrase
3. Tap **Understand with Stackit** in the text selection toolbar
4. Verify the capture sheet opens with the correct text
5. Check that the source app name is detected (when available)
6. Check that the surrounding sentence context is captured (when available)
7. Save the entry and verify it appears in the Library

## Known Limitations

- **PROCESS_TEXT** may not be available in all apps (some apps use custom
  text selection that does not expose the standard Android intent)
- **Share intent** works in more apps but requires the user to explicitly
  share text to Stackit
- **PDF text selection** varies by PDF reader — some render PDFs as images
  and do not support text selection
- **WebView-based apps** may not expose text through PROCESS_TEXT depending
  on how the web content is rendered
- **Protected content** (DRM, banking apps) will not allow text selection

## Physical Device Log

| Date | Device | Android Version | Build | Tester | Apps Tested |
|------|--------|----------------|-------|--------|-------------|
| - | - | - | - | - | - |
