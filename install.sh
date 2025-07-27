#!/bin/bash

# ClipboardManager Automatic Installer
# Compatible with macOS 11.0 (Big Sur) and later

set -e
echo "🚀 Starting ClipboardManager installation..."
echo

# Check macOS version compatibility
echo "🔍 Checking macOS compatibility..."
MAJOR_VERSION=$(sw_vers -productVersion | cut -d '.' -f 1)
MINOR_VERSION=$(sw_vers -productVersion | cut -d '.' -f 2)

if [[ $MAJOR_VERSION -lt 13 ]]; then
    echo "❌ This app requires macOS 13.0 (Ventura) or later"
    echo "📱 Your macOS version: $(sw_vers -productVersion)"
    echo "💡 Please update your macOS to install ClipboardManager"
    exit 1
fi

echo "✅ macOS $(sw_vers -productVersion) is compatible!"
echo

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed. Please install curl first"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "📁 Creating temporary directory: $TEMP_DIR"

# Download latest release
echo "⬇️ Downloading latest release..."
DOWNLOAD_URL="https://github.com/salimmous/clipboard-manager/releases/download/v1.0.4/ClipboardManager-1.0.4-Installer.dmg"

if ! curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/ClipboardManager.dmg"; then
    echo "❌ Failed to download the application"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Mount the DMG
echo "📦 Mounting DMG file..."

if ! hdiutil attach "$TEMP_DIR/ClipboardManager.dmg" -mountpoint "$TEMP_DIR/ClipboardManager"; then
    echo "❌ Failed to mount DMG file"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check if Applications folder exists
if [ ! -d "/Applications" ]; then
    echo "❌ Applications folder not found"
    hdiutil detach "$TEMP_DIR/ClipboardManager"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Copy app to Applications folder
echo "📱 Installing app to Applications folder..."

if ! cp -R "$TEMP_DIR/ClipboardManager/ClipboardManager.app" "/Applications/"; then
    echo "❌ Failed to copy app to Applications folder"
    echo "💡 Try running with admin privileges: sudo ./install.sh"
    hdiutil detach "$TEMP_DIR/ClipboardManager"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up temporary files
echo "🧹 Cleaning up temporary files..."
hdiutil detach "$TEMP_DIR/ClipboardManager"
rm -rf "$TEMP_DIR"

# Set proper permissions
echo "🔐 Setting proper permissions..."
chmod +x "/Applications/ClipboardManager.app/Contents/MacOS/ClipboardManager"

# Success message
echo "✅ ClipboardManager installed successfully!"
echo "🖥️  Compatible with macOS $(sw_vers -productVersion)"
echo
echo "🎉 You can now launch the app from:"
echo "   - Spotlight (press Cmd+Space and type ClipboardManager)"
echo "   - Applications folder"
echo "   - Or via Terminal: open /Applications/ClipboardManager.app"
echo
echo "📋 Available features:"
echo "   ⌘+X - Open/close clipboard window"
echo "   ✓ Automatic clipboard saving"
echo "   ✓ Automatic updates"
echo "   ✓ Quick search"
echo "   ✓ Keyboard shortcuts"
echo "   ✓ Global macOS compatibility (11.0+)"
echo
echo "🚀 Would you like to launch the app now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🎯 Launching the app..."
    open /Applications/ClipboardManager.app
    echo "📋 ClipboardManager is now running in your menu bar!"
fi

echo "🎊 Thank you for using ClipboardManager!"
echo "🌍 Works globally on all supported macOS versions!"