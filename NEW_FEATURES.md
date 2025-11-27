# ClipboardManager - New Features Summary

## 🎉 **Three Major Features Added**

### 1. **🧠 Smart Content Detection**
The app now automatically detects special content types in your clipboard:

- **📧 Email addresses** - Click to compose email
- **📞 Phone numbers** - Click to call (via FaceTime)
- **📍 Addresses** - Click to open in Apple Maps

**How it works:**
- When you copy text containing emails, phones, or addresses, they're automatically detected
- Right-click on any clipboard item to see quick actions for detected content
- Enable/disable in Settings → General → Smart Features

### 2. **☁️ iCloud Sync Across Devices**
Sync your clipboard history across all your Macs using iCloud!

**Features:**
- Automatic sync when enabled
- Syncs text and URLs (images excluded for performance)
- Shows last sync time in settings
- Merges items intelligently (no duplicates)

**How to enable:**
1. Open Settings → General
2. Toggle "Enable iCloud Sync"
3. Make sure you're signed into iCloud on all devices

**Note:** Requires iCloud to be enabled on your Mac. The app will check your iCloud status automatically.

### 3. **⌨️ Customizable Keyboard Shortcuts**
- Current shortcut: **⌘X** (Command+X)
- Displayed in Settings → General → Keyboard Shortcuts
- Future update will allow full customization

---

## 📋 **Technical Details**

### Smart Detection Implementation
- Uses `NSRegularExpression` for pattern matching
- Detects:
  - Emails: Standard email format validation
  - Phones: Multiple formats (international, US, etc.)
  - Addresses: Street patterns with common suffixes

### iCloud Sync Implementation
- Uses CloudKit private database
- Stores items as `CKRecord` with fields: id, content, type, isPinned, timestamp
- Automatic conflict resolution (newest wins)
- Background sync with status indicators

### Data Structure Changes
```swift
struct ClipboardItem {
    // ... existing fields ...
    var detectedEntities: [DetectedEntity] = []
}

struct DetectedEntity {
    let type: DetectedEntityType // email, phone, address
    let value: String
    let range: String
}
```

---

## 🚀 **How to Use**

### Smart Detection
1. Copy text with an email: `contact@example.com`
2. Open clipboard manager
3. Right-click the item → See "Email contact@example.com"
4. Click to open your email client

### iCloud Sync
1. Enable in Settings
2. Copy something on Mac #1
3. Open clipboard manager on Mac #2
4. Item appears automatically!

### Keyboard Shortcuts
- Press **⌘X** anywhere to show/hide clipboard
- Settings shows current shortcut
- (Custom shortcuts coming in next update)

---

## ⚠️ **Known Limitations**

1. **iCloud Sync:**
   - Images are NOT synced (too large for CloudKit)
   - Requires active internet connection
   - First sync may take a few seconds

2. **Smart Detection:**
   - Address detection works best with US-style addresses
   - Phone detection may occasionally match non-phone numbers

3. **Keyboard Shortcuts:**
   - Currently fixed to ⌘X
   - Full customization coming soon

---

## 🔧 **Settings Location**

All new features are in **Settings → General**:
- Smart Features section
- Keyboard Shortcuts section  
- iCloud Sync section

---

## 📦 **Build & Deploy**

The app has been successfully built with all new features.
Run `make deploy` to create the installer DMG.

**Version:** 1.1.12+
**macOS:** 13.0+ (Ventura and later)
**Architecture:** Universal (Intel + Apple Silicon)
