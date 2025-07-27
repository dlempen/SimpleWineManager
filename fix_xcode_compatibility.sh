#!/bin/bash

# Xcode Project Compatibility Fix Script
# Converts Xcode 16 project format to compatible format

echo "🔧 Fixing Xcode Project Compatibility"
echo "==================================="

PROJECT_FILE="/Users/VBLPD/Desktop/SimpleWineManager/SimpleWineManager/SimpleWineManager.xcodeproj/project.pbxproj"

# Create backup
echo "📁 Creating backup..."
cp "$PROJECT_FILE" "${PROJECT_FILE}.broken_backup"

# Fix objectVersion
echo "🔄 Downgrading object version..."
sed -i '' 's/objectVersion = 77;/objectVersion = 56;/' "$PROJECT_FILE"

# Check if that's enough
echo "✅ Basic fix applied"
echo ""
echo "🎯 Next steps:"
echo "1. Try opening the project in Xcode now"
echo "2. If it still doesn't work, we'll need to recreate the project"
echo ""
echo "💡 Alternative solutions if needed:"
echo "- Update to latest Xcode (recommended)"
echo "- Recreate project with older format"
echo ""
