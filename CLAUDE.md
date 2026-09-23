# Soundscape iOS Sector Card

## Purpose

Native iOS client for Soundscape.

## Invariants

- Features import contracts, never networking implementations.
- Only `Shared/Networking` may use `URLSession`.
- Only `Shared/Infrastructure` may use Keychain APIs.
- Backend paths and form keys have one typed home in `Shared/Contracts`.
- No fallback success for network, AI, auth, recording, or publish failures.
- No credentials, raw audio, private coordinates, or response bodies in logs.
- All collection views use stable IDs and expose loading, empty, and error states.

## Verification

Run `scripts/ci.sh` before handoff.

## Build / Release

- **Stable Xcode**: `/Users/wilsonxu/Applications/Xcode-26.6.0.app` (Xcode 26.6, 17F113)
- **Use with**: `DEVELOPER_DIR=/Users/wilsonxu/Applications/Xcode-26.6.0.app/Contents/Developer xcodebuild ...`
- **Simulator target**: always build, install, and verify against the DeviceHub simulator named `Soundscape Store 6.7`; resolve its UDID live. Do not substitute the unrelated `Klik new UI` simulator.
- **Archive**: `DEVELOPER_DIR=... xcodebuild archive -project Soundscape.xcodeproj -scheme Soundscape -archivePath /tmp/Soundscape.xcarchive -destination "generic/platform=iOS" -configuration Release`
- **Upload to ASC**: `DEVELOPER_DIR=... xcodebuild -exportArchive -archivePath /tmp/Soundscape.xcarchive -exportOptionsPlist scripts/AppStoreUploadOptions.plist -exportPath /tmp/Soundscape_Export -allowProvisioningUpdates`
- **Critical**: Must set `PATH="/usr/bin:/bin:$PATH"` before upload to avoid Homebrew rsync incompatibility (`--extended-attributes` flag).
- **⚠️ Never use Xcode-beta for ASC submission** — ASC rejects beta SDK builds.
