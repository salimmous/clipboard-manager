# ClipboardManager Installation Guide

## Quick Installation

### Step 1: Download the App
1. Go to [Releases page](https://github.com/salimmous/clipboard-manager/releases)
2. Download the latest version `ClipboardManager-1.0.4-Installer.dmg`

### Step 2: Install the Application
1. Open the downloaded `.dmg` file
2. Drag `ClipboardManager.app` to the `Applications` folder
3. Launch the app from Applications folder

### Step 3: Allow App to Run
If you see a security warning:
1. Go to `System Preferences` > `Security & Privacy`
2. Click `Open Anyway` next to the app name

## Terminal Installation

```bash
# Download latest release
curl -L -o ClipboardManager.dmg https://github.com/salimmous/clipboard-manager/releases/download/v1.0.4/ClipboardManager-1.0.4-Installer.dmg

# Mount the DMG
hdiutil attach ClipboardManager.dmg

# Copy to Applications
cp -R "/Volumes/ClipboardManager/ClipboardManager.app" /Applications/

# Unmount DMG
hdiutil detach "/Volumes/ClipboardManager"

# Launch the app
open /Applications/ClipboardManager.app
```

## Requirements
- macOS 13.0 (Ventura) or later
- 50 MB free space

## Features
- ✅ Automatic clipboard saving
- ✅ Automatic updates
- ✅ User-friendly interface
- ✅ Quick search in history
- ✅ Keyboard shortcuts

## Troubleshooting
If you encounter installation issues:
1. Make sure macOS is up to date
2. Check for sufficient free space
3. Restart your Mac and try again

## Uninstallation
To remove the app:
1. Go to `Applications` folder
2. Drag `ClipboardManager.app` to Trash
3. Empty Trash

---

**Note**: The app supports automatic updates, so you'll get the latest features automatically!