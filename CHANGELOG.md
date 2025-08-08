# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [1.1.12] - 2025-08-01
### Added
- Universal binary support (Intel x86_64 + Apple Silicon arm64)
- Professional DMG installer generation via Makefile
- Automated installation script (`install.sh`)
- Entitlements file for proper permissions (`ClipboardManager.entitlements`)

### Changed
- Build system updated to produce a true universal binary (separate arch builds + lipo)
- `Info.plist` version bump to 1.1.12
- Resource loading updated to use bundle paths (no hardcoded user paths)
- Makefile enhanced with `build-intel`, `build-arm64`, `create-universal`, `app-bundle`, and `create-dmg`

### Fixed
- Removed hardcoded absolute image/icon paths from `Sources/main.swift`
- Addressed DMG unmount reliability during creation

### Notes
- Compatible with macOS 13.0+ (Ventura and later)
- Ready for global distribution; works on any Mac

[1.1.12]: https://github.com/salimmous/clipboard-manager/releases/tag/v1.1.12
