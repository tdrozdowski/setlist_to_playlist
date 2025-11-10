# macOS App Bundle Setup Guide

This guide explains how to set up proper MusicKit entitlements for the Setlist Playlist Builder app.

## Why You Need This

The demo works but gets "Permission denied" when searching Apple Music because:
- CLI binaries don't have entitlements by default
- MusicKit requires the `com.apple.developer.music-kit` entitlement
- Entitlements require code signing with an Apple Developer certificate

## Prerequisites

### Required:
1. **Apple Developer Account** ($99/year)
   - Sign up at: https://developer.apple.com/programs/

2. **Xcode** (free)
   - Install from Mac App Store
   - Opens access to code signing

3. **Active Apple Music Subscription**
   - Required for MusicKit to work

## Setup Steps

### 1. Configure Your Apple Developer Account

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create a new **App ID**:
   - Platform: macOS
   - Bundle ID: `com.yourcompany.setlist-to-playlist` (change to your own)
   - Enable **MusicKit** capability
   - Save

### 2. Update Bundle Identifier

Edit `Info.plist` and change the bundle identifier to match your App ID:

```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.setlist-to-playlist</string>  <!-- Change this -->
```

Also update `scripts/build-app-bundle.sh`:

```bash
BUNDLE_ID="com.yourcompany.setlist-to-playlist"  # Change this
```

### 3. Get Your Signing Identity

Check available code signing identities:

```bash
security find-identity -v -p codesigning
```

You should see something like:
```
1) ABC123... "Apple Development: Your Name (TEAM123)"
2) DEF456... "Developer ID Application: Your Name (TEAM123)"
```

The script will automatically use "Apple Development" for development builds.

### 4. Build the App Bundle

```bash
make app-bundle
```

This will:
1. Build the release binary
2. Create the `.app` bundle structure
3. Copy Info.plist and entitlements
4. Code sign the bundle

### 5. Run the Signed App

```bash
open "target/Setlist Playlist Builder.app"
```

Or directly:

```bash
"target/Setlist Playlist Builder.app/Contents/MacOS/setlist_to_playlist"
```

## Verification

### Check Code Signature

```bash
codesign -dvv "target/Setlist Playlist Builder.app"
```

Should show:
- Identifier: your bundle ID
- Signing identity
- Entitlements including `com.apple.developer.music-kit`

### Check Entitlements

```bash
codesign -d --entitlements - "target/Setlist Playlist Builder.app"
```

Should show the MusicKit entitlement.

## Troubleshooting

### "No signing identity found"

**Problem**: The build script can't find a valid signing certificate.

**Solution**:
1. Open Xcode
2. Go to Preferences > Accounts
3. Add your Apple Developer account
4. Download certificates
5. Try `make app-bundle` again

### "Permission denied" still occurs

**Possible causes**:
1. **Bundle ID mismatch**: Ensure Info.plist matches your App ID
2. **MusicKit not enabled**: Check your App ID in Apple Developer portal
3. **Not signed**: Verify with `codesign -dvv`
4. **No Apple Music subscription**: MusicKit requires active subscription

### "Code signature invalid"

**Problem**: macOS quarantine flag on downloaded binaries.

**Solution**:
```bash
xattr -cr "target/Setlist Playlist Builder.app"
codesign --force --options runtime \
  --entitlements Entitlements.plist \
  --sign "Apple Development" \
  "target/Setlist Playlist Builder.app"
```

## Files Created

- `Entitlements.plist` - MusicKit and network entitlements
- `Info.plist` - App bundle metadata and usage descriptions
- `scripts/build-app-bundle.sh` - Build and signing script

## Development Workflow

### For Testing (with entitlements):
```bash
make app-bundle
open "target/Setlist Playlist Builder.app"
```

### For Distribution:
Use "Developer ID Application" certificate:
```bash
# Edit scripts/build-app-bundle.sh:
SIGNING_IDENTITY="Developer ID Application"

make app-bundle
```

Then notarize with Apple (required for distribution outside Mac App Store):
```bash
xcrun notarytool submit "target/Setlist Playlist Builder.app" \
  --apple-id your-email@example.com \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

## Alternative: Run Without Signing (Limited)

If you don't have an Apple Developer account, you can:

1. Test the FFI bridge (works without entitlements):
   ```bash
   cargo run  # The "Hello from Swift" test will work
   ```

2. Mock the MusicKit calls for development
3. Wait until you're ready to publish before getting a developer account

## Next Steps

Once the app bundle works with MusicKit:
1. Test the full search functionality
2. Implement playlist creation
3. Add proper error handling for authorization failures
4. Consider building a GUI instead of CLI

## Resources

- [Apple Developer Program](https://developer.apple.com/programs/)
- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [App Notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
