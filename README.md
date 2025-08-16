# Wine Manager 🍷

A privacy-focused iOS app for managing your personal wine collection. Store, organize, and track your wines entirely on your device - no cloud storage, no data sharing, no tracking.

![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![AI Powered](https://img.shields.io/badge/Built%20with-GitHub%20Copilot-purple.svg)
![Version](https://img.shields.io/badge/Version-2.7%20Dev-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 🤖 Built with AI

**This entire application was developed using GitHub Copilot.** Every line of code, from the initial project structure to the final implementation, was generated through AI assistance. No traditional manual coding was performed by human developers - this project represents a complete demonstration of AI-powered software development capabilities.

## Features

### 🍾 Wine Collection Management
- **Complete Wine Details**: Store name, producer, vintage, alcohol content, region, type, and more
- **Photo Support**: Take photos of wine labels or select from your photo library
- **Smart Categories**: Organize by Red, White, Rosé, Sparkling, Dessert, and Port wines
- **Quantity Tracking**: Monitor your wine inventory with easy consume functionality

### 🗂️ Organization & Search
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
- **No Internet Required**: Works completely offline
- **No Analytics**: Zero tracking or data collection
- **No Third-Party Services**: No external dependencies

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
- **No External Dependencies**: Pure iOS SDK implementation

### Privacy & Security
- **Local Data Storage**: Uses iOS Core Data framework
- **Device Encryption**: Leverages iOS built-in encryption
- **No Network Communication**: Zero internet connectivity
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
- **v2.4** (In Development): New features and improvements coming soon
- **v2.3** (Current - App Store): Improved UI consistency and search capabilities
- **v2.2**: Enhanced wine classification system
- **v2.1**: Core functionality and data model
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