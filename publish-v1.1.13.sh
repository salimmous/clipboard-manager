#!/bin/bash

# Quick GitHub Release for v1.1.13

echo "🚀 Creating GitHub Release for ClipboardManager v1.1.13"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI not installed"
    echo ""
    echo "📝 Manual Release Instructions:"
    echo "================================"
    echo ""
    echo "1. Go to: https://github.com/salimmous/clipboard-manager/releases/new"
    echo ""
    echo "2. Fill in:"
    echo "   • Tag version: v1.1.13"
    echo "   • Release title: ClipboardManager v1.1.13 - Production Release"
    echo ""
    echo "3. Copy description from:"
    echo "   RELEASE_NOTES_v1.1.13.md"
    echo ""
    echo "4. Upload file:"
    echo "   ClipboardManager-1.1.13-Installer.dmg"
    echo ""
    echo "5. Click 'Publish release'"
    echo ""
    echo "✅ Done! Users will auto-update within 24 hours!"
    exit 0
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub"
    echo "Run: gh auth login"
    exit 1
fi

# Verify file exists
if [ ! -f "ClipboardManager-1.1.13-Installer.dmg" ]; then
    echo "❌ Installer not found: ClipboardManager-1.1.13-Installer.dmg"
    exit 1
fi

echo "✅ All checks passed!"
echo ""
echo "Creating release..."
echo ""

# Create release
gh release create v1.1.13 \
    --title "ClipboardManager v1.1.13 - Production Release" \
    --notes-file "RELEASE_NOTES_v1.1.13.md" \
    "ClipboardManager-1.1.13-Installer.dmg#ClipboardManager Installer (Universal)"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS!"
    echo "========================================="
    echo ""
    echo "✅ Release published at:"
    echo "   https://github.com/salimmous/clipboard-manager/releases/tag/v1.1.13"
    echo ""
    echo "📱 Users with auto-update will be notified within 24 hours"
    echo ""
    echo "📊 Track downloads at:"
    echo "   https://github.com/salimmous/clipboard-manager/releases"
    echo ""
else
    echo "❌ Release failed. Try manual creation."
    exit 1
fi
