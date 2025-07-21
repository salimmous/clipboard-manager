#!/bin/bash

# Version Bump Script for ClipboardManager
# Automatically increments version and updates all relevant files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📈 ClipboardManager Version Bump Script${NC}"
echo "==========================================="

# Function to increment version
increment_version() {
    local version=$1
    local type=$2
    
    IFS='.' read -ra PARTS <<< "$version"
    local major=${PARTS[0]}
    local minor=${PARTS[1]}
    local patch=${PARTS[2]}
    
    case $type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo -e "${RED}❌ Invalid version type: $type${NC}"
            exit 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Get current version from Info.plist
CURRENT_VERSION=$(plutil -p Info.plist | grep CFBundleShortVersionString | awk '{print $3}' | tr -d '"')
echo -e "${YELLOW}📋 Current version: $CURRENT_VERSION${NC}"

# Ask user for version bump type
echo -e "${BLUE}🔢 Select version bump type:${NC}"
echo "1) Patch (bug fixes): $CURRENT_VERSION -> $(increment_version $CURRENT_VERSION patch)"
echo "2) Minor (new features): $CURRENT_VERSION -> $(increment_version $CURRENT_VERSION minor)"
echo "3) Major (breaking changes): $CURRENT_VERSION -> $(increment_version $CURRENT_VERSION major)"
echo "4) Custom version"
echo "5) Cancel"

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        NEW_VERSION=$(increment_version $CURRENT_VERSION patch)
        BUMP_TYPE="patch"
        ;;
    2)
        NEW_VERSION=$(increment_version $CURRENT_VERSION minor)
        BUMP_TYPE="minor"
        ;;
    3)
        NEW_VERSION=$(increment_version $CURRENT_VERSION major)
        BUMP_TYPE="major"
        ;;
    4)
        read -p "Enter custom version (e.g., 2.0.0): " NEW_VERSION
        BUMP_TYPE="custom"
        ;;
    5)
        echo -e "${YELLOW}⏭️  Version bump cancelled${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

# Validate version format
if [[ ! $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Invalid version format: $NEW_VERSION${NC}"
    echo "Version should be in format: major.minor.patch (e.g., 1.2.3)"
    exit 1
fi

echo -e "${BLUE}🚀 Bumping version from $CURRENT_VERSION to $NEW_VERSION${NC}"

# Update Info.plist
echo -e "${YELLOW}📝 Updating Info.plist...${NC}"
plutil -replace CFBundleShortVersionString -string "$NEW_VERSION" Info.plist
plutil -replace CFBundleVersion -string "$NEW_VERSION" Info.plist

# Update main.swift - currentVersion
echo -e "${YELLOW}📝 Updating main.swift...${NC}"
sed -i '' "s/let currentVersion = \".*\"/let currentVersion = \"$NEW_VERSION\"/g" Sources/main.swift

# Update main.swift - footer version
sed -i '' "s/Text(\"v.*\")/Text(\"v$NEW_VERSION\")/g" Sources/main.swift

# Update main.swift - About view version
sed -i '' "s/Version [0-9]\+\.[0-9]\+\.[0-9]\+/Version $NEW_VERSION/g" Sources/main.swift

# Update create_dmg.sh
echo -e "${YELLOW}📝 Updating create_dmg.sh...${NC}"
sed -i '' "s/VERSION=\".*\"/VERSION=\"$NEW_VERSION\"/g" create_dmg.sh

# Update README.md if it contains version info
if [ -f "README.md" ] && grep -q "Version" README.md; then
    echo -e "${YELLOW}📝 Updating README.md...${NC}"
    sed -i '' "s/Version [0-9]\+\.[0-9]\+\.[0-9]\+/Version $NEW_VERSION/g" README.md
fi

# Create changelog entry
echo -e "${YELLOW}📝 Creating changelog entry...${NC}"
if [ ! -f "CHANGELOG.md" ]; then
    cat > CHANGELOG.md << EOF
# Changelog

All notable changes to ClipboardManager will be documented in this file.

## [Unreleased]

EOF
fi

# Add new version entry to changelog
DATE=$(date +"%Y-%m-%d")
TEMP_FILE=$(mktemp)

# Read the changelog and insert new version
awk -v version="$NEW_VERSION" -v date="$DATE" -v type="$BUMP_TYPE" '
/^## \[Unreleased\]/ {
    print $0
    print ""
    print "## [" version "] - " date
    if (type == "major") {
        print "### Breaking Changes"
        print "- Major version update with breaking changes"
    } else if (type == "minor") {
        print "### Added"
        print "- New features and enhancements"
    } else {
        print "### Fixed"
        print "- Bug fixes and improvements"
    }
    print ""
    next
}
{ print }
' CHANGELOG.md > "$TEMP_FILE" && mv "$TEMP_FILE" CHANGELOG.md

echo -e "${GREEN}✅ Version bumped successfully!${NC}"
echo -e "${BLUE}📋 Summary of changes:${NC}"
echo "  • Info.plist: $CURRENT_VERSION → $NEW_VERSION"
echo "  • main.swift: Updated version references"
echo "  • create_dmg.sh: Updated version"
echo "  • CHANGELOG.md: Added new version entry"

echo -e "${YELLOW}⚠️  Next steps:${NC}"
echo "1. Review the changes: git diff"
echo "2. Test the application: swift run"
echo "3. Deploy new version: ./deploy.sh"
echo "4. Or commit manually: git add . && git commit -m 'Bump version to $NEW_VERSION'"

read -p "Do you want to run the deployment script now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🚀 Starting deployment...${NC}"
    ./deploy.sh
else
    echo -e "${YELLOW}📝 Remember to deploy when ready: ./deploy.sh${NC}"
fi