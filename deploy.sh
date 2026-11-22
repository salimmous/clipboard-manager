#!/bin/bash

# Automated Build, Package & GitHub Release Script for ClipboardManager

set -euo pipefail

APP_NAME="ClipboardManager"
REPO="salimmous/clipboard-manager"
VERSION=$(plutil -extract CFBundleShortVersionString raw Info.plist)
TAG="v${VERSION}"
DMG_FILE="${APP_NAME}-${VERSION}-Installer.dmg"
NOTES_FILE="RELEASE_NOTES_v${VERSION}.md"

echo "🚀 ClipboardManager Release Script (${TAG})"
echo "=========================================="

if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) not found. Install with: brew install gh"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "🔐 Please authenticate with GitHub first: gh auth login"
    exit 1
fi

echo "🧪 Running unit tests..."
swift test

echo "🔨 Building app bundle..."
make app-bundle

echo "💿 Creating DMG installer..."
chmod +x create_dmg.sh
./create_dmg.sh

if [ ! -f "$DMG_FILE" ]; then
    echo "❌ Expected DMG not found: $DMG_FILE"
    exit 1
fi

if [ ! -f "$NOTES_FILE" ]; then
    NOTES_FILE=$(mktemp /tmp/clipboardmanager_notes.XXXXXX)
    cat > "$NOTES_FILE" << EOF
# ClipboardManager ${TAG}

## Installation / Update
1. Download \`${DMG_FILE}\` below.
2. Open the DMG and drag **ClipboardManager** into **Applications**.
3. Launch **ClipboardManager**.
EOF
fi

if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    echo "⚠️  Release ${TAG} already exists on ${REPO}."
    read -p "Replace existing release ${TAG}? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    gh release delete "$TAG" -R "$REPO" --yes --cleanup-tag
fi

echo "🎉 Publishing ${TAG} to GitHub (${REPO})..."
gh release create "$TAG" \
    -R "$REPO" \
    --title "ClipboardManager ${TAG}" \
    --notes-file "$NOTES_FILE" \
    --latest \
    "$DMG_FILE"

echo "✅ Published: https://github.com/${REPO}/releases/tag/${TAG}"
echo "📱 Users on v1.4.0+ will receive automatic update notifications."
