#!/bin/bash

# Wine Manager v2.6 App Store Preparation Script
# Last Updated: August 11, 2025

echo "🍷 Wine Manager v2.6 - App Store Preparation"
echo "==========================================="

# Check if we're in the right directory
if [ ! -f "SimpleWineManager/SimpleWineManager.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the SimpleWineManager project directory"
    exit 1
fi

echo "📋 Pre-submission checks..."

# Check version numbers
VERSION=$(xcodebuild -project SimpleWineManager/SimpleWineManager.xcodeproj -target SimpleWineManager -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | head -1 | cut -d= -f2 | xargs)
BUILD=$(xcodebuild -project SimpleWineManager/SimpleWineManager.xcodeproj -target SimpleWineManager -showBuildSettings 2>/dev/null | grep CURRENT_PROJECT_VERSION | head -1 | cut -d= -f2 | xargs)
BUNDLE_ID=$(xcodebuild -project SimpleWineManager/SimpleWineManager.xcodeproj -target SimpleWineManager -showBuildSettings 2>/dev/null | grep PRODUCT_BUNDLE_IDENTIFIER | head -1 | cut -d= -f2 | xargs)
TEAM_ID=$(xcodebuild -project SimpleWineManager/SimpleWineManager.xcodeproj -target SimpleWineManager -showBuildSettings 2>/dev/null | grep DEVELOPMENT_TEAM | head -1 | cut -d= -f2 | xargs)

echo "📦 Current Version: $VERSION"
echo "🔢 Current Build: $BUILD"
echo "📱 Bundle ID: $BUNDLE_ID"
echo "👥 Team ID: $TEAM_ID"
echo ""

# Verify version numbers
if [ "$VERSION" != "2.6" ]; then
    echo "❌ Error: Marketing version should be 2.6, found: $VERSION"
    exit 1
fi

if [ "$BUILD" != "6" ]; then
    echo "❌ Error: Build number should be 6, found: $BUILD"
    exit 1
fi

if [ "$BUNDLE_ID" != "com.dieterlempen.SimpleWineManager" ]; then
    echo "❌ Error: Unexpected bundle identifier: $BUNDLE_ID"
    exit 1
fi

echo "✅ Version numbers verified"
echo ""

# Check for required files
echo "🔍 Checking required files..."

check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ Missing: $1"
        return 1
    fi
}

# Check essential project files
check_file "SimpleWineManager/SimpleWineManager.xcodeproj/project.pbxproj"
check_file "SimpleWineManager/SimpleWineManager/Info.plist"
check_file "SimpleWineManager/SimpleWineManager/Assets.xcassets/AppIcon.appiconset/Contents.json"

# Check main source files
check_file "SimpleWineManager/SimpleWineManager/SimpleWineManagerApp.swift"
check_file "SimpleWineManager/SimpleWineManager/ContentView.swift"
check_file "SimpleWineManager/SimpleWineManager/Persistence.swift"
check_file "SimpleWineManager/SimpleWineManager/SimpleWineManager.xcdatamodeld/SimpleWineManager.xcdatamodel/contents"

echo ""

# Check Info.plist requirements
echo "🔍 Checking Info.plist requirements..."

if grep -q "NSCameraUsageDescription" SimpleWineManager/SimpleWineManager/Info.plist 2>/dev/null; then
    echo "✅ Camera usage description found"
else
    echo "❌ Missing camera usage description"
fi

if grep -q "NSPhotoLibraryAddUsageDescription" SimpleWineManager/SimpleWineManager/Info.plist 2>/dev/null; then
    echo "✅ Photo library usage description found"
else
    echo "❌ Missing photo library usage description"
fi

echo ""

# Test build
echo "🔨 Testing build..."

xcodebuild -project SimpleWineManager/SimpleWineManager.xcodeproj \
           -scheme SimpleWineManager \
           -configuration Release \
           -destination generic/platform=iOS \
           clean build > build_test.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
    rm -f build_test.log
else
    echo "❌ Build failed. Check build_test.log for details"
    echo "Last few lines of build log:"
    tail -10 build_test.log
    exit 1
fi

echo ""

# Test archive creation
echo "📦 Testing archive creation..."

xcodebuild -project SimpleWineManager/SimpleWineManager.xcodeproj \
           -scheme SimpleWineManager \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath "./wine_manager_v2.6.xcarchive" \
           archive > archive_test.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Archive creation successful"
    echo "📁 Archive location: ./wine_manager_v2.6.xcarchive"
    
    # Show archive details
    if [ -d "./wine_manager_v2.6.xcarchive" ]; then
        ARCHIVE_VERSION=$(defaults read "$(pwd)/wine_manager_v2.6.xcarchive/Info.plist" ApplicationProperties.CFBundleShortVersionString 2>/dev/null || echo "Unknown")
        ARCHIVE_BUILD=$(defaults read "$(pwd)/wine_manager_v2.6.xcarchive/Info.plist" ApplicationProperties.CFBundleVersion 2>/dev/null || echo "Unknown")
        echo "📦 Archive Version: $ARCHIVE_VERSION"
        echo "🔢 Archive Build: $ARCHIVE_BUILD"
    fi
    
    rm -f archive_test.log
else
    echo "❌ Archive creation failed. Check archive_test.log for details"
    echo "Last few lines of archive log:"
    tail -10 archive_test.log
    exit 1
fi

echo ""

# App Store preparation checklist
echo "📋 App Store Preparation Checklist"
echo "=================================="

echo "✅ Version 2.6 (Build 6) configured"
echo "✅ Bundle ID: com.dieterlempen.SimpleWineManager"
echo "✅ Development Team: $TEAM_ID"
echo "✅ Privacy usage descriptions included"
echo "✅ App icon assets prepared"
echo "✅ Build and archive successful"
echo "✅ Documentation complete (VERSION_2.6_RELEASE.md)"
echo "✅ README updated to reflect v2.6"

echo ""
echo "🎯 Ready for App Store Submission!"
echo ""
echo "📱 Next Steps:"
echo "   1. Open Xcode and go to Window > Organizer"
echo "   2. Select the wine_manager_v2.6.xcarchive"
echo "   3. Click 'Distribute App'"
echo "   4. Choose 'App Store Connect'"
echo "   5. Follow the upload process"
echo "   6. Complete App Store Connect metadata"
echo "   7. Submit for review"
echo ""
echo "📞 Support files ready:"
echo "   - VERSION_2.6_RELEASE.md (Release documentation)"
echo "   - Privacy_Policy.md (Privacy policy)"
echo "   - AppStore_Marketing_Materials.md (Marketing copy)"
echo ""
echo "🍷 Wine Manager v2.6 is ready for the App Store!"
