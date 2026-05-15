# SimpleWineManager — Version 3.2 Development Plan

**Branch:** `v3.2-development`
**Base tag:** `v3.1`
**Marketing Version:** 3.2
**Build Number:** 1
**Started:** 2026-05-14

---

## 🎯 Goals for v3.2

Version 3.2 builds on the AI foundation of v3.1 and focuses on refinement,
usability improvements, and new user-facing features.

---

## ✅ Carried over from v3.1 (completed, stable)

- AI Fill using OpenAI Responses API (`gpt-4.1`, `web_search_preview`)
- Multi-source price search with automatic currency conversion (Frankfurter API)
- Per-source price breakdown and drinking window breakdown in AI preview
- All consulted web sources listed with tappable links
- Geo-filter for AI search (country picker with 30 countries + ISO codes)
- Average price rounded to 1 decimal, displayed with 2 decimal digits (e.g. 65.30)
- Keychain-backed API key storage

---

## 🔲 Planned for v3.2

> Items to be defined and prioritised. Add ideas below.

### Candidates

- [ ] **AI Fill — remember last suggestion**: Cache the last AI response so the
      user can re-open the preview without re-calling the API.
- [ ] **Wine notes / tasting log**: Allow adding timestamped tasting notes to
      individual wines.
- [ ] **Bulk AI Fill**: Run AI Fill on multiple selected wines in one go.
- [ ] **Improved statistics**: Charts for price distribution, vintage spread,
      grape variety breakdown.
- [ ] **Widgets**: Home screen widget showing a random wine from the cellar or
      today's drinking-window wines.
- [ ] **iCloud sync**: CloudKit-backed sync across devices.
- [ ] **CSV export improvements**: Include all v3.x fields (grapes, drinking
      window, remarks) in the export.

---

## 📁 Key files

| File | Purpose |
|---|---|
| `SimpleWineManager/AIService.swift` | AI enrichment, currency conversion |
| `SimpleWineManager/AIPreviewView.swift` | AI suggestion preview UI |
| `SimpleWineManager/SettingsStore.swift` | App-wide settings & Keychain |
| `SimpleWineManager/SettingsView.swift` | Settings UI |
| `SimpleWineManager/AddWineView.swift` | Add wine form |
| `SimpleWineManager/WineDetailView.swift` | Wine detail & edit view |
| `SimpleWineManager/ContentView.swift` | Main wine list |

---

## 📋 Changelog (in progress)

### 3.2.0 (build 1)
- Version bump from 3.1 → 3.2
- Development branch `v3.2-development` created from tag `v3.1`
