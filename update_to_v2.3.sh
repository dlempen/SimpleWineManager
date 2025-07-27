#!/bin/zsh

# Wine Manager Version Update Script for v2.3
# Updated: July 21, 2025

echo "🍷 Wine Manager Version Update to v2.3"
echo "======================================"

PROJECT_FILE="SimpleWineManager/SimpleWineManager.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

echo "📦 Current version information:"
grep -m1 "MARKETING_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/Marketing Version: \1/'
grep -m1 "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/Build Number: \1/'

echo ""
echo "🔄 Updating to v2.3..."

# Create backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.pre_v2.3_backup"

# Update version numbers using sed
sed -i '' 's/MARKETING_VERSION = 2\.2;/MARKETING_VERSION = 2.3;/g' "$PROJECT_FILE"
sed -i '' 's/CURRENT_PROJECT_VERSION = 3;/CURRENT_PROJECT_VERSION = 4;/g' "$PROJECT_FILE"

echo "✅ Version numbers updated!"
echo ""
echo "📦 New version information:"
grep -m1 "MARKETING_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/Marketing Version: \1/'
grep -m1 "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/Build Number: \1/'

echo ""
echo "🎉 Ready for v2.3 development!"
echo ""
echo "💡 Next steps:"
echo "   1. Clean and rebuild in Xcode"
echo "   2. Continue developing your v2.3 features"
echo "   3. Test thoroughly before submission"
echo ""
