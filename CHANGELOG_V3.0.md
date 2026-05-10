# Changelog — v3.0

## What's New in v3.0

### ✨ AI-Powered Wine Enrichment
Wine Manager 3.0 introduces **AI Fill** — a one-tap feature that automatically looks up and fills in missing wine details using OpenAI's `gpt-4.1` model with live web search.

**How it works:**
1. Enter at least a wine name or producer in Add Wine or Edit Wine
2. Tap the **✨ AI Fill** button in the toolbar
3. The AI searches the web and returns suggestions for all empty fields
4. A preview screen lets you review each suggestion individually
5. Check or uncheck fields, then tap **Apply** to copy only what you want

**Fields that can be enriched:**
- Producer / winery
- Vintage year
- Grape variety / blend
- Country and region
- Sub-region / appellation
- Wine type and category
- Alcohol content
- Drink-from and best-before years
- Tasting notes / remarks
- Average market price (in your chosen currency)

**Web sources:** The preview screen shows the web pages the AI cited, with tappable links so you can verify any detail.

---

### 🔐 Keychain Storage for API Key
The OpenAI API key is now stored exclusively in the **iOS Keychain** with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — it is never written to `UserDefaults` or any plain-text store.

- Automatic **migration** from any legacy `UserDefaults` value on first launch after update
- Users upgrading from a build where the key was stored in `UserDefaults` will have it silently migrated — no need to re-enter it

---

### 🛠 Simplified AI Settings
- Removed Anthropic Claude and Google Gemini provider options — **OpenAI only** for a simpler, more reliable experience
- Removed model selector, custom base URL, and web search toggle — the best defaults are applied automatically
- The AI section in Settings now shows a single **API Key** field with a plain-English footer explaining where to get a key and how it is stored

---

### 📖 Updated User Manual
- New **"AI Fill — Auto-complete Wine Details"** section in the in-app manual covering:
  - What the feature does and which fields it enriches
  - Step-by-step usage guide
  - Step-by-step instructions for obtaining an OpenAI API key
  - Notes on cost (fractions of a cent per lookup) and free starter credits
- New AI tip added to the tips strip at the bottom of the manual

---

### 🐛 Bug Fixes
- **AI Fill button invisible on real iPhone**: The button was previously hidden when no API key was configured, making it impossible to discover the feature on a fresh device. The button is now always visible; tapping it without a key shows a prompt directing the user to Settings.

---

## Technical Changes

| Area | Change |
|---|---|
| `AIService.swift` | Removed `anthropic` / `gemini` enum cases and their dead switch branches |
| `AIService.swift` | Endpoint: `POST /v1/responses`, model `gpt-4.1`, tool `web_search_preview` |
| `KeychainHelper.swift` | New file — `save`, `read`, `delete` wrappers over `Security` framework |
| `SettingsStore.swift` | `aiApiKey` `didSet` writes to Keychain; `init` reads from Keychain with UserDefaults migration |
| `SettingsView.swift` | Removed provider Picker; updated AI section footer |
| `AddWineView.swift` | AI Fill button always rendered; prompts for key if absent |
| `WineDetailView.swift` | AI Fill button always rendered; prompts for key if absent |
| `ManualView.swift` | Added AI Fill manual section and tips entry |
