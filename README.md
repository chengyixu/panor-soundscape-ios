# Soundscape iOS

Native SwiftUI client for **Soundscape**. The app preserves the existing service model while replacing the browser shell with an iPhone-first experience:

- Editorial search and recording lists.
- A compact map with selected-place cover, title, and playback controls.
- Record-style ranking lanes for place, architecture, nature, and future categories.
- Recording or file import, optional location, uploaded cover or AI-watermarked cover, then authenticated publishing.
- A personal recording archive with visibility and deletion controls.
- A full-screen physical turntable where the tonearm controls playback and track selection.
- A private resonance matcher that combines creator intent (`0.10`), collective perception (`0.30`), and session-aware user arousal (`0.60`) instead of selecting the first catalog item.

## Bootstrap

```bash
brew install xcodegen
scripts/bootstrap.sh
open Soundscape.xcodeproj
```

## Verification

```bash
scripts/ci.sh
scripts/verify-api-contract.sh
```

`scripts/ci.sh` includes repository guards, a clean simulator build, the complete unit suite, and XCUITests covering all five primary tabs. Physical-device release verification separately exercises the production API, tonearm gestures, background audio, and the Return Bar on ZLIPHONE.

The matching architecture, feedback semantics, backend feature seam, and privacy boundary are documented in `docs/domains/resonance-matching.md`. Personalization stays on device as protected numeric profiles and attributable structured events; private composition text is not persisted.

The canonical backend contract is `https://www.panor.tech/soundscape/api`. The checked-in OpenAPI snapshot is a review artifact and drift detector, not a second independently edited schema. The production route is live; verify it before release with `SOUNDSCAPE_VERIFY_LIVE=1 scripts/verify-api-contract.sh`.

Google Search Console ownership is verified through the website's Google Analytics integration. Do not remove the existing `gtag.js` tracking code from the Soundscape web deployment.

## App icon

The AppIcon is generated deterministically from the Soundscape visual language:

```bash
scripts/generate-app-icon.sh
```

The script requires ImageMagick and produces the checked-in opaque 1024×1024 source asset used by Xcode.
