#!/bin/bash

# Veltrix Security - DMG Builder
# Creates a distributable DMG file from the built app

set -e

# Configuration
APP_NAME="VeltrixSecurity"
VERSION="1.0.0"
BUILD_DIR="./build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION.dmg"
TEMP_DMG="temp-$DMG_NAME"
VOLUME_NAME="Veltrix Security"

echo "🔨 Building $DMG_NAME..."

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    echo "Please build the app first: xcodebuild build -scheme VeltrixSecurity -configuration Release"
    exit 1
fi

# Clean up previous temp files
rm -f "$TEMP_DMG" "$DMG_NAME"

# Create DMG
echo "📦 Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$APP_PATH" \
    -ov -format UDZO \
    -imagekey zlib-level=9 \
    "$TEMP_DMG"

# Rename to final
mv "$TEMP_DMG" "$DMG_NAME"

# Get file size
SIZE=$(ls -lh "$DMG_NAME" | awk '{print $5}')

echo "✅ DMG created: $DMG_NAME"
echo "📊 Size: $SIZE"

# Calculate SHA256 (useful for distribution)
echo ""
echo "🔐 SHA256 Checksum:"
shasum -a 256 "$DMG_NAME"

echo ""
echo "📝 Next steps:"
echo "1. Sign the DMG (if using Developer ID):"
echo "   codesign --sign 'Developer ID Application' $DMG_NAME"
echo ""
echo "2. Test on another Mac:"
echo "   - Download and open the DMG"
echo "   - Drag VeltrixSecurity.app to /Applications"
echo "   - Launch and verify it runs"
echo ""
echo "3. Verify Gatekeeper acceptance:"
echo "   spctl -a -v /Applications/$APP_NAME.app"
echo ""
echo "4. Distribute via:"
echo "   - GitHub Releases: gh release create v$VERSION $DMG_NAME"
echo "   - Direct download on your website"
echo "   - Email to beta testers"

