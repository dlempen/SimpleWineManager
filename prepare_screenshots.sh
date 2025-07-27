#!/bin/bash

# Wine Manager - Screenshot Helper Script
# This script helps you prepare screenshots for App Store submission

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📱 Wine Manager - Screenshot Preparation Guide${NC}"
echo "==========================================================="

# Create screenshots directory
SCREENSHOTS_DIR="/Users/VBLPD/Desktop/SimpleWineManager/AppStore_Screenshots"
mkdir -p "$SCREENSHOTS_DIR"

echo -e "${YELLOW}📋 Required Screenshot Dimensions:${NC}"
echo ""
echo -e "${BLUE}iPhone Screenshots:${NC}"
echo "• iPhone 6.7\" (iPhone 14 Pro Max): 1290 x 2796 pixels"
echo "• iPhone 6.5\" (iPhone XS Max): 1242 x 2688 pixels"
echo "• iPhone 5.5\" (iPhone 8 Plus): 1242 x 2208 pixels"
echo ""
echo -e "${BLUE}iPad Screenshots:${NC}"
echo "• iPad Pro 12.9\" (6th gen): 2048 x 2732 pixels"
echo "• iPad Pro 11\" (4th gen): 1668 x 2388 pixels"
echo ""

echo -e "${YELLOW}📸 How to take screenshots:${NC}"
echo "1. Open the iOS Simulator in Xcode"
echo "2. Choose the device sizes listed above"
echo "3. Build and run your app (⌘+R)"
echo "4. Navigate to key screens and take screenshots (⌘+S)"
echo "5. Screenshots will be saved to Desktop"
echo ""

echo -e "${YELLOW}🖼️  Recommended screenshots to capture:${NC}"
echo "1. Main wine list/collection view"
echo "2. Add new wine screen"
echo "3. Wine detail view with photo"
echo "4. Search/filter functionality"
echo "5. Settings or additional features"
echo ""

echo -e "${BLUE}💡 Pro Tips:${NC}"
echo "• Use high-quality sample data for screenshots"
echo "• Show your app's best features"
echo "• Ensure text is readable"
echo "• Use consistent wine data across screenshots"
echo "• Consider using status bar overlays (clean status bar)"
echo ""

echo -e "${GREEN}📁 Screenshot folder created: $SCREENSHOTS_DIR${NC}"
echo ""

# Create sample data suggestions
cat > "$SCREENSHOTS_DIR/sample_wine_data.txt" << 'EOF'
SAMPLE WINE DATA FOR SCREENSHOTS
================================

Use these sample wines to make your screenshots look professional:

1. Château Margaux 2015
   - Region: Bordeaux, France / Margaux
   - Type: Red Wine
   - Producer: Château Margaux
   - Notes: "Exceptional vintage with elegant tannins"

2. Barolo Brunate 2018
   - Region: Piedmont, Italy / Barolo
   - Type: Red Wine  
   - Producer: Giuseppe Mascarello
   - Notes: "Traditional Barolo with excellent aging potential"

3. Chablis Premier Cru 2020
   - Region: Burgundy, France / Chablis
   - Type: White Wine
   - Producer: William Fèvre
   - Notes: "Crisp minerality with citrus notes"

4. Opus One 2019
   - Region: California, USA / Napa Valley
   - Type: Red Wine
   - Producer: Opus One Winery
   - Notes: "Bordeaux-style blend, perfect balance"

5. Dom Pérignon 2012
   - Region: Champagne, France
   - Type: Sparkling Wine
   - Producer: Moët & Chandon
   - Notes: "Prestigious vintage champagne"

TIP: Add these wines to your app before taking screenshots
to showcase the app's features with realistic, impressive data.
EOF

echo -e "${GREEN}✅ Sample wine data file created for screenshots${NC}"
echo -e "${BLUE}📖 Check: $SCREENSHOTS_DIR/sample_wine_data.txt${NC}"

# Device simulator commands
echo -e "${YELLOW}🚀 Quick Simulator Commands:${NC}"
echo "To quickly open simulators for screenshots:"
echo ""
echo "iPhone 14 Pro Max:"
echo "xcrun simctl boot 'iPhone 14 Pro Max' && open -a Simulator"
echo ""
echo "iPhone XS Max:"  
echo "xcrun simctl boot 'iPhone XS Max' && open -a Simulator"
echo ""
echo "iPad Pro 12.9-inch (6th generation):"
echo "xcrun simctl boot 'iPad Pro (12.9-inch) (6th generation)' && open -a Simulator"
