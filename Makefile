# Makefile for Clipboard Manager

.PHONY: build run clean install

# Build the application
build:
	@echo "Building Clipboard Manager..."
	swift build -c release

# Run the application
run:
	@echo "Running Clipboard Manager..."
	swift run

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build

# Install the application to /usr/local/bin
install: build
	@echo "Installing Clipboard Manager..."
	cp .build/release/ClipboardManager /usr/local/bin/clipboard-manager
	@echo "Clipboard Manager installed successfully!"
	@echo "You can now run it with: clipboard-manager"

# Create an app bundle (requires additional setup)
app-bundle: build
	@echo "Creating app bundle..."
	mkdir -p ClipboardManager.app/Contents/MacOS
	mkdir -p ClipboardManager.app/Contents/Resources
	cp .build/release/ClipboardManager ClipboardManager.app/Contents/MacOS/
	cp Info.plist ClipboardManager.app/Contents/
	cp AppIcon.icns ClipboardManager.app/Contents/Resources/
	cp logo.png ClipboardManager.app/Contents/Resources/
	@echo "App bundle created: ClipboardManager.app"
	@echo "You can now drag ClipboardManager.app to your Applications folder!"

# Show help
help:
	@echo "Available commands:"
	@echo "  build      - Build the application"
	@echo "  run        - Run the application"
	@echo "  clean      - Clean build artifacts"
	@echo "  install    - Install to /usr/local/bin"
	@echo "  app-bundle - Create macOS app bundle"
	@echo "  help       - Show this help message"

default: build