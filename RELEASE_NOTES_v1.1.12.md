# ClipboardManager v1.1.12 Release Notes

## 🎉 Major Features Added

### 🧠 Smart Content Detection
Automatically detects and provides quick actions for:
- **📧 Email addresses** - Click to compose email instantly
- **📞 Phone numbers** - Click to call via FaceTime
- **📍 Addresses** - Click to open in Apple Maps

Smart detection runs automatically when you copy text. Just right-click any clipboard item to see available actions!

### ☁️ iCloud Sync Across Devices
Seamlessly sync your clipboard history across all your Macs:
- Automatic background synchronization
- Smart conflict resolution (no duplicates)
- Syncs text and URLs (images excluded for performance)
- Shows last sync time in settings
- Enable/disable with one toggle

**Note:** Requires iCloud to be enabled on your Mac. Text and URLs only; images are stored locally for optimal performance.

### ⌨️ Keyboard Shortcuts
- Global hotkey: **⌘X** (Command+X) to show/hide clipboard
- Displayed in Settings for easy reference
- Framework ready for full customization in future updates

### 📸 Screenshot Auto-Copy
Automatically copies new screenshots to your clipboard:
- Detects screenshots saved to Desktop
- Immediately adds to clipboard history
- Works with all screenshot formats (PNG, JPG, HEIC)
- Enable in Settings → General → Auto-Copy Screenshots

### 🖼️ HEIC Image Support
Full support for modern image formats:
- HEIC (iPhone/iPad default format)
- JPEG, PNG, TIFF, GIF
- Universal Clipboard images
- Automatic format conversion

## 🔄 Automatic Update System

### Smart Update Notifications
Beautiful, actionable notifications keep you informed:
- 🎉 **Update Available** - One tap to install
- ⬇️ **Downloading** - Real-time progress
- ✅ **Complete** - Ready to install
- ❌ **Error** - Clear error messages

### One-Click Updates
- Tap notification → Automatically downloads
- Choose auto-install or manual download
- Progress tracking at every step
- No GitHub knowledge required

### Settings UI
New **Update Status** panel:
- Current version display
- Real-time update availability
- "Check for Updates" button
- "Install Update" button
- Configure auto-update preferences

## 🛠️ Technical Improvements

### Image Storage Optimization
- **Fixed**: Memory crashes from storing images in UserDefaults
- Images now stored on disk in Application Support directory
- Automatic migration from old format
- Efficient file management with cleanup

### Modern Notification System
- **Fixed**: Deprecated NSUserNotificationCenter
- Now uses modern UserNotifications framework
- Better compatibility with macOS Ventura, Sonoma, and later
- Proper permission requests

### Universal Binary
- Supports both Intel and Apple Silicon Macs
- Single installer for all Mac architectures
- Optimized performance on M1/M2/M3 chips

## 🎨 User Experience Enhancements

### Settings Organization
All features accessible in Settings:
- **General**: Appearance, notifications, smart features, shortcuts
- **Updates**: Auto-update controls, version info, manual check
- **About**: App information and credits
- **Integrations**: Slack, Discord, Email, Notes

### Performance
- Faster clipboard monitoring (0.5s interval)
- Efficient file-based image storage
- Background sync without UI blocking
- Smooth animations and transitions

## 📋 System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Architecture**: Universal (Intel + Apple Silicon)
- **iCloud** (optional): For cross-device sync
- **Disk Space**: ~5 MB application + clipboard data

## 🐛 Bug Fixes

- Fixed memory crashes when copying large/multiple images
- Fixed notification compatibility on macOS 14+
- Fixed HEIC image detection and handling
- Fixed update version comparison logic
- Removed duplicate iCloudSync initialization
- Fixed async closure syntax warnings

## 🔐 Privacy & Security

- All clipboard data stored locally on your Mac
- Images stored in Application Support (not UserDefaults)
- iCloud sync uses private CloudKit database
- No analytics or tracking
- No external servers (except GitHub for updates)

## ⚙️ Settings & Preferences

### Configurable Options
- Max clipboard items (default: 100)
- Update check interval (1-168 hours)
- Auto-update behavior
- Screenshot watching
- Smart content detection
- iCloud sync
- Notifications

### Default Settings
- Auto-update check: Every 24 hours
- Screenshot auto-copy: Disabled
- Smart detection: Enabled
- iCloud sync: Disabled
- Notifications: Enabled

## 📦 Installation

1. Download `ClipboardManager-1.1.12-Installer.dmg`
2. Open the DMG file
3. Drag **ClipboardManager** to **Applications** folder
4. **Right-click** → **Open** (first time only, to bypass Gatekeeper)
5. Grant notification permissions when prompted
6. App appears in menu bar!

## 🆕 What's Next?

Planned for future releases:
- Full keyboard shortcut customization
- Quick Look preview (press Space for large preview)
- Paste Stack (paste multiple items in sequence)
- Rich text formatting support
- Multi-language support
- Statistics and insights
- More integration options

## 🙏 Credits

Built with ❤️ by Salim Moussouni
- GitHub: [@salimmous](https://github.com/salimmous)
- Repository: [clipboard-manager](https://github.com/salimmous/clipboard-manager)

## 📞 Support

- Report bugs: [GitHub Issues](https://github.com/salimmous/clipboard-manager/issues)
- Feature requests: [GitHub Discussions](https://github.com/salimmous/clipboard-manager/discussions)

---

**Full Changelog**: [v1.1.11...v1.1.12](https://github.com/salimmous/clipboard-manager/compare/v1.1.11...v1.1.12)
