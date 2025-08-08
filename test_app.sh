#!/bin/bash

# Test Script for ClipboardGenius
# Run this if the app doesn't work after installation

echo "🧪 Testing ClipboardGenius installation..."

# Check if app exists
if [ ! -d "/Applications/ClipboardGenius.app" ]; then
    echo "❌ ClipboardGenius not found in Applications folder"
    echo "💡 Please install the app first by dragging it to Applications"
    exit 1
fi

echo "✅ App found in Applications folder"

# Check if executable exists
if [ ! -f "/Applications/ClipboardGenius.app/Contents/MacOS/ClipboardManager" ]; then
    echo "❌ App executable not found"
    exit 1
fi

echo "✅ App executable found"

# Check permissions
if [ ! -x "/Applications/ClipboardGenius.app/Contents/MacOS/ClipboardManager" ]; then
    echo "🔧 Fixing permissions..."
    chmod +x "/Applications/ClipboardGenius.app/Contents/MacOS/ClipboardManager"
fi

echo "✅ Permissions OK"

# Try to launch the app
echo "🚀 Attempting to launch ClipboardGenius..."
open "/Applications/ClipboardGenius.app"

echo "✅ App launched successfully!"
echo "💡 Check your menu bar for the ClipboardGenius icon"
echo "💡 Press ⌘+X to open the clipboard manager"
echo ""
echo "🔧 If the app doesn't work:"
echo "1. Go to System Preferences → Security & Privacy → General"
echo "2. Click 'Allow' next to ClipboardGenius"
echo "3. Go to System Preferences → Security & Privacy → Accessibility"
echo "4. Add ClipboardGenius to the list"
echo "5. Restart the app"
