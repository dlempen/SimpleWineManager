# TestFlight External Review Submission Guide

## Wine Manager App - External Testing Review Information

### Test Information (What to Test)
```
Wine Manager is a personal wine collection organizer that allows users to catalog and manage their wine inventory with photos and detailed information.

CORE FEATURES TO TEST:
• Wine Entry Management: Add, edit, and delete wine entries with details (name, vintage, region, notes)
• Photo Integration: Take photos of wine labels using camera or select from photo library
• Wine Collection View: Browse and search through wine collection with visual wine cards
• Print Functionality: Generate printable wine collection lists in PDF format
• Data Management: Import/export wine collection data for backup purposes
• Universal Support: Test on both iPhone and iPad devices

TESTING SCENARIOS:
1. Add new wine entry with photo from camera
2. Add new wine entry with photo from photo library
3. Edit existing wine details and photos
4. Search and filter wine collection
5. Print wine collection to PDF
6. Import/export wine data
7. Test app orientation changes (portrait/landscape)
8. Verify app works offline (no internet required)
```

### Test Notes (Beta Testing Instructions)
```
IMPORTANT SETUP NOTES:
• App requires camera permission for taking wine label photos
• Photo library access needed for selecting existing wine label images
• All wine data is stored locally on your device - no cloud sync
• No internet connection required for app functionality
• App supports both iPhone and iPad with adaptive layouts

KNOWN LIMITATIONS:
• iOS 18.0+ required for full functionality
• Print feature requires AirPrint-compatible printer or PDF export
• Camera permission must be granted for photo capture features
• Photo library permission must be granted for photo selection

FEEDBACK AREAS:
• UI/UX on different device sizes (iPhone/iPad)
• Performance with large wine collections (100+ entries)
• Print formatting and layout quality
• Camera and photo library integration
• Data import/export functionality
• App stability and crash reporting
```

### App Review Information (For Apple Reviewers)
```
REVIEWER CONTACT INFORMATION:
Developer: Dieter Lempen
Development Team: JXYNZ48YKP

APP FUNCTIONALITY:
Wine Manager is a utility app for personal wine collection management. It allows users to:
- Catalog wines with photos, vintage information, and tasting notes
- Organize and search their wine collection
- Generate printable wine lists
- Import/export wine data for backup

PRIVACY & PERMISSIONS:
- Camera: Required for taking wine label photos
- Photo Library: Required for selecting wine label images
- No data collection, analytics, or third-party services
- All data stored locally using Core Data
- No network connectivity required

TESTING INSTRUCTIONS FOR REVIEWERS:
1. Grant camera and photo library permissions when prompted
2. Add 2-3 wine entries with photos to test core functionality
3. Test print functionality (PDF export)
4. Verify app works in airplane mode (offline functionality)
5. Test on both iPhone and iPad if available
```

### Demo Account Information
```
No demo account required - app works immediately without setup or registration.
App is fully functional in offline mode.
```

### App Store Connect Submission Steps

1. **Navigate to TestFlight**:
   - Go to App Store Connect → Your App → TestFlight tab
   - Select your build (Version 2.2, Build 3)

2. **Submit for External Review**:
   - Click "Submit for Review" button
   - Fill in the test information above
   - Add test notes for beta testers
   - Provide reviewer contact information

3. **Review Timeline**:
   - Expected review time: 24-48 hours
   - You'll receive email notification when approved/rejected
   - Once approved, build becomes available for external testing

### Post-Approval Actions

Once your build is approved for external testing:

1. **Create External Test Groups**:
   - Navigate to TestFlight → Groups
   - Create groups like "Wine Enthusiasts", "Beta Testers", etc.

2. **Add External Testers**:
   - Add tester email addresses to groups
   - Send TestFlight invitations
   - Provide testing guidelines and feedback collection method

3. **Monitor Testing**:
   - Track tester adoption and feedback
   - Monitor crash reports and performance metrics
   - Prepare for App Store submission based on feedback

### Ready-to-Copy Text for App Store Connect

**Test Information Field:**
```
Wine Manager allows users to organize their personal wine collection with photos and detailed information. Test adding wine entries, taking/selecting photos, searching the collection, and using the print functionality. Focus on camera integration, photo library access, and PDF generation features.
```

**Test Notes Field:**
```
Requires camera and photo library permissions. All data stored locally. No internet required. Test on iPhone and iPad. Print feature generates PDF. Import/export functionality for data backup. App supports iOS 18.0+.
```

This information is ready for your external TestFlight review submission!
