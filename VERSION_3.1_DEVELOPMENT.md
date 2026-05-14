# Wine Manager — v3.1 Development Plan

**Branch:** `v3.1-development`
**Base:** `v3.0` tag (`15d8fcd`)
**Started:** 2026-05-10

---

## Goals for v3.1

v3.1 is a focused improvement release building on the AI foundation introduced in v3.0.
The main themes are **AI quality**, **UX polish**, and **stability**.

---

## Planned Features & Improvements

### 🤖 AI Enhancements
- [ ] **Model upgrade hook** — make the OpenAI model name a constant (`AIService.model`) so it can be updated in one place without touching the prompt logic
- [ ] **Retry on failure** — automatic single retry with exponential back-off when the API returns a transient error (timeout, 5xx)
- [ ] **Better empty-state messaging** — distinguish between "AI found nothing new" vs "all fields already filled" in the preview screen
- [ ] **Token usage logging** — log prompt/completion token counts to the console in DEBUG builds for cost awareness

### 🎨 UI / UX Polish
- [ ] **AI Fill loading overlay** — replace the `ProgressView` in the toolbar with a full-screen semi-transparent overlay and descriptive label ("Looking up wine details…") so it is clear the app is working
- [ ] **Haptic feedback** — light haptic on AI Fill button tap and on Apply
- [ ] **Source link previews** — show favicon + domain name instead of raw URL in the Sources section of AIPreviewView

### 🔒 Security
- [ ] **iCloud Keychain sync option** (opt-in setting) — store API key with `kSecAttrSynchronizable = true` so users don't have to re-enter it on a new device

### 🐛 Known Issues to Address
- [ ] Investigate whether `web_search_preview` sources are always populated when the model has sufficient context to answer without searching
- [ ] Verify `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` behaviour after device restart before first unlock

### 📋 Housekeeping
- [ ] Update `AppStore_Preparation_Checklist.md` to v3.x
- [ ] Archive old v2.x planning documents into `backups/`
- [ ] Update marketing version to `3.1` and bump build number in Xcode project settings

---

## Version Numbers

| Setting | Value |
|---|---|
| Marketing Version | 3.1 |
| Build Number | TBD (increment from v3.0 submission build) |
| Min iOS | 18.0 |
| Branch | `v3.1-development` |

---

## Definition of Done

- All planned items above checked off
- Zero Xcode errors or warnings on `Release` configuration
- Tested on at least one physical iPhone (not just Simulator)
- `CHANGELOG_V3.1.md` written
- Committed and tagged `v3.1`
- `v3.1-development` pushed to `origin`
