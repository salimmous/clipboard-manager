#!/bin/bash

# ClipboardManager Global Installation Script
# This script downloads and installs ClipboardManager globally for all macOS users

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="ClipboardManager"
DMG_URL="https://github.com/salimmous/clipboard-manager/releases/latest/download/ClipboardManager-1.4.0-Installer.dmg"
APP_PATH="/Applications/${APP_NAME}.app"
TEMP_DIR="/tmp/clipboardmanager-install"
DMG_NAME="${APP_NAME}-Installer.dmg"

echo -e "${BLUE}🚀 ClipboardManager Global Installation Script${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running as root for global installation
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root - installing globally for all users"
    GLOBAL_INSTALL=true
else
    print_info "Installing for current user only"
    GLOBAL_INSTALL=false
fi

# Check macOS version (require 12.0 Monterey or later)
print_info "Checking macOS version..."
macos_version=$(sw_vers -productVersion)
required_version="12.0"

if [[ "$(printf '%s\n' "$required_version" "$macos_version" | sort -V | head -n1)" != "$required_version" ]]; then
    print_error "This application requires macOS 12.0 (Monterey) or later."
    print_error "Your current version: $macos_version"
    exit 1
fi

print_status "macOS version $macos_version is compatible"

# Check for existing installation
if [[ -d "$APP_PATH" ]]; then
    print_warning "${APP_NAME} is already installed at $APP_PATH"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    print_info "Removing existing installation..."
    rm -rf "$APP_PATH"
fi

# Create temporary directory
print_info "Creating temporary directory..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download DMG
print_info "Downloading ${APP_NAME}..."
if command -v curl >/dev/null 2>&1; then
    curl -L -o "$DMG_NAME" "$DMG_URL" --progress-bar
elif command -v wget >/dev/null 2>&1; then
    wget -O "$DMG_NAME" "$DMG_URL"
else
    print_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

if [[ ! -f "$DMG_NAME" ]]; then
    print_error "Failed to download ${APP_NAME}"
    exit 1
fi

print_status "Download completed"

# Mount DMG
print_info "Mounting installer..."
MOUNT_POINT=$(hdiutil attach "$DMG_NAME" | grep -E '^/dev/' | awk '{print $3}' | tail -1)

if [[ -z "$MOUNT_POINT" ]]; then
    print_error "Failed to mount DMG"
    exit 1
fi

print_status "DMG mounted at $MOUNT_POINT"

# Find the app in the mounted DMG
APP_SOURCE="$MOUNT_POINT/${APP_NAME}.app"

if [[ ! -d "$APP_SOURCE" ]]; then
    print_error "${APP_NAME}.app not found in DMG"
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1
    exit 1
fi

# Copy app to Applications
print_info "Installing ${APP_NAME} to /Applications..."
cp -R "$APP_SOURCE" "/Applications/"

if [[ ! -d "$APP_PATH" ]]; then
    print_error "Failed to copy ${APP_NAME} to Applications"
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1
    exit 1
fi

# Set proper permissions
print_info "Setting permissions..."
chmod +x "$APP_PATH/Contents/MacOS/${APP_NAME}"

if [[ $GLOBAL_INSTALL == true ]]; then
    # Set global permissions for all users
    chown -R root:admin "$APP_PATH"
    chmod -R 755 "$APP_PATH"
    print_status "Global permissions set for all users"
else
    # Set user permissions
    chown -R "$(whoami):staff" "$APP_PATH"
    print_status "User permissions set"
fi

# Unmount DMG
print_info "Cleaning up..."
hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1

# Remove temporary files
cd /
rm -rf "$TEMP_DIR"

print_status "Installation completed successfully!"
echo ""
print_info "${APP_NAME} has been installed to /Applications"
print_info "You can now launch it from Launchpad or Applications folder"

if [[ $GLOBAL_INSTALL == true ]]; then
    print_status "Global installation complete - available for all users"
fi

echo ""
print_info "To launch ${APP_NAME} now, run:"
echo -e "${BLUE}open -a '${APP_NAME}'${NC}"
echo ""

# Ask if user wants to launch the app
read -p "Do you want to launch ${APP_NAME} now? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_info "You can launch ${APP_NAME} later from Applications"
else
    print_info "Launching ${APP_NAME}..."
    open -a "${APP_NAME}"
    print_status "${APP_NAME} launched successfully!"
fi

echo ""
print_status "Installation complete! Enjoy using ${APP_NAME}! 🎉"