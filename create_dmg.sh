#!/bin/bash

# Create DMG installer for ClipboardManager
# Keeps volume name "Install ClipboardManager" for backward-compatible auto-updates.

set -euo pipefail

APP_NAME="ClipboardManager"
VERSION=$(plutil -extract CFBundleShortVersionString raw Info.plist)
FINAL_DMG="${APP_NAME}-${VERSION}-Installer.dmg"
SOURCE_APP="${APP_NAME}.app"
VOLUME_NAME="Install ${APP_NAME}"
STAGE_DIR="$(mktemp -d /tmp/clipboardmanager_dmg_stage.XXXXXX)"

cleanup() {
    rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

if [ ! -d "$SOURCE_APP" ]; then
    echo "Error: $SOURCE_APP not found! Run 'make app-bundle' first."
    exit 1
fi

echo "Preparing clean staging directory for ${APP_NAME} v${VERSION}..."
cp -R "$SOURCE_APP" "$STAGE_DIR/"

# Code sign staged app (use DEVELOPER_ID if provided, otherwise ad-hoc sign)
if [ -n "${DEVELOPER_ID:-}" ]; then
    echo "Signing with Developer ID: ${DEVELOPER_ID}..."
    codesign --force --deep --entitlements ClipboardManager.entitlements \
        --sign "Developer ID Application: ${DEVELOPER_ID}" --options runtime "$STAGE_DIR/$SOURCE_APP"
else
    echo "Signing with ad-hoc signature (set DEVELOPER_ID to sign with Developer ID)..."
    codesign --force --deep --sign - "$STAGE_DIR/$SOURCE_APP"
fi

codesign --verify --deep --strict "$STAGE_DIR/$SOURCE_APP"
echo "Code signature verified."

# Clean existing DMG & unmount lingering volume if any
rm -f "$FINAL_DMG"
if [ -d "/Volumes/$VOLUME_NAME" ]; then
    hdiutil detach "/Volumes/$VOLUME_NAME" -quiet || hdiutil detach "/Volumes/$VOLUME_NAME" -force -quiet || true
fi

# Prefer create-dmg for styled Finder window; fallback to clean hdiutil if Finder scripting is unavailable
CREATED=0
if command -v create-dmg >/dev/null 2>&1 && [ "${SKIP_FINDER_STYLE:-0}" != "1" ]; then
    echo "Building styled DMG with create-dmg..."
    VOLICON_ARGS=()
    if [ -f "AppIcon.icns" ]; then
        VOLICON_ARGS=(--volicon "AppIcon.icns")
    fi

    if create-dmg \
        --volname "$VOLUME_NAME" \
        "${VOLICON_ARGS[@]}" \
        --window-pos 200 120 \
        --window-size 600 360 \
        --icon-size 110 \
        --icon "$SOURCE_APP" 175 155 \
        --hide-extension "$SOURCE_APP" \
        --app-drop-link 425 155 \
        --no-internet-enable \
        "$FINAL_DMG" \
        "$STAGE_DIR"; then
        CREATED=1
    else
        echo "create-dmg styling failed (likely headless/Finder automation); falling back to hdiutil..."
        rm -f "$FINAL_DMG" rw.*."$FINAL_DMG" 2>/dev/null || true
        if [ -d "/Volumes/$VOLUME_NAME" ]; then
            hdiutil detach "/Volumes/$VOLUME_NAME" -force -quiet || true
        fi
    fi
fi

if [ "$CREATED" -ne 1 ]; then
    echo "Building compressed DMG with hdiutil..."
    ln -s /Applications "$STAGE_DIR/Applications"
    hdiutil create \
        -volname "$VOLUME_NAME" \
        -srcfolder "$STAGE_DIR" \
        -ov \
        -format UDZO \
        -imagekey zlib-level=9 \
        "$FINAL_DMG"
fi

echo ""
echo "✅ DMG created: $FINAL_DMG"
echo "📦 Size: $(du -h "$FINAL_DMG" | awk '{print $1}')"
echo "🔐 SHA-256: $(shasum -a 256 "$FINAL_DMG" | awk '{print $1}')"
