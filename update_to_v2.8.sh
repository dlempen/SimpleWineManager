#!/bin/zsh

# Wine Manager - Version Update Script for v2.8
# This script safely updates version numbers in the Xcode project file
# and performs setup tasks for v2.8 development

PROJECT_FILE="SimpleWineManager/SimpleWineManager.xcodeproj/project.pbxproj"
NEW_VERSION="2.8"
NEW_BUILD="1"

# Text colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Updating Wine Manager to version $NEW_VERSION build $NEW_BUILD${NC}"

# Backup the original project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Update marketing version (2.7 -> 2.8)
sed -i '' "s/MARKETING_VERSION = 2\.7;/MARKETING_VERSION = $NEW_VERSION;/g" "$PROJECT_FILE"

# Update build version (9 -> 1) 
sed -i '' "s/CURRENT_PROJECT_VERSION = 9;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PROJECT_FILE"

# Verify the project file is still valid
if xcodebuild -list -project SimpleWineManager/SimpleWineManager.xcodeproj > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Project file updated successfully!${NC}"
    echo -e "📋 Version: $NEW_VERSION"
    echo -e "🏗️  Build: $NEW_BUILD"
    
    # Show updated version numbers
    echo ""
    echo -e "${BLUE}🔍 Version numbers in project file:${NC}"
    grep -n "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | head -6
    
    # Clean up backup
    rm "${PROJECT_FILE}.backup"
    
    # Check if we're on the right branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ "$CURRENT_BRANCH" == "v2.8-development-fresh" ]]; then
        echo -e "\n${GREEN}✅ Working on v2.8-development-fresh branch${NC}"
    else
        echo -e "\n${YELLOW}⚠️ Not on v2.8-development-fresh branch! Current branch: $CURRENT_BRANCH${NC}"
        echo -e "Consider switching with: ${BLUE}git checkout v2.8-development-fresh${NC}"
    fi
    
    # Update build_for_appstore.sh script to include iPhone 16 compatibility checks
    echo -e "\n${BLUE}📝 Updating build script for iPhone 16 compatibility checks...${NC}"
    if grep -q "iPhone 16" "build_for_appstore.sh"; then
        echo -e "${GREEN}✅ build_for_appstore.sh already contains iPhone 16 compatibility checks${NC}"
    else
        echo -e "${YELLOW}⚠️ iPhone 16 compatibility checks not found in build_for_appstore.sh${NC}"
        echo -e "Consider adding them manually to ensure iPhone 16 compatibility"
    fi
    
    # Create or verify V2.8_SETUP_COMPLETE.md file
    echo -e "\n${BLUE}📝 Creating setup completion marker...${NC}"
    cat > V2.8_SETUP_COMPLETE.md << EOL
# Wine Manager v2.8 Setup Complete

**Date:** $(date "+%B %d, %Y")
**Branch:** $(git branch --show-current)

The setup for Wine Manager v2.8 development has been completed successfully. Development is now taking place on the v2.8-development-fresh branch, which was created from the stable v2.7 codebase.

## Next Steps
1. Implement new features as outlined in VERSION_2.8_DEVELOPMENT.md
2. Test on iPhone 16 simulators for compatibility
3. Perform performance testing
4. Update documentation as development progresses
EOL
    echo -e "${GREEN}✅ V2.8_SETUP_COMPLETE.md created${NC}"
    
    # Clean build folder to start fresh
    echo -e "\n${BLUE}🧹 Cleaning build folder...${NC}"
    xcodebuild clean -project SimpleWineManager/SimpleWineManager.xcodeproj -scheme SimpleWineManager -quiet
    echo -e "${GREEN}✅ Build folder cleaned${NC}"
    
    echo -e "\n${GREEN}✅ v2.8 setup completed successfully!${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "1. Review VERSION_2.8_DEVELOPMENT.md for development tasks"
    echo -e "2. Implement features incrementally with testing"
    echo -e "3. Test extensively on iPhone 16 simulators"
else
    echo -e "${RED}❌ Project file validation failed! Restoring backup...${NC}"
    mv "${PROJECT_FILE}.backup" "$PROJECT_FILE"
    exit 1
fi
