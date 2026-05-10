# Wine Manager 🍷

A privacy-focused iOS app for managing your personal wine collection. Store, organize, and track your wines entirely on your device - no cloud storage, no data sharing, no tracking.

![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![AI Powered](https://img.shields.io/badge/Built%20with-GitHub%20Copilot-purple.svg)
![Version](https://img.shields.io/badge/Version-3.0-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 🤖 Built with AI

**This entire application was developed using GitHub Copilot.** Every line of code, from the initial project structure to the final implementation, was generated through AI assistance. No traditional manual coding was performed by human developers - this project represents a complete demonstration of AI-powered software development capabilities.

## Features

### ✨ AI-Powered Wine Enrichment (New in v3.0)
- **✨ AI Fill Button**: Automatically look up and fill in missing wine details with a single tap — powered by OpenAI with live web search
- **Smart Field Detection**: AI only suggests values for fields that are empty, never overwriting data you've already entered
- **Per-Field Preview**: Review every AI suggestion before applying — check or uncheck individual fields in a preview screen
- **Web Sources**: See exactly which web pages the AI used, with tappable links to verify information
- **Fields Enriched**: Producer, vintage, grapes, country, region, sub-region, type, category, alcohol, drink window, best-before year, tasting notes, and average market price
- **Secure Key Storage**: Your OpenAI API key is stored exclusively in the iOS Keychain — never in plain text
- **Bring Your Own Key**: Uses your personal OpenAI API key — no subscription, no middleman, full control

### 🍾 Wine Collection Management
- **Complete Wine Details**: Store name, producer, vintage, alcohol content, region, type, and more
- **Photo Support**: Take photos of wine labels or select from your photo library
- **Smart Categories**: Organize by Red, White, Rosé, Sparkling, Dessert, and Port wines
- **Quantity Tracking**: Monitor your wine inventory with easy consume functionality

### 🗂️ Organisation & Search
- **Advanced Sorting**: Sort by any field including drink dates and best before dates
- **Smart Search**: Find wines quickly with real-time search
- **Regional Classification**: Comprehensive wine regions database with autocomplete
- **Custom Storage Locations**: Track where you store each wine

### 📊 Collection Overview
- **Visual Dashboard**: See your collection at a glance
- **Total Statistics**: Track total bottles, volume, and value
- **Grouped Views**: Organize by category, region, vintage, or custom criteria

### 📱 Modern iOS Experience
- **Native SwiftUI Interface**: Beautiful, responsive design
- **Dark Mode Support**: Seamless light/dark mode switching
- **iPad Optimized**: Full iPad support with adaptive layouts
- **Accessibility**: VoiceOver and accessibility features supported

### 🔒 Privacy First
- **Local Storage Only**: All data stays on your device using Core Data
- **No Analytics**: Zero tracking or data collection
- **Keychain Security**: Sensitive credentials stored in the iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Optional AI**: The AI feature is entirely opt-in and requires your own API key

### 📄 Import/Export
- **Data Backup**: Export your collection for safekeeping
- **Data Portability**: Import previously exported data
- **Print Support**: Generate beautiful printable wine lists

## Technical Details

### Requirements
- iOS 18.0 or later
- iPhone or iPad
- Xcode 16.0+ (for development)

### Architecture
- **Framework**: SwiftUI with UIKit components
- **Database**: Core Data for local storage
- **Image Processing**: Vision framework for label text recognition
- **AI Integration**: OpenAI Responses API (`gpt-4.1`) with `web_search_preview` tool
- **Secure Storage**: iOS Keychain for API key storage (`Security` framework)
- **No External Swift Packages**: Pure iOS SDK implementation

### Privacy & Security
- **Local Data Storage**: Uses iOS Core Data framework
- **Device Encryption**: Leverages iOS built-in encryption
- **Keychain for Secrets**: API key stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Opt-in Network Use**: Network is only used when you explicitly tap ✨ AI Fill
- **GDPR/CCPA Compliant**: Privacy-by-design architecture

## Installation

### App Store
*Coming Soon* - Wine Manager will be available on the iOS App Store.

### Development Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/dlempen/SimpleWineManager.git
   cd SimpleWineManager
   ```

2. Open in Xcode:
   ```bash
   open SimpleWineManager.xcodeproj
   ```

3. Build and run on your device or simulator

## Project Structure

```
SimpleWineManager/
├── SimpleWineManager/          # Main app source code
│   ├── AddWineView.swift      # Wine entry interface
│   ├── ContentView.swift     # Main collection view
│   ├── WineDetailView.swift  # Wine details and editing
│   ├── SettingsView.swift    # App settings
│   ├── PrintView.swift       # Print functionality
│   ├── WineRegions.swift     # Wine regions database
│   ├── SuggestionProvider.swift # Autocomplete system
│   └── Assets.xcassets/      # App icons and images
├── SimpleWineManager.xcodeproj/ # Xcode project files
└── Documentation/            # Project documentation
```

## Development

### Version History
- **v3.0** (Current): AI-powered wine enrichment via OpenAI, Keychain API key storage, simplified AI UX
- **v2.8**: Statistics performance optimisation, advanced search improvements
- **v2.7**: Grapes field integration, bottle size unit conversion
- **v2.6**: Print support, UI refinements
- **v2.5**: Advanced search filters
- **v2.4**: CSV import/export, data portability
- **v2.3**: Improved UI consistency and search capabilities
- **v2.2**: Enhanced wine classification system
- **v2.1**: Core functionality and data model

### Contributing
This is a personal project, but suggestions and feedback are welcome through GitHub Issues.

### Building for Release
Use the provided build scripts:
```bash
./build_for_appstore.sh  # Prepare for App Store submission
./pre_submission_check.sh # Validate before submission
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

Need help or found a bug? Get support through:
- **Issues & Bug Reports**: [GitHub Issues](https://github.com/dlempen/SimpleWineManager/issues)
- **Full Support Guide**: [SUPPORT.md](SUPPORT.md)
- **Feature Requests**: [Request a Feature](https://github.com/dlempen/SimpleWineManager/issues/new)

## Contact

**Developer**: Dieter Lempen  
**GitHub**: [@dlempen](https://github.com/dlempen)  
**App Store**: Wine Manager (Coming Soon)  
**Support**: [GitHub Issues](https://github.com/dlempen/SimpleWineManager/issues)

## Privacy Policy

Wine Manager is built with privacy as a core principle. Read our complete [Privacy Policy](Privacy_Policy.md) for detailed information about data handling.

---

**Wine Manager - Keep your wine collection private and secure.**