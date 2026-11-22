#!/bin/bash

# Clipboard Manager Installation Script
# Works on any macOS system (Intel + Apple Silicon)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# App information
APP_NAME="Clipboard Manager"
APP_VERSION="1.4.0"
DOWNLOAD_URL="https://github.com/salimmous/clipboard-manager/releases/latest/download/ClipboardManager-${APP_VERSION}-Installer.dmg"
TEMP_DIR="/tmp/clipboard-manager-install"
DMG_NAME="ClipboardManager-${APP_VERSION}-Installer.dmg"

echo -e "${BLUE}📋 ${APP_NAME} v${APP_VERSION} - Universal macOS Installer${NC}"
echo "=================================================="
echo ""

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
MACOS_MINOR=$(echo $MACOS_VERSION | cut -d. -f2)

if [ "$MACOS_MAJOR" -lt 12 ]; then
    echo -e "${RED}❌ Error: ${APP_NAME} requires macOS 12.0 (Monterey) or later.${NC}"
    echo "Current macOS version: $MACOS_VERSION"
    echo "Please upgrade to macOS 12.0 or later."
    exit 1
fi

echo -e "${GREEN}✅ macOS version check passed: $MACOS_VERSION${NC}"

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    echo -e "${GREEN}✅ Intel Mac detected${NC}"
elif [ "$ARCH" = "arm64" ]; then
    echo -e "${GREEN}✅ Apple Silicon Mac detected${NC}"
else
    echo -e "${YELLOW}⚠️  Unknown architecture: $ARCH${NC}"
fi

echo ""

# Create temp directory
echo -e "${BLUE}📁 Creating temporary directory...${NC}"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download DMG
echo -e "${BLUE}⬇️  Downloading ${APP_NAME}...${NC}"
if command -v curl >/dev/null 2>&1; then
    curl -L -o "$DMG_NAME" "$DOWNLOAD_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$DMG_NAME" "$DOWNLOAD_URL"
else
    echo -e "${RED}❌ Error: Neither curl nor wget found. Please install one of them.${NC}"
    exit 1
fi

# Check if download was successful
if [ ! -f "$DMG_NAME" ]; then
    echo -e "${RED}❌ Error: Failed to download ${APP_NAME}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Download completed${NC}"

# Mount DMG
echo -e "${BLUE}🔗 Mounting installer...${NC}"
MOUNT_POINT=$(hdiutil attach "$DMG_NAME" -nobrowse -readonly | grep "/Volumes/" | cut -f3)

if [ -z "$MOUNT_POINT" ]; then
    echo -e "${RED}❌ Error: Failed to mount DMG${NC}"
    exit 1
fi

echo -e "${GREEN}✅ DMG mounted at: $MOUNT_POINT${NC}"

# Find the app in the mounted volume
APP_PATH=""
for item in "$MOUNT_POINT"/*; do
    if [[ "$item" == *.app ]]; then
        APP_PATH="$item"
        break
    fi
done

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Error: Could not find ${APP_NAME}.app in the DMG${NC}"
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
    exit 1
fi

echo -e "${GREEN}✅ Found app: $(basename "$APP_PATH")${NC}"

# Check if app is already installed
INSTALL_PATH="/Applications/$(basename "$APP_PATH")"
if [ -d "$INSTALL_PATH" ]; then
    echo -e "${YELLOW}⚠️  ${APP_NAME} is already installed.${NC}"
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Unmounting DMG...${NC}"
        hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
        echo -e "${GREEN}✅ Installation cancelled${NC}"
        exit 0
    fi
    echo -e "${BLUE}🗑️  Removing existing installation...${NC}"
    rm -rf "$INSTALL_PATH"
fi

# Install the app
echo -e "${BLUE}📦 Installing ${APP_NAME}...${NC}"
cp -R "$APP_PATH" "/Applications/"

# Set proper permissions
chmod +x "/Applications/$(basename "$APP_PATH")/Contents/MacOS/"*

echo -e "${GREEN}✅ Installation completed successfully!${NC}"

# Unmount DMG
echo -e "${BLUE}🔄 Unmounting DMG...${NC}"
hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true

# Clean up
echo -e "${BLUE}🧹 Cleaning up...${NC}"
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}🎉 ${APP_NAME} has been installed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Open Applications folder"
echo "2. Find '${APP_NAME}'"
echo "3. Right-click and select 'Open' (first time only)"
echo "4. Grant permissions when prompted"
echo "5. The app will appear in your menu bar"
echo ""
echo -e "${BLUE}⌨️  Keyboard shortcut:${NC}"
echo "Press ⌘+X to open the clipboard manager"
echo ""
echo -e "${BLUE}🔗 For more information:${NC}"
echo "https://github.com/salimmous/clipboard-manager"
echo ""
echo -e "${GREEN}✨ Enjoy your new clipboard manager!${NC}"