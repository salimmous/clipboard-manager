# Makefile for Clipboard Manager - macOS Distribution Build

.PHONY: build test run clean install app-bundle codesign create-dmg deploy test-app help

SWIFT_BUILD_FLAGS = -c release
VERSION := $(shell plutil -extract CFBundleShortVersionString raw Info.plist)
DMG_NAME := ClipboardManager-$(VERSION)-Installer.dmg

build:
	@echo "Building Clipboard Manager v$(VERSION)..."
	swift build $(SWIFT_BUILD_FLAGS)
	@echo "✅ Build complete!"

test:
	@echo "Running unit tests..."
	swift test

run:
	@echo "Running Clipboard Manager..."
	swift run

clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	rm -rf ClipboardManager.app

install: build
	@echo "Installing Clipboard Manager..."
	cp .build/release/ClipboardManager /usr/local/bin/clipboard-manager
	@echo "Clipboard Manager installed to /usr/local/bin/clipboard-manager"

app-bundle: build
	@echo "Creating app bundle v$(VERSION)..."
	rm -rf ClipboardManager.app
	mkdir -p ClipboardManager.app/Contents/MacOS
	mkdir -p ClipboardManager.app/Contents/Resources
	cp .build/release/ClipboardManager ClipboardManager.app/Contents/MacOS/
	cp Info.plist ClipboardManager.app/Contents/
	if [ -f AppIcon.icns ]; then cp AppIcon.icns ClipboardManager.app/Contents/Resources/AppIcon.icns; fi
	if [ -d AppIcon.iconset ]; then cp -r AppIcon.iconset ClipboardManager.app/Contents/Resources/; fi
	if [ -f "logos/Assets.xcassets/AppIcon.appiconset/32.png" ]; then \
		mkdir -p ClipboardManager.app/Contents/Resources/Assets.xcassets/AppIcon.appiconset/; \
		cp logos/Assets.xcassets/AppIcon.appiconset/* ClipboardManager.app/Contents/Resources/Assets.xcassets/AppIcon.appiconset/; \
	fi
	chmod +x ClipboardManager.app/Contents/MacOS/ClipboardManager
	@echo "App bundle created: ClipboardManager.app"

codesign: app-bundle
	@echo "Code signing app bundle..."
	@if [ -n "$$DEVELOPER_ID" ]; then \
		codesign --force --deep --entitlements ClipboardManager.entitlements --sign "Developer ID Application: $$DEVELOPER_ID" --options runtime ClipboardManager.app; \
	else \
		echo "No DEVELOPER_ID set; applying ad-hoc signature."; \
		codesign --force --deep --sign - ClipboardManager.app; \
	fi

create-dmg: app-bundle
	@echo "Creating $(DMG_NAME)..."
	chmod +x create_dmg.sh
	./create_dmg.sh

deploy: test build app-bundle create-dmg
	@echo "Distribution package created: ClipboardManager.app & $(DMG_NAME)"

test-app: app-bundle
	@echo "Inspecting ClipboardManager.app..."
	find ClipboardManager.app -type f -name "*.plist" -o -name "ClipboardManager" | sort
	lipo -info ClipboardManager.app/Contents/MacOS/ClipboardManager

help:
	@echo "Targets: build, test, run, clean, install, app-bundle, codesign, create-dmg, deploy, test-app"

default: build
