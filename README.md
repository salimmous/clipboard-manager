# Clipboard Manager for macOS

**ClipboardManager** is a powerful, native macOS clipboard management utility that transforms how you work with copied content. Built with Swift and SwiftUI, this lightweight application runs seamlessly in your menu bar, providing instant access to your clipboard history with advanced features and integrations.

## 🆕 **What's New in v1.1.12**

### 🔥 **Major Feature Updates**
- 🖼️ **Image Support**: Copy/paste images with preview thumbnails
- 🔍 **Advanced Search**: Filter by content type, date, and text
- 🎨 **Custom Themes**: Beautiful color schemes (Blue, Purple, Green, Orange)
- ⚡ **Quick Actions**: Share to apps, transform text, and more
- 🌙 **Enhanced Dark Mode**: Improved dark theme with better contrast
- 📐 **Compact Mode**: Smaller, minimal interface option
- 🎭 **Custom Icons**: Multiple icon styles and animations
- 📏 **Resizable Windows**: User-adjustable window sizes
- 🔔 **Smart Notifications**: Contextual alerts with auto-dismiss

### 🔗 **Powerful Integrations**
- 💬 **Slack Integration**: Send clipboard items directly to Slack channels
- 🎮 **Discord Integration**: Share content to Discord servers
- 📧 **Email Integration**: Compose emails with multiple app support (Mail, Outlook, Gmail, Spark)
- 📝 **Notes Apps Integration**: Save to Notes, Notion, Obsidian, Bear, DEVONthink
- 🕒 **Scheduled Clear**: Automatically clear old clipboard items
- ⌨️ **Menu Bar Customization**: Configurable menu items with smart display

### 🎯 **Visual Enhancements**
- ✨ **Smooth Animations**: Beautiful transitions and loading states
- 🎨 **Gradient Backgrounds**: Eye-catching theme-based gradients
- 📊 **Enhanced Empty State**: Animated tips and welcome messages
- 🎪 **Improved Header**: Item counter, keyboard shortcuts display
- 🔍 **Visual Search Bar**: Enhanced with focus indicators and shadows
- 🏷️ **Content Type Icons**: Visual indicators for text, images, and URLs

## 🎯 **What It Does**
ClipboardManager automatically captures and stores everything you copy - text, images, and URLs - creating a searchable, filterable history that persists across app sessions. With a simple **⌘+X** keyboard shortcut, you can instantly access your clipboard history from anywhere on your Mac.

## 🎮 **How to Control the App**

### **Basic Controls**
- **⌘+X** - Toggle clipboard window (show/hide)
- **Esc** - Close clipboard window
- **Click Menu Bar Icon** - Access quick menu with recent items (max 5)
- **Click "Show All"** - Open full clipboard interface when >5 items
- **Search Box** - Type to filter clipboard items by content
- **Filter Chips** - Filter by content type (Text, Image, URL) or date
- **Click Item** - Copy selected item back to clipboard
- **Right-click Item** - Context menu with actions and integrations

### **Menu Bar Controls**
- **Left Click** - Show recent clipboard items menu (max 5 items with full text)
- **"Show All" Button** - Open main clipboard window (appears when >5 items)
- **"Settings" Button** - Access comprehensive app preferences
- **"Quit" Button** - Exit the application

### **Main Window Features**
- **Smart Window Sizing** - 380px (compact) / 420px (normal) width
- **Search & Filter** - Real-time filtering with visual chips
- **Content Type Icons** - Visual indicators for different content types
- **Time Stamps** - "X minutes ago" display for each item
- **Pin Items** - Keep important items permanently
- **Batch Actions** - Clear all, export history
- **Context Menus** - Right-click for actions and integrations

### **Settings & Preferences**

#### **General Tab**
- **Appearance Mode** - System, Light, Dark, Blue, Purple, Green, Orange themes
- **Compact Mode** - Toggle between normal (420px) and compact (380px) interface
- **Smart Notifications** - Enable contextual clipboard notifications
- **Max Items** - Set maximum number of items to store (default: 100)
- **Update Interval** - Adjust clipboard monitoring frequency

#### **Integrations Tab** ⭐
- **Slack Integration** - Configure webhook URL for channel sharing
- **Discord Integration** - Set up webhook for server sharing
- **Email Integration** - Choose default app (Mail, Outlook, Gmail, Spark)
- **Notes Integration** - Select preferred app (Notes, Notion, Obsidian, Bear, DEVONthink)
- **Test Buttons** - Verify integrations with sample messages

#### **Updates Tab**
- **Auto-Update** - Enable/disable automatic app updates
- **Update Check Interval** - Set frequency (1 hour to 1 week)
- **Auto-Install Updates** - Automatically install new versions
- **Manual Check** - Check for updates immediately

#### **About Tab**
- **App Information** - Version, copyright, and credits
- **System Details** - Build information and technical specs

### **Keyboard Shortcuts**
- **⌘+X** - Global hotkey to show/hide clipboard window
- **Esc** - Close clipboard window
- **↑/↓ Arrow Keys** - Navigate through clipboard items
- **Enter** - Copy selected item to clipboard
- **⌘+F** - Focus search field
- **Delete** - Remove selected item

## ✨ **Key Features**

### **Core Functionality**
- 📋 **Multi-Content Support**: Text, images (.png, .tiff), and URLs
- 🔍 **Advanced Search**: Real-time filtering by content and type
- 📊 **Smart Categorization**: Automatic content type detection
- 💾 **Persistent Storage**: All data stored locally with auto-sync
- 📌 **Pin Important Items**: Keep essential clips permanently
- 🕒 **Timestamp Tracking**: "X minutes ago" for each item

