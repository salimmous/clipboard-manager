# Auto-Update Setup

This guide explains how to set up the automatic update system for the ClipboardManager application.

## Requirements

- macOS 13.0 or later
- Internet connection
- Administrator privileges (for installation)

## How Auto-Updates Work

1. **Periodic Check**: The app checks for updates every 24 hours
2. **Version Comparison**: Compares current version with the latest release on GitHub
3. **Automatic Download**: If an update is available, it downloads automatically
4. **Safe Installation**: Updates are installed while preserving user data

## Available Settings

### In `main.swift` file:

```swift
// Update check interval (in seconds)
private let updateCheckInterval: TimeInterval = 24 * 60 * 60 // 24 hours

// Enable/disable automatic updates
@Published var autoInstallUpdates: Bool = true
```

### Customizing Check Interval:

```swift
// Check every 12 hours
private let updateCheckInterval: TimeInterval = 12 * 60 * 60

// Check every 6 hours
private let updateCheckInterval: TimeInterval = 6 * 60 * 60

// Check every hour (for testing)
private let updateCheckInterval: TimeInterval = 60 * 60
```

## Security Mechanisms

1. **Signature Verification**: Downloaded files are verified for authenticity
2. **Backup Creation**: A backup is created before updating
3. **Automatic Recovery**: If update fails, the previous version is restored

## Troubleshooting

### Issue: Updates not working

**Solutions:**
1. Check internet connection
2. Verify app permissions
3. Restart the application

### Issue: Failed to download update

**Solutions:**
1. Check available disk space
2. Ensure firewall isn't blocking the app
3. Try manual update

### Issue: Failed to install update

**Solutions:**
1. Close all instances of the app
2. Run app with administrator privileges
3. Download update manually from GitHub

## Manual Update

If automatic updates fail, you can update manually:

1. Go to [Releases page](https://github.com/salimmous/clipboard-manager/releases)
2. Download the latest release
3. Close the current app
4. Install the new version

## Disabling Auto-Updates

To disable automatic updates:

```swift
// In main.swift
@Published var autoInstallUpdates: Bool = false
```

Or through the app interface:
1. Open app settings
2. Turn off "Automatic Updates"

## Privacy and Security

- **No personal data collection** during update process
- **GitHub-only verification** for release information
- **HTTPS encryption** for all downloads
- **No system information sent** to external servers

## Support

For assistance:
- [Open an issue](https://github.com/salimmous/clipboard-manager/issues)
- [Review documentation](https://github.com/salimmous/clipboard-manager/wiki)
- [Contact developer](mailto:support@clipboardmanager.com)