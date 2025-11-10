#!/bin/bash
set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load local configuration (not in git)
if [ -f "$PROJECT_ROOT/build-config.sh" ]; then
    source "$PROJECT_ROOT/build-config.sh"
else
    echo "Error: build-config.sh not found!"
    echo "Copy build-config.sh.example to build-config.sh and configure your signing identity"
    exit 1
fi

# Configuration
APP_NAME="Setlist Playlist Builder"
BINARY_NAME="setlist_to_playlist"
BUILD_DIR="$PROJECT_ROOT/target/release"
APP_BUNDLE="$PROJECT_ROOT/target/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== Building App Bundle ==="
echo "App Name: $APP_NAME"
echo "Bundle ID: $BUNDLE_ID"
echo ""

# Step 1: Build release binary
echo "1. Building release binary..."
cargo build --release
echo "   ✓ Binary built"
echo ""

# Step 2: Create app bundle structure
echo "2. Creating app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
echo "   ✓ Bundle structure created"
echo ""

# Step 3: Copy binary
echo "3. Copying binary..."
cp "$BUILD_DIR/$BINARY_NAME" "$MACOS_DIR/$BINARY_NAME"
chmod +x "$MACOS_DIR/$BINARY_NAME"
echo "   ✓ Binary copied"
echo ""

# Step 4: Generate Info.plist with bundle ID
echo "4. Generating Info.plist..."
if [ ! -f "$PROJECT_ROOT/Info.plist" ]; then
    if [ ! -f "$PROJECT_ROOT/Info.plist.example" ]; then
        echo "   ✗ Error: Info.plist.example not found"
        exit 1
    fi
    sed "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$BUNDLE_ID/g" "$PROJECT_ROOT/Info.plist.example" > "$PROJECT_ROOT/Info.plist"
fi
cp "$PROJECT_ROOT/Info.plist" "$CONTENTS_DIR/Info.plist"
echo "   ✓ Info.plist generated"
echo ""

# Step 5: Embed provisioning profile (if available)
echo "5. Looking for provisioning profile..."
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PROFILE_DIR" ]; then
    # Find a profile matching our bundle ID
    PROFILE=$(find "$PROFILE_DIR" -name "*.provisionprofile" -exec grep -l "$BUNDLE_ID" {} \; | head -1)
    if [ -n "$PROFILE" ]; then
        mkdir -p "$CONTENTS_DIR"
        cp "$PROFILE" "$CONTENTS_DIR/embedded.provisionprofile"
        echo "   ✓ Provisioning profile embedded"
    else
        echo "   ⚠️  No provisioning profile found for $BUNDLE_ID"
        echo "   You need to create one in Xcode with MusicKit capability"
    fi
else
    echo "   ⚠️  No provisioning profiles directory found"
fi
echo ""

# Step 6: Sign the app bundle
echo "6. Signing app bundle..."
echo "   Looking for signing identity: $SIGNING_IDENTITY"

# Check if we have a valid signing identity
if security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
    codesign --force --deep --options runtime \
        --entitlements "$PROJECT_ROOT/Entitlements.plist" \
        --sign "$SIGNING_IDENTITY" \
        "$APP_BUNDLE"
    echo "   ✓ App bundle signed with: $SIGNING_IDENTITY"
else
    echo "   ⚠️  Warning: No valid signing identity found"
    echo "   Using ad-hoc signing with entitlements..."
    codesign --force --deep \
        --entitlements "$PROJECT_ROOT/Entitlements.plist" \
        --sign "-" \
        "$APP_BUNDLE"
    echo "   ⚠️  App bundle signed ad-hoc (requires Apple Developer account for MusicKit)"
fi
echo ""

# Step 6: Verify signature (if signed)
if codesign -v "$APP_BUNDLE" 2>/dev/null; then
    echo "6. Verifying signature..."
    codesign -dvv "$APP_BUNDLE"
    echo ""
    echo "   ✓ Signature verified"
    echo ""
fi

echo "=== Build Complete ==="
echo "App bundle created at: $APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "To test from command line (with entitlements):"
echo "  \"$MACOS_DIR/$BINARY_NAME\""
