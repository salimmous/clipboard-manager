# Makefile for Clipboard Manager - Universal Distribution Build

.PHONY: build run clean install app-bundle create-dmg deploy help

# Build configurations
SWIFT_BUILD_FLAGS = -c release

# Build the application (universal binary)
build: build-intel build-arm64 create-universal
	@echo "✅ Universal binary created successfully!"

# Build for Intel Macs
build-intel:
	@echo "Building Clipboard Manager (Intel)..."
	swift build $(SWIFT_BUILD_FLAGS) -Xswiftc -target -Xswiftc x86_64-apple-macos13.0
	@mkdir -p .build/universal
	@cp .build/release/ClipboardManager .build/universal/ClipboardManager-intel

# Build for Apple Silicon
build-arm64:
	@echo "Building Clipboard Manager (Apple Silicon)..."
	swift build $(SWIFT_BUILD_FLAGS) -Xswiftc -target -Xswiftc arm64-apple-macos13.0
	@mkdir -p .build/universal
	@cp .build/release/ClipboardManager .build/universal/ClipboardManager-arm64

# Create universal binary
create-universal:
	@echo "Creating universal binary..."
	@lipo -create .build/universal/ClipboardManager-intel .build/universal/ClipboardManager-arm64 -output .build/universal/ClipboardManager
	@cp .build/universal/ClipboardManager .build/release/ClipboardManager
	@echo "✅ Universal binary created: Intel + Apple Silicon"

# Run the application
run:
	@echo "Running Clipboard Manager..."
	swift run

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	rm -rf ClipboardManager.app
	rm -rf ClipboardManager-*.dmg

# Install the application to /usr/local/bin
install: build
	@echo "Installing Clipboard Manager..."
	cp .build/release/ClipboardManager /usr/local/bin/clipboard-manager
	@echo "Clipboard Manager installed successfully!"
	@echo "You can now run it with: clipboard-manager"

# Create an app bundle (distribution ready)
app-bundle: build
	@echo "Creating distribution-ready app bundle..."
	mkdir -p ClipboardManager.app/Contents/MacOS
	mkdir -p ClipboardManager.app/Contents/Resources
	cp .build/release/ClipboardManager ClipboardManager.app/Contents/MacOS/
	cp Info.plist ClipboardManager.app/Contents/
	
	# Copy app icon if available
	if [ -f AppIcon.icns ]; then cp AppIcon.icns ClipboardManager.app/Contents/Resources/AppIcon.icns; fi
	if [ -d AppIcon.iconset ]; then cp -r AppIcon.iconset ClipboardManager.app/Contents/Resources/; fi
	
	# Copy additional resources
	if [ -f "logos/Assets.xcassets/AppIcon.appiconset/32.png" ]; then \
		mkdir -p ClipboardManager.app/Contents/Resources/Assets.xcassets/AppIcon.appiconset/; \
		cp logos/Assets.xcassets/AppIcon.appiconset/* ClipboardManager.app/Contents/Resources/Assets.xcassets/AppIcon.appiconset/; \
	fi
	
	@echo "App bundle created: ClipboardManager.app"
	@echo "You can now drag ClipboardManager.app to your Applications folder!"

# Code sign the app bundle (optional - for distribution)
codesign: app-bundle
	@echo "Code signing app bundle..."
	@if [ -n "$$DEVELOPER_ID" ]; then \
		echo "Signing with Developer ID: $$DEVELOPER_ID"; \
		codesign --force --deep --sign "Developer ID Application: $$DEVELOPER_ID" --options runtime ClipboardManager.app; \
	else \
		echo "No DEVELOPER_ID set. Skipping code signing."; \
		echo "To sign, set DEVELOPER_ID environment variable or run manually:"; \
		echo "  codesign --force --deep --sign 'Developer ID Application: YOUR_NAME' --options runtime ClipboardManager.app"; \
	fi

# Create DMG installer
create-dmg: app-bundle
	@echo "Creating DMG installer..."
	@if command -v create-dmg >/dev/null 2>&1; then \
		create-dmg \
			--volname "Install ClipboardManager" \
			--window-pos 200 120 \
			--window-size 600 300 \
			--icon-size 100 \
			--icon "ClipboardManager.app" 175 120 \
			--hide-extension "ClipboardManager.app" \
			--app-drop-link 425 120 \
			"ClipboardManager-1.1.13-Installer.dmg" \
			"ClipboardManager.app"; \
	else \
		echo "create-dmg not found. Installing via Homebrew..."; \
		brew install create-dmg; \
		create-dmg \
			--volname "Install ClipboardManager" \
			--window-pos 200 120 \
			--window-size 600 300 \
			--icon-size 100 \
			--icon "ClipboardManager.app" 175 120 \
			--hide-extension "ClipboardManager.app" \
			--app-drop-link 425 120 \
			"ClipboardManager-1.1.13-Installer.dmg" \
			"ClipboardManager.app"; \
	fi

# Build and deploy (complete distribution package)
deploy: clean build app-bundle create-dmg
	@echo "Distribution package created successfully!"
	@echo "Files created:"
	@echo "  - ClipboardManager.app (Universal Binary)"
	@echo "  - ClipboardManager-1.1.13-Installer.dmg"
	@echo ""
	@echo "For code signing, run:"
	@echo "  DEVELOPER_ID='Your Developer ID' make codesign"
	@echo ""
	@echo "For notarization, run:"
	@echo "  xcrun notarytool submit ClipboardManager-1.1.13-Installer.dmg --apple-id 'your-apple-id' --password 'your-app-specific-password' --team-id 'your-team-id'"

# Test the app bundle
test-app: app-bundle
	@echo "Testing app bundle..."
	@if [ -d "ClipboardManager.app" ]; then \
		echo "App bundle structure:"; \
		find ClipboardManager.app -type f -name "*.plist" -o -name "ClipboardManager" | sort; \
		echo ""; \
		echo "Universal binary info:"; \
		lipo -info ClipboardManager.app/Contents/MacOS/ClipboardManager; \
		echo ""; \
		echo "Testing launch..."; \
		./ClipboardManager.app/Contents/MacOS/ClipboardManager --help 2>/dev/null || echo "App launched successfully"; \
	else \
		echo "App bundle not found. Run 'make app-bundle' first."; \
	fi

# Show help
help:
	@echo "Available commands:"
	@echo "  build         - Build universal binary (Intel + Apple Silicon)"
	@echo "  build-intel   - Build for Intel Macs only"
	@echo "  build-arm64   - Build for Apple Silicon Macs only"
	@echo "  run           - Run the application"
	@echo "  clean         - Clean build artifacts"
	@echo "  install       - Install to /usr/local/bin"
	@echo "  app-bundle    - Create macOS app bundle"
	@echo "  codesign      - Code sign app bundle (requires DEVELOPER_ID)"
	@echo "  create-dmg    - Create DMG installer"
	@echo "  deploy        - Complete distribution package"
	@echo "  test-app      - Test the app bundle"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  DEVELOPER_ID  - Your Developer ID for code signing"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy                                    # Create distribution package"
	@echo "  DEVELOPER_ID='Your Name' make codesign        # Code sign with your ID"
	@echo "  make test-app                                  # Test the app bundle"

default: build