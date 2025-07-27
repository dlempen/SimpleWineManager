# Contributing to Wine Manager

Thank you for your interest in contributing to Wine Manager! This document provides guidelines for contributing to the project.

## Getting Started

### Prerequisites
- Xcode 16.0 or later
- iOS 18.0+ device or simulator
- macOS Ventura or later

### Setup
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/SimpleWineManager.git
   cd SimpleWineManager
   ```
3. Open the project in Xcode:
   ```bash
   open SimpleWineManager.xcodeproj
   ```

## Development Workflow

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature development branches
- `feature/version-*` - Version-specific feature branches

### Making Changes
1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the coding standards below

3. Test your changes thoroughly:
   - Build and run on iOS Simulator
   - Test on physical device if possible
   - Verify all existing functionality still works

4. Commit your changes:
   ```bash
   git add .
   git commit -m "feat: description of your changes"
   ```

5. Push and create a pull request:
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### Swift Style Guide
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain consistency with existing code style
- Use meaningful variable and function names
- Add comments for complex logic

### Code Organization
- Keep views focused and single-purpose
- Use proper separation of concerns
- Follow the existing project structure
- Use Core Data for persistence consistently

### Privacy First
- Ensure all data remains local to the device
- No network requests or external services
- Maintain the privacy-focused architecture

## Testing

### Before Submitting
- [ ] App builds without warnings or errors
- [ ] All existing features continue to work
- [ ] New features work as expected
- [ ] UI is responsive and accessible
- [ ] Privacy principles are maintained

### Manual Testing Areas
- Wine collection management (add, edit, delete)
- Search and filtering functionality
- Photo capture and storage
- Data import/export
- Print functionality
- Settings and preferences

## Pull Request Guidelines

### PR Title Format
Use conventional commit format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `style:` for UI/styling changes
- `refactor:` for code refactoring
- `test:` for adding tests

### PR Description
Include:
- Clear description of changes
- Screenshots for UI changes
- Testing performed
- Any breaking changes
- Related issue numbers

### Review Process
1. All PRs require review before merging
2. Address feedback promptly
3. Keep PRs focused and reasonably sized
4. Update documentation if needed

## Issue Reporting

### Bug Reports
Include:
- iOS version and device model
- App version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

### Feature Requests
Include:
- Clear description of the feature
- Use case and rationale
- Mockups or examples if helpful
- Consider privacy implications

## Architecture Guidelines

### Core Principles
- **Privacy First**: All data stays on device
- **Native iOS**: Use iOS frameworks and patterns
- **Performance**: Efficient Core Data usage
- **Accessibility**: Support VoiceOver and accessibility features
- **Offline-First**: No internet dependencies

### Technical Stack
- **UI**: SwiftUI with UIKit integration where needed
- **Data**: Core Data for local storage
- **Images**: Local storage with Core Data
- **Export**: iOS document system integration

## Questions?

If you have questions about contributing, please:
1. Check existing issues and documentation
2. Create a discussion on GitHub
3. Contact the maintainer through GitHub

Thank you for helping make Wine Manager better! 🍷
