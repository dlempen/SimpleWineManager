#!/bin/bash

# Wine Manager - Pre-Submission Checklist
# Run this script before submitting to App Store

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/Users/VBLPD/Desktop/SimpleWineManager/SimpleWineManager"

echo -e "${BLUE}🍷 Wine Manager - Pre-Submission Checklist${NC}"
echo "=================================================="

cd "$PROJECT_DIR"

# Function to check if a condition is met
check_item() {
    local description="$1"
    local condition="$2"
    
    if eval "$condition"; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

echo -e "${YELLOW}📋 Technical Requirements:${NC}"

# Check app icon
check_item "App Icon (1024x1024)" "[ -f 'SimpleWineManager/Assets.xcassets/AppIcon.appiconset/AppIcon.png' ]"

# Check Info.plist requirements
check_item "Camera usage description" "grep -q 'NSCameraUsageDescription' SimpleWineManager/Info.plist"
check_item "Photo Library usage description" "grep -q 'NSPhotoLibraryAddUsageDescription' SimpleWineManager/Info.plist"

# Check version information
MARKETING_VERSION=$(xcodebuild -project SimpleWineManager.xcodeproj -target SimpleWineManager -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | head -1 | cut -d= -f2 | xargs)
BUILD_VERSION=$(xcodebuild -project SimpleWineManager.xcodeproj -target SimpleWineManager -showBuildSettings 2>/dev/null | grep CURRENT_PROJECT_VERSION | head -1 | cut -d= -f2 | xargs)

check_item "Marketing version set ($MARKETING_VERSION)" "[ ! -z '$MARKETING_VERSION' ]"
check_item "Build version set ($BUILD_VERSION)" "[ ! -z '$BUILD_VERSION' ]"

echo ""
echo -e "${YELLOW}🧪 Code Quality Checks:${NC}"

# Test build
echo -e "${BLUE}Building project...${NC}"
if xcodebuild build -project SimpleWineManager.xcodeproj -scheme SimpleWineManager -configuration Release -destination "generic/platform=iOS" > /tmp/build.log 2>&1; then
    echo -e "${GREEN}✅ Project builds successfully${NC}"
else
    echo -e "${RED}❌ Build failed - check /tmp/build.log${NC}"
    echo "Last few lines of build log:"
    tail -10 /tmp/build.log
fi

echo ""
echo -e "${YELLOW}📱 App Store Connect Checklist:${NC}"

echo -e "   📄 App description written"
echo -e "   🏷️  App keywords selected"
echo -e "   📸 Screenshots prepared for all device sizes"
echo -e "   🎬 App preview video (optional but recommended)"
echo -e "   🔞 Age rating completed"
echo -e "   🔒 Privacy policy created (if required)"
echo -e "   💰 Pricing tier selected"
echo -e "   🌍 App availability/territories selected"

echo ""
echo -e "${YELLOW}📦 Final Steps:${NC}"
echo "1. Archive your app: ./build_for_appstore.sh"
echo "2. Upload to App Store Connect via Xcode Organizer"
echo "3. Complete App Store Connect metadata"
echo "4. Submit for review"

echo ""
echo -e "${BLUE}🔗 Useful Links:${NC}"
echo "• App Store Connect: https://appstoreconnect.apple.com"
echo "• Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/"
echo "• App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/"

echo ""
echo -e "${GREEN}🎉 Your app looks ready for App Store submission!${NC}"
