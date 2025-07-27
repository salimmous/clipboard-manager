#!/bin/bash

# Automated Deployment Script for ClipboardManager
# This script automatically builds, packages, and releases new versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 ClipboardManager Auto-Deployment Script${NC}"
echo "================================================"

# Extract version from Info.plist
VERSION=$(plutil -p Info.plist | grep CFBundleShortVersionString | awk '{print $3}' | tr -d '"')
TAG="v$VERSION"

echo -e "${YELLOW}📋 Current version: $VERSION${NC}"
echo -e "${YELLOW}🏷️  Release tag: $TAG${NC}"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    read -p "Do you want to commit them first? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Update to version $VERSION"
        echo -e "${GREEN}✅ Changes committed${NC}"
    fi
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is not installed${NC}"
    echo "Please install it with: brew install gh"
    exit 1
fi

# Check if user is authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}🔐 Please authenticate with GitHub first${NC}"
    gh auth login
fi

# Check if release already exists
echo -e "${BLUE}🔍 Checking for existing release...${NC}"
if gh release view "$TAG" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Release $TAG already exists${NC}"
    read -p "Do you want to delete it and create a new one? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🗑️  Deleting existing release...${NC}"
        gh release delete "$TAG" --yes
        git push --delete origin "$TAG" 2>/dev/null || true
        echo -e "${GREEN}✅ Existing release deleted${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipping deployment${NC}"
        exit 0
    fi
fi

# Build the application
echo -e "${BLUE}🔨 Building application...${NC}"
swift build -c release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Create app bundle
echo -e "${BLUE}📦 Creating app bundle...${NC}"
mkdir -p ClipboardManager.app/Contents/MacOS
mkdir -p ClipboardManager.app/Contents/Resources

# Copy executable
cp .build/release/ClipboardManager ClipboardManager.app/Contents/MacOS/

# Copy Info.plist
cp Info.plist ClipboardManager.app/Contents/

# Copy icon if exists
if [ -f "CustomAppIcon.icns" ]; then
    cp CustomAppIcon.icns ClipboardManager.app/Contents/Resources/AppIcon.icns
fi

# Make executable
chmod +x ClipboardManager.app/Contents/MacOS/ClipboardManager

echo -e "${GREEN}✅ App bundle created${NC}"

# Create DMG installer
echo -e "${BLUE}💿 Creating DMG installer...${NC}"
chmod +x create_dmg.sh

# Force unmount any lingering DMG volumes
echo -e "${YELLOW}Force unmounting any lingering DMG volumes...${NC}"
pkill -f "Install ${APP_NAME}" 2>/dev/null || true
hdiutil detach -force "/Volumes/Install ${APP_NAME}" 2>/dev/null || true
sleep 2

echo "n" | ./create_dmg.sh

if [ -f "ClipboardManager-$VERSION-Installer.dmg" ]; then
    echo -e "${GREEN}✅ DMG installer created${NC}"
else
    echo -e "${RED}❌ DMG creation failed${NC}"
    exit 1
fi

# Create release notes
echo -e "${BLUE}📝 Creating release notes...${NC}"
cat > release_notes.md << EOF
# ClipboardManager v$VERSION

## 🚀 What's New
- Updated to version $VERSION
- Enhanced security features
- Improved auto-update system
- Bug fixes and performance improvements

## 📦 Installation
1. Download the DMG file below
2. Open the DMG and drag ClipboardManager to Applications
3. Launch from Applications folder

## 🔄 Auto-Update
This version includes automatic update notifications. The app will check for new versions and notify you when updates are available.

## 🛡️ Security
- Enhanced privacy permissions
- Secure clipboard handling
- Code signing for trusted installation

---

**Download the installer below and enjoy the latest features!**
EOF

# Push changes to GitHub
echo -e "${BLUE}📤 Pushing changes to GitHub...${NC}"
git push origin main

# Create GitHub release
echo -e "${BLUE}🎉 Creating GitHub release...${NC}"
gh release create "$TAG" \
    --title "ClipboardManager v$VERSION" \
    --notes-file release_notes.md \
    --latest \
    "ClipboardManager-$VERSION-Installer.dmg"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Release created successfully!${NC}"
    echo -e "${BLUE}🔗 Release URL: https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/releases/tag/$TAG${NC}"
else
    echo -e "${RED}❌ Release creation failed${NC}"
    exit 1
fi

# Clean up
echo -e "${BLUE}🧹 Cleaning up...${NC}"
rm -f release_notes.md
rm -rf ClipboardManager.app

echo -e "${GREEN}🎊 Deployment completed successfully!${NC}"
echo -e "${BLUE}📱 Users will be notified of the new version automatically${NC}"
echo "================================================"