# Automatic Update System - Complete Guide

## ✅ **What's Fixed & Improved:**

### 1. **Version Number Updated**
- Current version: **1.1.12**
- Properly synced with installer version
- Accurate version comparison for updates

### 2. **Smart Update Notifications**
Users now get beautiful, actionable notifications:
- 🎉 "**New Update Available!**" – with "Update Now" and "Later" buttons
- ⬇️ "**Downloading Update**" – shows download progress
- ✅ "**Download Complete**" – ready to install
- ❌ "**Update Failed**" – if something goes wrong

### 3. **One-Click Updates**
- Tap notification → Automatically downloads & installs
- No manual steps required!
- Progress tracking at every step

### 4. **Auto-Update Flow**
```
1. App checks GitHub every X hours (configurable)
2. New version detected → Notification appears
3. User taps "Update Now"
4. Download starts (with progress notification)
5. Installation options appear (Auto or Manual)
6. Update installs & app restarts
```

### 5. **Settings UI Improvements**
New **Update Status** panel in Settings → Updates:
- Shows current version (v1.1.12)
- Shows if update available
- "Check for Updates" button (with loading state)
- "Install Update" button (when available)
- Real-time update status

---

## 🔧 **How to Enable Auto-Updates:**

### For End Users:
1. Open **ClipboardManager Settings**
2. Go to **Updates** tab
3. Toggle ON: **"Check for Updates Automatically"**
4. (Optional) Toggle ON: **"Install Updates Automatically"** for hands-free updates
5. Set check interval (default: 24 hours)

### Update Modes:
- **Manual**: Get notified, click to install
- **Automatic**: Updates install without asking
- **Check Interval**: 1-168 hours (1 week max)

---

## 🚀 **For Developers: How to Publish Updates**

### Step 1: Update Version
In `main.swift`, line 371:
```swift
private let currentVersion = "1.1.13" // Update this
```

### Step 2: Build Release
```bash
make deploy
```

### Step 3: Create GitHub Release
1. Go to: https://github.com/salimmous/clipboard-manager/releases
2. Click "Create a new release"
3. Tag version: `v1.1.13` (must start with 'v')
4. Release title: `Version 1.1.13`
5. Description: List changes
6. Upload: `ClipboardManager-1.1.13-Installer.dmg`
7. Publish!

### Step 4: Users Auto-Update
- Users with auto-update enabled get notification within configured interval
- They click "Update Now"
- App auto-downloads, installs, and restarts
- Done! ✅

---

## 📋 **Technical Details:**

### Update Check Logic:
```swift
// Checks GitHub API endpoint
https://api.github.com/repos/salimmous/clipboard-manager/releases/latest

// Compares versions:
- Current: "1.1.12"
- Latest: "1.1.13" 
- If latest > current → Notify user
```

### Version Comparison:
- Splits versions by "."
- Compares each segment numerically
- Example: 1.2.0 > 1.1.99 ✓

### Notification Categories:
```swift
UPDATE_CATEGORY with actions:
- UPDATE_NOW (foreground)
- LATER (background)
```

### Download Flow:
1. URLSession downloads `.dmg` to temp location
2. Shows progress notifications
3. Presents installation options
4. Auto-installs to `/Applications/`
5. Restarts app

---

## ⚙️ **Settings Explained:**

### Check for Updates Automatically
- **ON**: Checks GitHub every X hours
- **OFF**: No automatic checking (manual only)

### Install Updates Automatically  
- **ON**: Downloads and installs without asking
- **OFF**: Ask before installing (recommended)

### Check Interval
- How often to check for new versions
- Range: 1-168 hours
- Default: 24 hours (once per day)
- Recommended: 12-24 hours for active users

---

## 🔔 **Notification Examples:**

### 1. Update Available
```
🎉 New Update Available!
Version v1.1.13 is ready to install. Tap to update now.

[Update Now]  [Later]
```

### 2. Downloading
```
⬇️ Downloading Update
Version v1.1.13 is being downloaded...
```

### 3. Download Complete
```
✅ Download Complete
Ready to install version v1.1.13
```

### 4. Error
```
❌ Update Failed
Failed to download update: [error details]
```

---

## 🎯 **Best Practices:**

### For Users:
1. Keep "Check for Updates" enabled
2. Use "Install Automatically" if you trust updates
3. Check interval: 24 hours is good balance
4. Always tap "Update Now" when notified

### For Developers:
1. Always test updates locally first
2. Increment version correctly (semantic versioning)
3. Write detailed release notes
4. Upload DMG to GitHub Releases
5. Tag with "v" prefix (v1.1.13, not 1.1.13)

---

## 🐛 **Troubleshooting:**

### "No updates found" but new version exists:
- Check GitHub release tag starts with 'v'
- Ensure DMG is uploaded to release
- Wait for API cache (up to 5 minutes)

### Download fails:
- Check internet connection
- Ensure enough disk space
- Try manual download from GitHub

### Update doesn't install:
- Check `/Applications/` permissions
- Close all instances of the app
- Manually download and install

---

## 📊 **Update Statistics (for future):**

Track update adoption:
- Users on latest version
- Average update time
- Failed update reasons
- Most common update interval

(Requires analytics integration)

---

## 🎉 **Result:**

Users now have a **professional, automatic update system** that:
- ✅ Checks for updates automatically
- ✅ Shows beautiful notifications
- ✅ Offers one-click installation
- ✅ Tracks download progress
- ✅ Handles errors gracefully
- ✅ Provides full manual control in settings

**The update experience is now as smooth as macOS App Store!** 🚀
