# Auto-Update System Setup Guide

## Overview
The application includes an automatic update system that checks for new versions from GitHub Releases and downloads/installs them automatically.

## GitHub Repository Setup

### 1. Create GitHub Repository
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/clipboard-manager.git
git push -u origin main
```

### 2. Update Repository URL in Code
In `main.swift`, update the URL in `AppUpdateManager`:
```swift
private let releasesURL = "https://api.github.com/repos/YOUR_USERNAME/clipboard-manager/releases/latest"
```

### 3. Create New Release
1. Go to your repository page on GitHub
2. Click "Releases" in the sidebar
3. Click "Create a new release"
4. Enter tag version (e.g., v1.0.1)
5. Enter release title and description of updates
6. Upload the compressed `.app` file as an Asset
7. Click "Publish release"

## Building the App for Distribution

### 1. Build the Application
```bash
# Build the app
swift build -c release

# Or use Xcode
# Product > Archive > Distribute App
```

### 2. Compress the Application
```bash
# Compress the app
zip -r ClipboardManager-v1.0.1.zip ClipboardManager.app
```

### 3. Upload Release
- Upload the compressed file to GitHub Release
- Ensure the filename contains the version number

## How Auto-Update Works

### 1. Update Checking
- Checks for updates every 24 hours by default
- Users can change this interval in settings
- Manual update check available from app menu

### 2. Update Download
- When an update is available, user gets a notification
- One-click download from the update prompt
- Update is saved to Downloads folder

### 3. Update Installation
- Downloads folder opens automatically
- User is prompted to drag new app to Applications folder
- Old app closes automatically

## User Settings

### In Settings Menu:
- **Enable Auto-Updates**: Turn automatic update checking on/off
- **Update Check Interval**: From 1 hour to 1 week

### In App Menu:
- **Check for Updates**: Manual update check
- **Download Update**: When new version is available

## Update Security

### Version Verification
- Compares version numbers
- Validates download URLs
- Checks file integrity

### Permissions
- No admin privileges required
- Downloads to user folder
- User controls installation process

## Troubleshooting

### Common Issues:
1. **Updates not showing**: Check GitHub Repository URL
2. **Download fails**: Check internet connection
3. **Installation doesn't work**: Check Applications folder permissions

### Error Logs:
```swift
// Add logging for development
print("Update check failed: \(error.localizedDescription)")
```

## Developer Tips

1. **Test Updates**: Test the system with beta releases
2. **Version Numbers**: Use Semantic Versioning (v1.0.0)
3. **Update Descriptions**: Write clear descriptions of new features
4. **Backups**: Keep copies of previous versions
5. **Testing**: Test the app on different systems before release

## Workflow Example

```bash
# 1. Develop new feature
git checkout -b feature/new-feature
# ... develop code
git commit -m "Add new feature"
git push origin feature/new-feature

# 2. Merge to main
git checkout main
git merge feature/new-feature
git push origin main

# 3. Build new release
swift build -c release

# 4. Create Release on GitHub
# - Tag: v1.0.2
# - Title: "Add New Feature"
# - Description: Update details
# - Assets: ClipboardManager-v1.0.2.zip

# 5. Users will automatically get update notification
```

## GitHub CLI Commands

### Setup
```bash
# Install GitHub CLI
brew install gh

# Login
gh auth login

# Create repository
gh repo create clipboard-manager --public --description "Clipboard Manager with Auto-Update"
```

### Release Management
```bash
# Create release
gh release create v1.0.1 ClipboardManager-v1.0.1.zip --title "Version 1.0.1" --notes "Release notes here"

# List releases
gh release list

# View release
gh release view v1.0.1
```

This system ensures users get the latest updates easily and securely.