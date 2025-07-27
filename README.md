# Clipboard Manager for macOS

**ClipboardManager** is a powerful, native macOS clipboard management utility that transforms how you work with copied content. Built with Swift and SwiftUI, this lightweight application runs seamlessly in your menu bar, providing instant access to your clipboard history.

## 🆕 **What's New in v1.1.0**

- ✨ **Professional Icons**: Added high-quality, professional app icons with proper iconset structure
- 🌐 **Global Installation Support**: New global-install.sh script for system-wide installation in /Applications
- 📦 **Enhanced DMG Installer**: Improved installer with better visual presentation
- 🔧 **Updated macOS Requirements**: Now requires macOS 13.0+ (Ventura or later) for better compatibility
- 📚 **Improved Documentation**: Enhanced installation guides with separate user and global installation options

## 🎯 **What It Does**
ClipboardManager automatically captures and stores everything you copy, creating a searchable history that persists across app sessions. With a simple **⌘+X** keyboard shortcut, you can instantly access your clipboard history from anywhere on your Mac.

## 🎮 **How to Control the App**

### **Basic Controls**
- **⌘+X** - Toggle clipboard window (show/hide)
- **Click Menu Bar Icon** - Access quick menu with recent items
- **Click "Show All"** - Open full clipboard interface
- **Search Box** - Type to filter clipboard items
- **Click Item** - Copy selected item back to clipboard
- **Hover over Item** - Show action buttons

### **Menu Bar Controls**
- **Left Click** - Show recent clipboard items menu
- **"Show All" Button** - Open main clipboard window
- **"Settings" Button** - Access app preferences
- **"Quit" Button** - Exit the application

### **Main Window Controls**
- **Search Field** - Filter items by typing
- **Item List** - Scroll through clipboard history
- **Clear All** - Remove all clipboard items
- **Settings Panel** - Configure app behavior

### **Settings & Preferences**
- **Appearance Mode** - Choose System, Light, or Dark theme
- **Max Items** - Set maximum number of items to store (default: 100)
- **Update Interval** - Adjust clipboard monitoring frequency
- **Auto-Update** - Enable/disable automatic app updates
- **Update Check Interval** - Set how often to check for updates (1 hour to 1 week)
- **Auto-Install Updates** - Automatically install new versions

### **Keyboard Shortcuts**
- **⌘+X** - Global hotkey to show/hide clipboard window
- **↑/↓ Arrow Keys** - Navigate through clipboard items
- **Enter** - Copy selected item to clipboard
- **⌘+F** - Focus search field
- **Escape** - Close clipboard window

## Features

- 📋 **Native macOS App**: Built with Swift and SwiftUI for optimal performance
- 🔍 **Real-time Monitoring**: Automatically captures clipboard changes with customizable intervals
- 📱 **Menu Bar Integration**: Quick access from the menu bar with professional icons
- 💾 **Persistent Storage**: All data stored locally using UserDefaults
- 🎨 **Native UI**: Beautiful macOS-native design with SwiftUI
- ⌨️ **Quick Actions**: Click to copy, hover for actions
- 🔄 **Smart Detection**: Automatically detects URLs, emails, and phone numbers
- 🚀 **Lightweight**: Runs as background utility without dock icon
- 🔄 **Automatic Updates**: Built-in update system that checks for new versions automatically
- ⚙️ **Customizable Update Intervals**: Set how often the app checks for updates (1 hour to 1 week)
- 🎯 **Professional Icons**: High-quality app icons with proper iconset structure
- 🌐 **Global Installation**: Support for system-wide installation for all users

## 📥 **Download & Installation**

### **Quick Download (Recommended)**
📥 **[Download ClipboardManager v1.1.0 Installer](https://github.com/salimmous/clipboard-manager/releases/download/v1.1.0/ClipboardManager-1.1.0-Installer.dmg)**

1. Click the download link above
2. Open the downloaded `.dmg` file
3. Drag ClipboardManager to your Applications folder
4. Launch from Applications or Spotlight

### **One-Click Installation Scripts**

**User Installation (recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/salimmous/clipboard-manager/main/install.sh | bash
```

**Global Installation (all users):**
```bash
curl -fsSL https://raw.githubusercontent.com/salimmous/clipboard-manager/main/global-install.sh | bash
```

### **Alternative Download Links**
- 📦 [All Releases](https://github.com/salimmous/clipboard-manager/releases)
- 🔄 [Latest Release](https://github.com/salimmous/clipboard-manager/releases/latest)
- 💾 [Direct DMG Download](https://github.com/salimmous/clipboard-manager/releases/download/v1.1.0/ClipboardManager-1.1.0-Installer.dmg)

---

## 🛠️ **Build from Source (Advanced)**

### Option 1: Build from Source
```bash
# Clone or download the project
cd "copy clipboard"

# Build the application
make build

# Run the application
make run

# Install to system (optional)
make install
```

### Option 2: Create App Bundle
```bash
# Create a macOS app bundle
make app-bundle

# Move to Applications folder
mv ClipboardManager.app /Applications/
```

## How to Use

1. **Launch**: Run the app - it will appear in your menu bar
2. **Auto-Capture**: Copy any text - it's automatically saved
3. **Quick Access**: Click the menu bar icon to see recent items
4. **Full Interface**: Click "Show All" for the complete interface
5. **Search**: Use the search box to find specific items
6. **Copy**: Click any item to copy it back to clipboard

## Requirements

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+ (for building from source)
- Swift 5.9+
- Administrator privileges (for global installation only)

## Privacy

All clipboard data is stored locally on your Mac using UserDefaults. No data is transmitted over the network or shared with third parties.

## Technical Details

- **Language**: Swift 5.9
- **Framework**: SwiftUI
- **Architecture**: MVVM with ObservableObject
- **Storage**: UserDefaults with JSON encoding
- **Monitoring**: NSPasteboard polling with Timer
- **UI**: Native macOS controls and styling

## Available Commands

- `make build` - Build the application
- `make run` - Run the application
- `make clean` - Clean build artifacts
- `make install` - Install to /usr/local/bin
- `make app-bundle` - Create macOS app bundle
- `make help` - Show available commands

Enjoy your native macOS clipboard manager! 🎉