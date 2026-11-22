#!/bin/bash

# Test Script for ClipboardManager
# Run this if the app doesn't work after installation

echo "🧪 Testing ClipboardManager installation..."

# Check if app exists
if [ ! -d "/Applications/ClipboardManager.app" ]; then
    echo "❌ ClipboardManager not found in Applications folder"
    echo "💡 Please install the app first by dragging it to Applications"
    exit 1
fi

echo "✅ App found in Applications folder"

# Check if executable exists
if [ ! -f "/Applications/ClipboardManager.app/Contents/MacOS/ClipboardManager" ]; then
    echo "❌ App executable not found"
    exit 1
fi

echo "✅ App executable found"

# Check permissions
if [ ! -x "/Applications/ClipboardManager.app/Contents/MacOS/ClipboardManager" ]; then
    echo "🔧 Fixing permissions..."
    chmod +x "/Applications/ClipboardManager.app/Contents/MacOS/ClipboardManager"
fi

echo "✅ Permissions OK"

# Try to launch the app
echo "🚀 Attempting to launch ClipboardManager..."
open "/Applications/ClipboardManager.app"

echo "✅ App launched successfully!"
echo "💡 Check your menu bar for the ClipboardManager icon"
echo "💡 Press ⌘⇧V to open the clipboard manager"
echo ""
echo "🔧 If direct paste doesn't work:"
echo "1. Open System Settings → Privacy & Security → Accessibility"
echo "2. Enable ClipboardManager in the list"
echo "3. Restart the app"
