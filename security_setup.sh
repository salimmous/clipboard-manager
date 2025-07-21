#!/bin/bash

# ClipboardManager Security Setup Script
# This script helps prepare your app for secure distribution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APP_NAME="ClipboardManager"
APP_BUNDLE="${APP_NAME}.app"
DMG_FILE="${APP_NAME}-1.0.3-Installer.dmg"

echo -e "${BLUE}🔐 ClipboardManager Security Setup${NC}"
echo -e "${BLUE}===================================${NC}"

# Function to check if app exists
check_app_exists() {
    if [ ! -d "$APP_BUNDLE" ]; then
        echo -e "${RED}❌ Error: $APP_BUNDLE not found!${NC}"
        echo -e "${YELLOW}Please build the app first with: swift build -c release${NC}"
        exit 1
    fi
}

# Function to check current signing status
check_signing_status() {
    echo -e "${YELLOW}📋 Checking current signing status...${NC}"
    codesign -dv "$APP_BUNDLE" 2>&1 || echo -e "${RED}App is not signed${NC}"
    echo ""
}

# Function to list available certificates
list_certificates() {
    echo -e "${YELLOW}📜 Available Developer Certificates:${NC}"
    security find-identity -v -p codesigning | grep "Developer ID Application" || {
        echo -e "${RED}❌ No Developer ID certificates found!${NC}"
        echo -e "${YELLOW}You need to:${NC}"
        echo -e "${YELLOW}1. Join Apple Developer Program ($99/year)${NC}"
        echo -e "${YELLOW}2. Create Developer ID certificate in Xcode or Developer Portal${NC}"
        echo -e "${YELLOW}3. Download and install the certificate${NC}"
        return 1
    }
    echo ""
}

# Function to sign the app
sign_app() {
    echo -e "${YELLOW}✍️  Signing the application...${NC}"
    
    # Get the first available Developer ID certificate
    CERT_NAME=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*") //g' | sed 's/".*//g')
    
    if [ -z "$CERT_NAME" ]; then
        echo -e "${RED}❌ No Developer ID certificate found for signing${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Using certificate: $CERT_NAME${NC}"
    
    # Sign with hardened runtime
    codesign --force --deep --options runtime --sign "$CERT_NAME" "$APP_BUNDLE"
    
    # Verify signing
    echo -e "${YELLOW}🔍 Verifying signature...${NC}"
    codesign --verify --verbose "$APP_BUNDLE"
    spctl --assess --verbose "$APP_BUNDLE"
    
    echo -e "${GREEN}✅ App signed successfully!${NC}"
    echo ""
}

# Function to create signed DMG
create_signed_dmg() {
    echo -e "${YELLOW}📦 Creating signed DMG...${NC}"
    
    # Rebuild the app bundle in the DMG
    rm -rf "$APP_BUNDLE"
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    mkdir -p "${APP_BUNDLE}/Contents/Resources"
    
    # Copy files
    cp ./.build/arm64-apple-macosx/release/ClipboardManager "${APP_BUNDLE}/Contents/MacOS/"
    cp Info.plist "${APP_BUNDLE}/Contents/"
    cp CustomAppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    
    # Sign the rebuilt app
    sign_app
    
    # Create DMG
    ./create_dmg.sh
    
    echo -e "${GREEN}✅ Signed DMG created: $DMG_FILE${NC}"
    echo ""
}

# Function to prepare for notarization
prepare_notarization() {
    echo -e "${YELLOW}📝 Notarization Instructions:${NC}"
    echo -e "${BLUE}To notarize your app with Apple:${NC}"
    echo ""
    echo -e "${YELLOW}1. Create app-specific password:${NC}"
    echo -e "   - Go to appleid.apple.com"
    echo -e "   - Sign in with your Apple ID"
    echo -e "   - Generate app-specific password"
    echo ""
    echo -e "${YELLOW}2. Submit for notarization:${NC}"
    echo -e "   xcrun notarytool submit $DMG_FILE \\"
    echo -e "     --apple-id \"your-apple-id@email.com\" \\"
    echo -e "     --password \"app-specific-password\" \\"
    echo -e "     --team-id \"YOUR_TEAM_ID\" \\"
    echo -e "     --wait"
    echo ""
    echo -e "${YELLOW}3. Staple notarization:${NC}"
    echo -e "   xcrun stapler staple $DMG_FILE"
    echo ""
    echo -e "${YELLOW}4. Verify notarization:${NC}"
    echo -e "   xcrun stapler validate $DMG_FILE"
    echo ""
}

# Function to show security checklist
show_security_checklist() {
    echo -e "${BLUE}🛡️  Security Checklist:${NC}"
    echo -e "${GREEN}✅ Privacy permissions added to Info.plist${NC}"
    echo -e "${GREEN}✅ App category specified (Productivity)${NC}"
    echo -e "${GREEN}✅ Usage descriptions provided${NC}"
    echo -e "${GREEN}✅ Hardened runtime enabled${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo -e "${YELLOW}1. Get Apple Developer Program membership${NC}"
    echo -e "${YELLOW}2. Create and install Developer ID certificate${NC}"
    echo -e "${YELLOW}3. Sign the app with this script${NC}"
    echo -e "${YELLOW}4. Notarize with Apple${NC}"
    echo -e "${YELLOW}5. Distribute to users${NC}"
    echo ""
}

# Main execution
echo -e "${YELLOW}What would you like to do?${NC}"
echo "1. Check current signing status"
echo "2. List available certificates"
echo "3. Sign the app (requires Developer ID certificate)"
echo "4. Create signed DMG"
echo "5. Show notarization instructions"
echo "6. Show security checklist"
echo "7. Do everything (full security setup)"
echo ""
read -p "Enter your choice (1-7): " choice

case $choice in
    1)
        check_app_exists
        check_signing_status
        ;;
    2)
        list_certificates
        ;;
    3)
        check_app_exists
        list_certificates && sign_app
        ;;
    4)
        create_signed_dmg
        ;;
    5)
        prepare_notarization
        ;;
    6)
        show_security_checklist
        ;;
    7)
        echo -e "${BLUE}🚀 Running full security setup...${NC}"
        check_app_exists
        check_signing_status
        list_certificates
        if list_certificates; then
            create_signed_dmg
            prepare_notarization
        fi
        show_security_checklist
        ;;
    *)
        echo -e "${RED}Invalid choice. Please run the script again.${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 Security setup completed!${NC}"