### **Visual & UX**
- 🎨 **Beautiful Themes**: 7 appearance modes with custom gradients
- ✨ **Smooth Animations**: Polished transitions and micro-interactions
- 📱 **Responsive Design**: Adapts to compact and normal modes
- 🌙 **Dark Mode Excellence**: Enhanced dark theme with proper contrast
- 📐 **Resizable Interface**: Customizable window dimensions
- 🎪 **Enhanced Empty States**: Welcoming first-run experience

### **Integrations & Productivity**
- 💬 **Slack/Discord**: Direct sharing with webhook support
- 📧 **Email Clients**: Multi-app support with smart detection
- 📝 **Notes Ecosystem**: Universal notes app integration
- 🔔 **Smart Notifications**: Non-intrusive success/error feedback
- ⚡ **Quick Actions**: Context-sensitive action menus
- 🕒 **Scheduled Cleanup**: Automatic old item removal

### **Technical Excellence**
- 🚀 **Native Performance**: Built with Swift and SwiftUI
- 🔄 **Real-time Monitoring**: Efficient clipboard watching (0.5s intervals)
- 💾 **Reliable Persistence**: UserDefaults with immediate sync
- 🎯 **Menu Bar Optimization**: Lightweight background operation
- 🔐 **Privacy First**: All data stays on your Mac
- 🛠️ **Auto-Updates**: Seamless version management

## 📥 **Download & Installation**

### **Quick Download (Recommended)**
📥 **[Download ClipboardManager v1.1.12 Installer](https://github.com/salimmous/clipboard-manager/releases/latest/download/ClipboardManager-1.1.12-Installer.dmg)**

1. Click the download link above
2. Open the downloaded `.dmg` file
3. Drag ClipboardManager to your Applications folder
4. Launch from Applications or Spotlight
5. **Important**: Right-click → Open on first launch (security requirement)

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
- 💾 [Direct DMG Download](https://github.com/salimmous/clipboard-manager/releases/latest/download/ClipboardManager-1.1.12-Installer.dmg)

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

## 🚀 **How to Use**

### **Getting Started**
1. **Launch**: Run the app - it appears in your menu bar with a clipboard icon
2. **Auto-Capture**: Copy any text, image, or URL - it's automatically saved
3. **Quick Access**: Click menu bar icon to see recent 5 items with full text
4. **Full Interface**: Click "Show All" for complete interface (when >5 items)
5. **Search & Filter**: Use search box and filter chips to find content
6. **Copy**: Click any item to copy it back to clipboard

### **Setting Up Integrations**
1. **Open Settings** → Integrations tab
2. **Slack**: Get webhook URL from Slack workspace settings
3. **Discord**: Create webhook in server settings → copy URL
4. **Email/Notes**: Select your preferred applications
5. **Test**: Use test buttons to verify integrations work
6. **Use**: Right-click any clipboard item → choose integration

### **Customizing Appearance**
1. **Open Settings** → General tab
2. **Choose Theme**: System, Light, Dark, or custom colors
3. **Toggle Compact Mode**: Smaller interface for minimal design
4. **Enable Notifications**: Get feedback on clipboard actions
5. **Adjust Monitoring**: Set clipboard check frequency

## 🔧 **Troubleshooting**

### **App Won't Open**
- **Right-click** → Open on first launch (macOS security)
- Check **System Preferences** → Security & Privacy → Allow app

### **Integrations Not Working**
- Verify webhook URLs in **Settings** → Integrations
- Test with **Test buttons** in settings
- Ensure target apps are installed for Notes/Email

### **Settings Not Saving**
- Settings now auto-save immediately when changed
- Check **Settings** → about for current version

## 📋 **Requirements**

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** (for building from source)
- **Swift 5.9+**
- **Administrator privileges** (for global installation only)
- **Internet connection** (for integrations and updates)

## 🔒 **Privacy & Security**

- **Local Storage**: All clipboard data stored locally using UserDefaults
- **No Cloud Sync**: No data transmitted unless you use integrations
- **Webhook Security**: Integration URLs stored securely in UserDefaults
- **Transparent Operations**: Open source with visible code
- **User Control**: You control all data sharing through integrations

## 🏗️ **Technical Details**

- **Language**: Swift 5.9
- **Framework**: SwiftUI + AppKit
- **Architecture**: MVVM with ObservableObject
- **Storage**: UserDefaults with JSON encoding + immediate sync
- **Monitoring**: NSPasteboard polling (0.5s intervals)
- **UI**: Native macOS controls with custom theming
- **Integrations**: URLSession for webhooks, NSWorkspace for apps
- **Updates**: GitHub API with automatic DMG installation

## 📚 **Available Commands**

- `make build` - Build the application
- `make run` - Run the application  
- `make clean` - Clean build artifacts
- `make install` - Install to /usr/local/bin
- `make app-bundle` - Create macOS app bundle
- `make create-dmg` - Generate installer DMG
- `make deploy` - Build and release to GitHub
- `make help` - Show available commands

## 🎉 **Coming Soon**

- 📱 **iOS Companion App** - Sync with iPhone/iPad via iCloud
- 📊 **Statistics Dashboard** - Usage analytics and insights
- 📁 **File Path Copying** - Support for file references
- 🔄 **Cloud Sync Options** - Multiple cloud service support
- 🎨 **More Themes** - Additional color schemes and customization

---

**Enjoy your powerful, feature-rich macOS clipboard manager!** 🚀

*Transform your copy-paste workflow with advanced features, beautiful design, and seamless integrations.*