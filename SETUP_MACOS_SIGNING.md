# macOS Code Signing Setup

This document explains how to set up code signing for local development.

## Prerequisites

1. **Apple Developer Account** ($99/year)
2. **Xcode Command Line Tools**: `xcode-select --install`
3. **Code Signing Certificate** installed in Keychain

## Setup Steps

### 1. Find Your Signing Identity

```bash
security find-identity -v -p codesigning
```

Look for a line like:
```
1) ABCD1234... "Apple Development: Your Name (XXXXXXXXXX)"
```

Copy the **full SHA-1 hash** (the long hex string).

### 2. Create Local Build Configuration

```bash
cp build-config.sh.example build-config.sh
```

Edit `build-config.sh` and set:
- `BUNDLE_ID`: Your Apple Developer bundle identifier (e.g., `com.yourname.appname`)
- `SIGNING_IDENTITY`: The SHA-1 hash from step 1

### 3. Create Entitlements File

```bash
cp Entitlements.plist.example Entitlements.plist
```

Modify `Entitlements.plist` as needed for your app's capabilities.

### 4. Download Provisioning Profile (Optional)

For distribution or restricted entitlements:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/profiles)
2. Create/download a provisioning profile for your Bundle ID
3. Install it: `open YourProfile.provisionprofile`

### 5. Build the App

```bash
make build
```

Or directly:
```bash
./scripts/build-app-bundle.sh
```

## Files (Git Status)

- ✅ **Committed** (safe to share):
  - `build-config.sh.example`
  - `Entitlements.plist.example`
  - `Info.plist.example`
  - `scripts/build-app-bundle.sh`

- ❌ **Not committed** (personal/sensitive):
  - `build-config.sh` - Your signing identity
  - `Entitlements.plist` - Your app's capabilities
  - `Info.plist` - Generated with your bundle ID
  - `*.provisionprofile` - Your provisioning profiles

## Troubleshooting

### "Ambiguous signing identity"

You have duplicate certificates. Use the SHA-1 hash instead of the certificate name in `build-config.sh`.

### "No matching profile found"

Your Mac's UDID isn't in the provisioning profile. Get your UDID:
```bash
system_profiler SPHardwareDataType | grep "Provisioning UDID"
```

Add it to your provisioning profile in Apple Developer Portal.

### "Code signature validation failed"

Ensure the entitlements in `Entitlements.plist` match what's in your provisioning profile.
