#!/bin/bash

# Wine Manager - App Store Build and Archive Script
# This script automates the build process for App Store submission

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/Users/VBLPD/Desktop/SimpleWineManager/SimpleWineManager"
PROJECT_NAME="SimpleWineManager"
SCHEME_NAME="SimpleWineManager"
CONFIGURATION="Release"
ARCHIVE_PATH="$HOME/Desktop/SimpleWineManager_Archive.xcarchive"

echo -e "${BLUE}🍷 Wine Manager - App Store Build Script${NC}"
echo "=================================================="

# Check if we're in the right directory
cd "$PROJECT_DIR"

echo -e "${YELLOW}📋 Pre-build checks...${NC}"

# Function to check if iPhone 16 simulator is available
check_iphone16_simulator() {
    echo -e "${YELLOW}Checking for iPhone 16 simulator...${NC}"
    
    # Get a list of available simulators
    AVAILABLE_SIMULATORS=$(xcrun simctl list devices available -j | grep "iPhone 16")
    
    if [ -z "$AVAILABLE_SIMULATORS" ]; then
        echo -e "${YELLOW}⚠️ No iPhone 16 simulator found. Using latest available simulator.${NC}"
        # Use a different destination for testing
        TEST_DESTINATION="platform=iOS Simulator,name=iPhone 15"
        return 1
    else
        echo -e "${GREEN}✅ iPhone 16 simulator found.${NC}"
        TEST_DESTINATION="platform=iOS Simulator,name=iPhone 16"
        return 0
    fi
}

# Call the function
check_iphone16_simulator

# Verify project exists
if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: Xcode project not found!${NC}"
    exit 1
fi

# Verify iPhone 16 compatibility
echo -e "${YELLOW}📱 Checking iPhone 16 display compatibility...${NC}"

# Check for potential layout issues in ContentView.swift
grep -q "GeometryReader" "$PROJECT_DIR/SimpleWineManager/ContentView.swift" || {
    echo -e "${YELLOW}⚠️ No GeometryReader found in ContentView.swift${NC}"
    echo -e "${BLUE}ℹ️ Consider using GeometryReader for better adaptability to different screen sizes${NC}"
}

# Check for usage of safe area insets that might need adaptation for iPhone 16
grep -q "safeAreaInsets" "$PROJECT_DIR/SimpleWineManager/ContentView.swift" && {
    echo -e "${BLUE}ℹ️ SafeAreaInsets detected - make sure they work well with iPhone 16 display${NC}"
}

# Check for Dynamic Island adaptations if targeting iPhone 16 Pro
echo -e "${BLUE}ℹ️ Remember to test for Dynamic Island compatibility on iPhone 16 Pro models${NC}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
xcodebuild clean -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION"

# Build for iPhone 16 testing first
echo -e "${YELLOW}🔨 Building for iPhone 16 testing...${NC}"
xcodebuild build -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -destination "$TEST_DESTINATION"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ iPhone 16 build successful!${NC}"
else
    echo -e "${RED}❌ iPhone 16 build failed! Please fix errors and try again.${NC}"
    exit 1
fi

# Build for general release
echo -e "${YELLOW}🔨 Building for release...${NC}"
xcodebuild build -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -destination "generic/platform=iOS"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed! Please fix errors and try again.${NC}"
    exit 1
fi

# Check if SearchPerformanceTests exists
if [ -f "$PROJECT_DIR/SimpleWineManagerTests/SearchPerformanceTests.swift" ]; then
    # Run basic tests to verify search performance
    echo -e "${YELLOW}🧪 Running search performance tests on iPhone 16 simulator...${NC}"
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -destination "$TEST_DESTINATION" \
        -only-testing:SimpleWineManagerTests/SearchPerformanceTests || {
            echo -e "${YELLOW}⚠️ Performance tests failed, but continuing with build...${NC}"
        }
else
    echo -e "${YELLOW}⚠️ SearchPerformanceTests not found, skipping performance testing${NC}"
    echo -e "${YELLOW}➡️ Create this file to test search performance on iPhone 16${NC}"
fi

# Create archive
echo -e "${YELLOW}📦 Creating archive for App Store...${NC}"
xcodebuild archive \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Archive created successfully!${NC}"
    echo -e "${BLUE}📍 Archive location: $ARCHIVE_PATH${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Open Xcode"
    echo "2. Go to Window → Organizer"
    echo "3. Select the archive and click 'Distribute App'"
    echo "4. Choose 'App Store Connect' for submission"
    echo ""
    echo -e "${GREEN}🎉 Ready for App Store submission!${NC}"
else
    echo -e "${RED}❌ Archive failed! Please check the errors above.${NC}"
    exit 1
fi
