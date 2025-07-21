# 🤖 ClipboardManager Automation Guide

This guide explains the automated deployment system for ClipboardManager that handles version updates, builds, and releases automatically.

## 📋 Overview

The automation system consists of three main components:

1. **Version Bump Script** (`bump_version.sh`) - Automatically increments version numbers
2. **Deployment Script** (`deploy.sh`) - Builds and releases new versions
3. **GitHub Actions Workflow** (`.github/workflows/auto-release.yml`) - Automated CI/CD

## 🚀 Quick Start

### For New Releases (Recommended Workflow)

```bash
# 1. Bump version and deploy in one go
./bump_version.sh

# 2. Or do it step by step:
./bump_version.sh  # Choose version type
./deploy.sh        # Build and release
```

### For Manual Deployment

```bash
# Deploy current version
./deploy.sh
```

## 📈 Version Bump Script (`bump_version.sh`)

### What it does:
- ✅ Automatically increments version numbers (patch/minor/major)
- ✅ Updates all version references in the codebase
- ✅ Creates changelog entries
- ✅ Optionally triggers deployment

### Usage:
```bash
./bump_version.sh
```

### Version Types:
- **Patch** (1.0.3 → 1.0.4): Bug fixes, small improvements
- **Minor** (1.0.3 → 1.1.0): New features, backwards compatible
- **Major** (1.0.3 → 2.0.0): Breaking changes
- **Custom**: Specify any version manually

### Files Updated:
- `Info.plist` - Bundle version strings
- `Sources/main.swift` - App version constants and UI text
- `create_dmg.sh` - DMG version
- `README.md` - Documentation version (if present)
- `CHANGELOG.md` - Version history

## 🚀 Deployment Script (`deploy.sh`)

### What it does:
- ✅ Checks for existing releases and removes them
- ✅ Builds the application with Swift
- ✅ Creates app bundle with proper structure
- ✅ Generates DMG installer
- ✅ Creates GitHub release with release notes
- ✅ Uploads DMG to GitHub releases

### Prerequisites:
- GitHub CLI (`gh`) installed and authenticated
- Xcode command line tools
- Git repository with remote origin

### Usage:
```bash
./deploy.sh
```

### What happens:
1. **Version Detection**: Reads version from `Info.plist`
2. **Conflict Resolution**: Removes existing releases if they exist
3. **Build Process**: Compiles the Swift application
4. **Packaging**: Creates `.app` bundle and DMG installer
5. **Release Creation**: Publishes to GitHub with auto-generated notes
6. **Cleanup**: Removes temporary files

## ⚙️ GitHub Actions Workflow

### Automatic Triggers:
The workflow automatically runs when you push changes to:
- `Sources/main.swift`
- `Info.plist`
- `Package.swift`

### What it does:
- 🔄 Detects version changes
- 🗑️ Removes old releases automatically
- 🔨 Builds on macOS runners
- 📦 Creates DMG installers
- 🎉 Publishes GitHub releases

### Setup:
1. The workflow file is already created in `.github/workflows/auto-release.yml`
2. No additional setup required - it uses `GITHUB_TOKEN` automatically
3. Push your changes and the workflow will run

## 🔄 Auto-Update System Integration

### How it works with the app:
1. **Version Detection**: App checks current version against GitHub releases
2. **Automatic Cleanup**: Old releases are removed, only latest is kept
3. **User Notifications**: App notifies users when new versions are available
4. **One-Click Updates**: Users can download and install updates easily

### Update Check URL:
```
https://api.github.com/repos/salimmous/clipboard-manager/releases/latest
```

## 📝 Release Notes Template

Each release automatically includes:

```markdown
# ClipboardManager v{VERSION}

## 🚀 What's New
- Updated to version {VERSION}
- Enhanced security features
- Improved auto-update system
- Bug fixes and performance improvements

## 📦 Installation
1. Download the DMG file below
2. Open the DMG and drag ClipboardManager to Applications
3. Launch from Applications folder

## 🔄 Auto-Update
This version includes automatic update notifications.

## 🛡️ Security
- Enhanced privacy permissions
- Secure clipboard handling
- Code signing for trusted installation
```

## 🛠️ Troubleshooting

### Common Issues:

#### "GitHub CLI not found"
```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login
```

#### "Build failed"
```bash
# Check Swift installation
swift --version

# Clean build
swift package clean
swift build -c release
```

#### "DMG creation failed"
```bash
# Check create_dmg.sh permissions
chmod +x create_dmg.sh

# Unmount any existing volumes
hdiutil detach "/Volumes/Install ClipboardManager" 2>/dev/null || true
```

#### "Release already exists"
The scripts automatically handle this by:
1. Asking for confirmation
2. Deleting the existing release
3. Creating a new one

### Manual Cleanup:
```bash
# Remove all releases for a version
gh release delete v1.0.3 --yes
git push --delete origin v1.0.3

# Clean local build artifacts
rm -rf .build
rm -rf ClipboardManager.app
rm -f *.dmg
```

## 🎯 Best Practices

### Development Workflow:
1. **Make changes** to your code
2. **Test locally** with `swift run`
3. **Bump version** with `./bump_version.sh`
4. **Review changes** with `git diff`
5. **Deploy** automatically or manually

### Version Strategy:
- **Patch**: Bug fixes, typos, small improvements
- **Minor**: New features, UI improvements, new functionality
- **Major**: Breaking changes, major redesigns, API changes

### Release Frequency:
- **Patch releases**: As needed for critical fixes
- **Minor releases**: Weekly or bi-weekly for new features
- **Major releases**: Monthly or quarterly for significant updates

## 📊 Monitoring

### Check Release Status:
```bash
# List all releases
gh release list

# View specific release
gh release view v1.0.3

# Check download stats
gh release view v1.0.3 --json assets
```

### App Update Analytics:
The app automatically reports update check frequency and success rates through the auto-update system.

## 🔐 Security Considerations

- ✅ **Code Signing**: DMG files are created with proper signatures
- ✅ **Secure Distribution**: GitHub releases provide secure download links
- ✅ **Version Verification**: App verifies update authenticity
- ✅ **Privacy**: No personal data collected during update checks

## 🆘 Support

If you encounter issues with the automation system:

1. **Check the logs** in GitHub Actions
2. **Run scripts manually** to isolate issues
3. **Verify prerequisites** (GitHub CLI, Xcode, etc.)
4. **Check permissions** on script files

---

**🎉 Congratulations! Your ClipboardManager now has a fully automated deployment pipeline that handles everything from version bumping to user notifications!**