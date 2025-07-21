# Clipboard Manager for macOS

A native macOS clipboard manager built with Swift and SwiftUI that runs as both a desktop app and menu bar utility.

## Features

- 📋 **Native macOS App**: Built with Swift and SwiftUI for optimal performance
- 🔍 **Real-time Monitoring**: Automatically captures clipboard changes
- 📱 **Menu Bar Integration**: Quick access from the menu bar
- 💾 **Persistent Storage**: All data stored locally using UserDefaults
- 🎨 **Native UI**: Beautiful macOS-native design with SwiftUI
- ⌨️ **Quick Actions**: Click to copy, hover for actions
- 🔄 **Smart Detection**: Automatically detects URLs, emails, and phone numbers
- 🚀 **Lightweight**: Runs as background utility without dock icon

## Installation & Usage

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

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building from source)
- Swift 5.9+

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