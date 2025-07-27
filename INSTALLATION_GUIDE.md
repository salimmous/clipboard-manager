# ClipboardManager Installation Guide

## Automatic Installation (Recommended)

### For Current User Only
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/clipboardmanager/main/install.sh | bash
```

### For Global Installation (All Users)
To install ClipboardManager globally for all macOS users, run with administrator privileges:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/clipboardmanager/main/global-install.sh | sudo bash
```

Both scripts will:
- Check macOS version compatibility (13.0+ required)
- Download the latest version automatically
- Install to `/Applications` folder
- Set proper permissions (global or user-specific)
- Launch the app automatically

### Manual Installation from DMG

1. **Download** the `ClipboardManager-1.0.4-Installer.dmg` file
2. **Double-click** the DMG file to mount it
3. **Drag** the ClipboardManager app to the Applications folder
4. **Eject** the DMG by clicking the eject button in Finder
5. **Launch** ClipboardManager from your Applications folder or Spotlight

## First Launch

- The app will appear as a clipboard icon in your menu bar
- Click the icon to access your clipboard history
- The app runs in the background and automatically saves your clipboard items

## Security Note

The app is code-signed with a **Developer ID Application certificate**, which means:
- ✅ **Globally trusted** - Works on all macOS systems without warnings
- ✅ **Apple verified** - Signed with official Apple Developer certificate
- ✅ **Runtime hardened** - Enhanced security with runtime protections
- ✅ **No security bypasses needed** - Installs and runs immediately
- ✅ **Professional distribution** - Ready for enterprise and public use

## Troubleshooting

If you encounter any issues:
1. Make sure you're running macOS 13.0 (Ventura) or later
2. Ensure you have an active internet connection during first launch (for certificate verification)
3. If the app doesn't appear in menu bar, check Activity Monitor to confirm it's running
4. For any permission requests, grant them in System Preferences > Security & Privacy > Privacy

## Features

- 📋 Automatic clipboard history tracking
- 🔍 Search through clipboard items
- 🎨 Clean, minimalist interface
- 🔄 Auto-update functionality
- 🛡️ Privacy-focused (data stays local)

Enjoy using ClipboardManager!