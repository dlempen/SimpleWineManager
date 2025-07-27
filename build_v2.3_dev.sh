#!/bin/bash

# Wine Manager v2.3 Development Build Script
# Last Updated: July 20, 2025

echo "🍷 Wine Manager v2.3 Development Build"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "SimpleWineManager.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the SimpleWineManager project directory"
    exit 1
fi

echo "📋 Pre-build checks..."

# Check version numbers
VERSION=$(grep -m1 "MARKETING_VERSION" SimpleWineManager.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
BUILD=$(grep -m1 "CURRENT_PROJECT_VERSION" SimpleWineManager.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')

echo "📦 Current Version: $VERSION"
echo "🔢 Current Build: $BUILD"

if [ "$VERSION" != "2.3" ]; then
    echo "⚠️  Warning: Marketing version is not 2.3"
    echo "   Please update manually in Xcode:"
    echo "   1. Open project in Xcode"
    echo "   2. Select target 'SimpleWineManager'"
    echo "   3. Change Version to '2.3' in General tab"
fi

if [ "$BUILD" != "4" ]; then
    echo "⚠️  Warning: Build number is not 4"
    echo "   Please update manually in Xcode:"
    echo "   1. Open project in Xcode"
    echo "   2. Select target 'SimpleWineManager'" 
    echo "   3. Change Build to '4' in General tab"
fi

# Check for common issues
echo "🔍 Checking for potential issues..."

# Check app icons
if [ ! -f "SimpleWineManager/Assets.xcassets/AppIcon.appiconset/AppIcon.png" ]; then
    echo "❌ Missing main app icon"
else
    echo "✅ App icons present"
fi

# Check for clean build
echo "🧹 Cleaning previous builds..."
if command -v xcodebuild &> /dev/null; then
    xcodebuild clean -project SimpleWineManager.xcodeproj -scheme SimpleWineManager
    echo "✅ Clean completed"
else
    echo "⚠️  Xcodebuild not found - clean manually in Xcode"
fi

# Build for debugging
echo "🔨 Building for debug..."
if command -v xcodebuild &> /dev/null; then
    xcodebuild build -project SimpleWineManager.xcodeproj -scheme SimpleWineManager -configuration Debug
    
    if [ $? -eq 0 ]; then
        echo "✅ Debug build successful!"
    else
        echo "❌ Debug build failed"
        exit 1
    fi
else
    echo "⚠️  Xcodebuild not found - build manually in Xcode"
fi

echo ""
echo "🎉 Development environment ready for v2.3!"
echo "💡 Next steps:"
echo "   1. Update version numbers in Xcode if needed"
echo "   2. Choose features to implement"
echo "   3. Start coding!"
echo ""
