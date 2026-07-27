# Clipboard Manager for macOS (v1.3.0)

**ClipboardManager** is a powerful, lightweight, native macOS clipboard management utility that transforms how you work with copied content. Built with Swift and SwiftUI, this application runs seamlessly in your menu bar, providing instant access to your clipboard history with advanced security, optical character recognition (OCR), and integrations.

<p align="center">
  <img src="assets/preview.png" width="450" alt="Clipboard Manager Interface">
</p>

---

## 🚀 **Installation Options**

Choose any of the following fast installation methods for your Mac:

### Option 1: ⚡ One-Line Terminal Command (Fastest & Recommended)
Open Terminal and run this command:
```bash
curl -fsSL https://raw.githubusercontent.com/salimmous/clipboard-manager/main/install.sh | bash
```

### Option 2: 📦 Download DMG Installer
1. 📥 **[Download ClipboardManager v1.3.0 DMG Installer](https://github.com/salimmous/clipboard-manager/releases/latest/download/ClipboardManager-1.3.0-Installer.dmg)**
2. Open `ClipboardManager-1.3.0-Installer.dmg`
3. Drag **ClipboardManager** into your **Applications** folder

### Option 3: 🌐 Global System-Wide Installation (All Users)
```bash
curl -fsSL https://raw.githubusercontent.com/salimmous/clipboard-manager/main/global-install.sh | bash
```

### Option 4: 🛠️ Build & Install from Source
```bash
git clone https://github.com/salimmous/clipboard-manager.git
cd clipboard-manager
make app-bundle
open ClipboardManager.app
```

---

## 🆕 **What's New in v1.3.0 (2026 Release)**

🎉 **Major release with Modular Swift Architecture, Vision OCR, Password Manager Security, and Quick Look Previews!**

### ✨ **Key Features**

#### 🔒 **Security & Privacy Password Manager Exclusion**
- **Automatic Password Protection**: Detects when you copy sensitive text from password managers like **1Password, Bitwarden, Keychain Access, LastPass, Dashlane, KeePassXC**, etc.
- **Privacy First**: Automatically skips storing sensitive passwords to protect your credentials.

#### 👁️ **Apple Vision OCR Image Text Recognition**
- **Text Extraction**: Uses Apple's native `VNRecognizeTextRequest` framework to recognize text in copied images and screenshots asynchronously.
- **Searchable Images**: Search for text *inside* images directly from the search bar!

#### 🔍 **Quick Look Preview (Spacebar)**
- **Instant Overlay**: Press **Spacebar** on any clipboard item to open a full Quick Look overlay window.
- View full high-resolution images, complete text contents, and extracted OCR text.

#### ⚡ **Direct Auto-Paste (⌘V)**
- **One-Click Paste**: Automatically paste selected clipboard items directly into the active application using synthetic `CGEvent` simulation.
- **Plain Text Option**: Paste as plain text to strip unwanted formatting.

#### 🧠 **Smart Content Detection**
- **Emails**: Detects email addresses — click to compose via default email app.
- **Phones**: Recognizes phone numbers — click to call via FaceTime.
- **Addresses**: Identifies addresses — click to view in Apple Maps.

#### ☁️ **iCloud Sync & Auto-Updates**
- Cross-device clipboard history sync via CloudKit.
- One-click GitHub auto-update system with DMG auto-installation.

---

## 🎯 **Quick Start & Controls**

| Shortcut / Control | Action |
| --- | --- |
| **⌘+X** | Global hotkey to toggle Clipboard Manager popup |
| **Spacebar** | Quick Look preview for highlighted item |
| **Enter** | Paste or copy selected item |
| **Esc** | Close popup / Quick Look preview |
| **↑ / ↓ Arrows** | Navigate through clipboard list |

---

## 🔒 **Privacy & Security**

- **Local Storage**: All clipboard history is stored locally in `~/Library/Application Support/ClipboardManager/`.
- **Password Manager Skip**: Password managers are automatically excluded from clipboard history.
- **Zero External Tracking**: No user data or analytics sent to external servers.

---

## 📄 **License & Copyright**

Copyright © 2026. All rights reserved.  
Licensed under the MIT License.