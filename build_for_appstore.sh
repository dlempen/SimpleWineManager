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

# Verify project exists
if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: Xcode project not found!${NC}"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
xcodebuild clean -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION"

# Build for testing first
echo -e "${YELLOW}🔨 Building for testing...${NC}"
xcodebuild build -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -destination "generic/platform=iOS"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed! Please fix errors and try again.${NC}"
    exit 1
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
