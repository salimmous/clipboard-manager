#!/bin/bash

# Create DMG installer for ClipboardManager
# This script creates a beautiful DMG installer similar to Spark Desktop

set -e

APP_NAME="ClipboardManager"
VERSION="1.1.5"
DMG_NAME="${APP_NAME}-${VERSION}-Installer"
SOURCE_APP="ClipboardManager.app"
TEMP_DMG="temp_${DMG_NAME}.dmg"
FINAL_DMG="${DMG_NAME}.dmg"
VOLUME_NAME="Install ${APP_NAME}"
DMG_SIZE="50m"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Creating DMG installer for ${APP_NAME}...${NC}"

# Check if source app exists
if [ ! -d "$SOURCE_APP" ]; then
    echo -e "${RED}Error: $SOURCE_APP not found!${NC}"
    exit 1
fi

# Clean up any existing files
echo -e "${YELLOW}Cleaning up existing files...${NC}"
rm -f "$TEMP_DMG" "$FINAL_DMG"
rm -rf "/Volumes/$VOLUME_NAME"

# Create a clean temporary directory with only necessary files
echo -e "${YELLOW}Preparing clean directory...${NC}"
TEMP_DIR="temp_dmg_content"
rm -rf "$TEMP_DIR"
mkdir "$TEMP_DIR"

# Copy only the app
cp -R "$SOURCE_APP" "$TEMP_DIR/"

# Ensure the app is code signed with Developer ID
echo -e "${YELLOW}Code signing the app with Developer ID...${NC}"
codesign --force --deep --sign "Developer ID Application: MUSTAFA HALASMUNLA (KAAL9WK5ZP)" --options runtime "$TEMP_DIR/$SOURCE_APP" || echo -e "${YELLOW}Warning: Could not sign app${NC}"

# Create temporary DMG from clean directory
echo -e "${YELLOW}Creating temporary DMG...${NC}"
hdiutil create -srcfolder "$TEMP_DIR" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size "$DMG_SIZE" "$TEMP_DMG"

# Clean up temp directory
rm -rf "$TEMP_DIR"

# Mount the DMG
echo -e "${YELLOW}Mounting DMG...${NC}"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
VOLUME_PATH="/Volumes/$VOLUME_NAME"

# Wait for mount
sleep 2

# Clean the mounted volume (remove unnecessary files)
echo -e "${YELLOW}Cleaning mounted volume...${NC}"
find "$VOLUME_PATH" -name ".*" -delete 2>/dev/null || true
rm -rf "$VOLUME_PATH/.fseventsd" 2>/dev/null || true
rm -rf "$VOLUME_PATH/.Spotlight-V100" 2>/dev/null || true
rm -rf "$VOLUME_PATH/.Trashes" 2>/dev/null || true
rm -rf "$VOLUME_PATH/Installer" 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.sh 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.md 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.txt 2>/dev/null || true
rm -f "$VOLUME_PATH/Package.swift" 2>/dev/null || true
rm -f "$VOLUME_PATH/Makefile" 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.zip 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.png 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.svg 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.icns 2>/dev/null || true
rm -rf "$VOLUME_PATH/Sources" 2>/dev/null || true
rm -rf "$VOLUME_PATH/AppIcon.iconset" 2>/dev/null || true
rm -f "$VOLUME_PATH/"*.swift 2>/dev/null || true
rm -f "$VOLUME_PATH/Info.plist" 2>/dev/null || true
rm -f "$VOLUME_PATH/.gitignore" 2>/dev/null || true

# Ensure only the app remains
if [ ! -d "$VOLUME_PATH/$SOURCE_APP" ]; then
    echo -e "${RED}Error: App was removed during cleanup!${NC}"
    exit 1
fi

# Create Applications symlink
echo -e "${YELLOW}Creating Applications symlink...${NC}"
ln -sf /Applications "$VOLUME_PATH/Applications"

# Create background image
echo -e "${YELLOW}Creating background image...${NC}"
mkdir -p "$VOLUME_PATH/.background"

# Create a simple background using built-in tools
cat > "$VOLUME_PATH/.background/create_bg.py" << 'EOF'
import os
from PIL import Image, ImageDraw, ImageFont

# Create a 600x400 background image
width, height = 600, 400
img = Image.new('RGB', (width, height), color='#f8f9fa')
draw = ImageDraw.Draw(img)

# Add gradient effect
for y in range(height):
    alpha = y / height
    color = tuple(int(248 + (240-248) * alpha) for _ in range(3))
    draw.line([(0, y), (width, y)], fill=color)

# Add subtle grid pattern
for x in range(0, width, 50):
    draw.line([(x, 0), (x, height)], fill='#f0f1f2', width=1)
for y in range(0, height, 50):
    draw.line([(0, y), (width, y)], fill='#f0f1f2', width=1)

img.save('background.png')
EOF

# Try to create background with Python PIL, fallback to simple method
if command -v python3 >/dev/null 2>&1; then
    cd "$VOLUME_PATH/.background"
    python3 -c "from PIL import Image, ImageDraw; img = Image.new('RGB', (600, 400), '#f8f9fa'); img.save('background.png')" 2>/dev/null || \
    python3 -c "import os; os.system('sips -s format png --resampleWidth 600 --resampleHeight 400 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns --out background.png')" 2>/dev/null || \
    cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns" "background.png" 2>/dev/null || \
    echo "Simple background" > background.txt
    cd - >/dev/null
else
    echo "Creating simple background..."
    echo "" > "$VOLUME_PATH/.background/background.png"
fi

rm -f "$VOLUME_PATH/.background/create_bg.py" 2>/dev/null || true

# Set up the view options
echo -e "${YELLOW}Setting up view options...${NC}"

# Create .DS_Store with proper view settings
cat > /tmp/dmg_setup.applescript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"
        set position of item "$SOURCE_APP" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Apply the settings
echo -e "${YELLOW}Applying Finder settings...${NC}"
osascript /tmp/dmg_setup.applescript || echo -e "${YELLOW}Warning: Could not set all view options${NC}"

# Clean up
rm -f /tmp/dmg_setup.applescript

# Sync and unmount
echo -e "${YELLOW}Finalizing DMG...${NC}"
sync

# Retry unmounting with a delay
ATTEMPTS=0
MAX_ATTEMPTS=5
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    hdiutil detach "$DEVICE" && break
    ATTEMPTS=$((ATTEMPTS + 1))
    echo -e "${YELLOW}Unmount failed, retrying in 2 seconds... ($ATTEMPTS/$MAX_ATTEMPTS)${NC}"
    sleep 2
done

# Force unmount if still busy
if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}Unmount failed after multiple attempts, forcing...${NC}"
    hdiutil detach -force "$DEVICE"
fi

# Convert to compressed DMG
echo -e "${YELLOW}Compressing DMG...${NC}"
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

# Clean up temporary files
rm -f "$TEMP_DMG"

echo -e "${GREEN}✅ DMG installer created successfully: $FINAL_DMG${NC}"
echo -e "${BLUE}📦 Size: $(du -h "$FINAL_DMG" | cut -f1)${NC}"
echo -e "${BLUE}🚀 Ready for distribution!${NC}"

# Optional: Open the DMG to test
read -p "Do you want to open the DMG to test it? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$FINAL_DMG"
fi