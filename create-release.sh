#!/bin/bash

# GitHub Release Creation Script for ClipboardManager v1.1.12
# This script guides you through creating a GitHub release

echo "========================================="
echo "📦 ClipboardManager v1.1.12 Release"
echo "========================================="
echo ""

# Step 1: Verify files
echo "✅ Step 1: Verifying files..."
if [ -f "ClipboardManager-1.1.12-Installer.dmg" ]; then
    echo "   ✓ Installer DMG found"
    DMG_SIZE=$(du -h "ClipboardManager-1.1.12-Installer.dmg" | cut -f1)
    echo "   Size: $DMG_SIZE"
else
    echo "   ❌ ERROR: ClipboardManager-1.1.12-Installer.dmg not found!"
    echo "   Run 'make deploy' first"
    exit 1
fi

if [ -f "RELEASE_NOTES_v1.1.12.md" ]; then
    echo "   ✓ Release notes found"
else
    echo "   ❌ WARNING: Release notes not found"
fi

echo ""

# Step 2: Git status
echo "✅ Step 2: Checking git status..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "   ✓ Git repository detected"
    
    # Check for uncommitted changes
    if [[ -n $(git status -s) ]]; then
        echo "   ⚠️  WARNING: You have uncommitted changes"
        git status -s
        echo ""
        read -p "   Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "   ✓ No uncommitted changes"
    fi
else
    echo "   ❌ ERROR: Not a git repository"
    exit 1
fi

echo ""

# Step 3: GitHub CLI check
echo "✅ Step 3: Checking GitHub CLI..."
if command -v gh &> /dev/null; then
    echo "   ✓ GitHub CLI installed"
    
    # Check authentication
    if gh auth status &> /dev/null; then
        echo "   ✓ Authenticated with GitHub"
        
        # Show current repo
        REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
        if [ ! -z "$REPO" ]; then
            echo "   Repository: $REPO"
        fi
    else
        echo "   ❌ Not authenticated with GitHub"
        echo "   Run: gh auth login"
        exit 1
    fi
else
    echo "   ⚠️  GitHub CLI not installed"
    echo "   Install: brew install gh"
    echo "   Or create release manually at:"
    echo "   https://github.com/salimmous/clipboard-manager/releases/new"
    echo ""
    echo "   Manual steps:"
    echo "   1. Go to the URL above"
    echo "   2. Tag version: v1.1.12"
    echo "   3. Release title: Version 1.1.12"
    echo "   4. Copy content from RELEASE_NOTES_v1.1.12.md"
    echo "   5. Upload: ClipboardManager-1.1.12-Installer.dmg"
    echo "   6. Click 'Publish release'"
    exit 0
fi

echo ""

# Step 4: Create release
echo "✅ Step 4: Creating GitHub release..."
echo ""
echo "   This will:"
echo "   • Create tag 'v1.1.12'"
echo "   • Create release 'Version 1.1.12'"
echo "   • Upload ClipboardManager-1.1.12-Installer.dmg"
echo "   • Use notes from RELEASE_NOTES_v1.1.12.md"
echo ""
read -p "   Proceed with release creation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "   Cancelled"
    exit 0
fi

echo ""
echo "   Creating release..."

# Create the release
gh release create v1.1.12 \
    --title "Version 1.1.12" \
    --notes-file "RELEASE_NOTES_v1.1.12.md" \
    "ClipboardManager-1.1.12-Installer.dmg#ClipboardManager Installer (Universal Binary)"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✅ Release Created Successfully!"
    echo "========================================="
    echo ""
    echo "🎉 Your release is now live at:"
    echo "   https://github.com/salimmous/clipboard-manager/releases/tag/v1.1.12"
    echo ""
    echo "📱 Users with auto-update enabled will receive notifications within 24 hours!"
    echo ""
    echo "📊 Monitor download stats at:"
    echo "   https://github.com/salimmous/clipboard-manager/releases"
    echo ""
else
    echo ""
    echo "❌ Release creation failed"
    echo "Try manual creation at:"
    echo "https://github.com/salimmous/clipboard-manager/releases/new"
    exit 1
fi
