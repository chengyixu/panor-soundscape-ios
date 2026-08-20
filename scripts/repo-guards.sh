#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

failures=0
fail() { printf 'FAIL %s\n' "$1" >&2; failures=$((failures + 1)); }
pass() { printf 'PASS %s\n' "$1"; }

if rg -n '^(<{7}|>{7}) ' . --glob '!Soundscape.xcodeproj/**' >/dev/null; then
  fail 'merge conflict markers detected'
else
  pass 'merge conflict markers'
fi

if rg -n 'XCTSkip|\.skip\(' Tests >/dev/null; then
  fail 'skipped tests require an explicit tracked exception'
else
  pass 'no skipped tests'
fi

if rg -n 'URLSession(\.|\()' Sources/Soundscape/Features Sources/Soundscape/App >/dev/null; then
  fail 'URLSession leaked outside Shared/Networking'
else
  pass 'URLSession boundary'
fi

if rg -n 'SecItem(Add|CopyMatching|Update|Delete)' Sources/Soundscape --glob '!**/Shared/Infrastructure/**' >/dev/null; then
  fail 'Keychain API leaked outside Shared/Infrastructure'
else
  pass 'Keychain boundary'
fi

if rg -n 'xcodebuild.*(build|test).*CODE_SIGNING_ALLOWED=NO' scripts/ci.sh >/dev/null; then
  fail 'simulator build/test disables signing and breaks Keychain entitlements'
else
  pass 'signed simulator Keychain parity'
fi

if ! rg -q 'SOUNDSCAPE_KEYCHAIN_SERVICE' Sources/Soundscape/App/AppContainer.swift || \
   ! rg -q 'launchEnvironment\["SOUNDSCAPE_KEYCHAIN_SERVICE"\]' Tests/SoundscapeUITests/SoundscapeUITests.swift; then
  fail 'XCUITests must isolate authentication from the production Keychain service'
else
  pass 'isolated XCUITest Keychain state'
fi

if rg -n 'https://www\.panor\.tech|/soundscape/api|/api/panor/auth' Sources/Soundscape --glob '!**/Shared/Contracts/APIEnvironment.swift' >/dev/null; then
  fail 'backend host/path duplicated outside APIEnvironment'
else
  pass 'single API environment source'
fi

if rg --pcre2 -n 'try\? await (?!Task\.sleep)' Sources/Soundscape >/dev/null || \
   rg -n 'catch \{[[:space:]]*\}' Sources/Soundscape >/dev/null; then
  fail 'silent asynchronous fallback detected'
else
  pass 'explicit async failures'
fi

if scripts/check-localization.sh >/dev/null; then
  pass 'complete localization boundary'
else
  fail 'localization audit failed'
fi

if rg -n 'print\(|debugPrint\(' Sources/Soundscape >/dev/null; then
  fail 'unstructured logging detected'
else
    pass 'privacy-safe logging boundary'
fi

audio_session_lifecycle='Sources/Soundscape/Shared/Media/AudioSessionLifecycle.swift'
if rg -n '\.setActive\(' Sources/Soundscape --glob '!**/AudioSessionLifecycle.swift' >/dev/null; then
  fail 'synchronous AVAudioSession activation leaked outside the lifecycle boundary'
elif ! rg -q '#available\(iOS 27\.0, \*\)' "$audio_session_lifecycle" || \
     ! rg -q '\.activate\(options:' "$audio_session_lifecycle" || \
     ! rg -q '\.deactivate\(options:' "$audio_session_lifecycle" || \
     ! rg -q 'DispatchQueue\.global' "$audio_session_lifecycle"; then
  fail 'audio session lifecycle must use native async APIs with a non-main legacy fallback'
else
  pass 'nonblocking audio session lifecycle'
fi

forbidden_product_token="$(printf '%s%s' 'vo' 'ice')"
forbidden_previous_name="$(printf '%s%s' 'the' 'ta')"
forbidden_product_pattern="(^|[^[:alnum:]_])${forbidden_product_token}([^[:alnum:]_]|$)|/${forbidden_product_token}(/|[^[:alnum:]_]|$)|${forbidden_product_token}_|(^|[^[:alnum:]_])${forbidden_previous_name}([^[:alnum:]_]|$)"
if rg -n -i "$forbidden_product_pattern" . \
  --glob '!.git/**' \
  --glob '!Soundscape.xcodeproj/**' >/dev/null; then
  fail 'non-Soundscape product token detected'
else
  pass 'Soundscape-only product naming'
fi

if rg -n '(^|[[:space:]])import[[:space:]]+ARKit|ARSession|ARWorldTrackingConfiguration|sceneDepth' Sources/Soundscape >/dev/null; then
  fail 'ARKit/capture world generation detected in iOS'
else
  pass 'AI-generated worlds remain capture-free'
fi

if rg -n -i 'ark\.cn-|volcengine|seedream|seedance|seed3d|ARK_API_KEY|VOLC_KEY' Sources/Soundscape >/dev/null; then
  fail 'AI provider implementation leaked into iOS'
else
  pass 'AI generation remains backend-owned'
fi

if rg -n 'MetalSplatter|SplatIO|SPZMetalView|WorldAssetCache' project.yml Sources/Soundscape >/dev/null || \
   rg -n '\.world\b' Sources/Soundscape/Features >/dev/null; then
  fail 'native turntable must not depend on legacy 3D world assets'
else
  pass 'turntable is independent of legacy 3D assets'
fi

if ! rg -q 'struct TurntablePlayerView' Sources/Soundscape/Features/Player/TurntablePlayerView.swift || \
   ! rg -q 'private\(set\) var presentedSoundscape' Sources/Soundscape/Shared/Media/AudioPlayerController.swift; then
  fail 'canonical turntable presentation contract is missing'
else
  pass 'canonical turntable presentation contract'
fi

turntable_presenters="$(rg -l 'TurntablePlayerView\(' Sources/Soundscape --glob '*.swift' || true)"
if [[ "$turntable_presenters" != "Sources/Soundscape/App/RootTabView.swift" ]]; then
  fail 'RootTabView must be the sole turntable presenter'
else
  pass 'single turntable presentation owner'
fi

if [[ -e Sources/Soundscape/Features/Player/MiniPlayerView.swift ]] || \
   rg -n 'MiniPlayerView|return-to-turntable' Sources Tests >/dev/null; then
  fail 'legacy return-to-turntable navigation bar detected'
else
  pass 'single primary navigation bar'
fi

if rg -q 'TabView\(' Sources/Soundscape/App/RootTabView.swift && \
   rg -q 'struct SoundscapeTabBar' Sources/Soundscape/App/RootTabView.swift; then
  fail 'custom app shell must not retain a native Liquid Glass TabView'
else
  pass 'single bottom navigation rendering system'
fi

navigation_gesture_body="$(sed -n '/private func screenTransitionGesture/,/private func vinylDragGesture/p' Sources/Soundscape/App/RootTabView.swift)"
if ! rg -q 'screenTransitionAnimation' Sources/Soundscape/App/RootTabView.swift || \
   ! rg -q 'simultaneousGesture\(screenTransitionGesture' Sources/Soundscape/App/RootTabView.swift || \
   ! printf '%s\n' "$navigation_gesture_body" | rg -q '\.onEnded' || \
   printf '%s\n' "$navigation_gesture_body" | rg -q 'navigationDrag|PlayerPagingLayout|UIGestureRecognizerRepresentable|\.offset\(x:|\.onChanged|\.updating'; then
  fail 'player navigation must be a release-triggered full-screen fade with no interactive offset'
else
  pass 'non-interactive full-screen player fade'
fi

app_icon="Resources/Assets.xcassets/AppIcon.appiconset/Soundscape-AppIcon-1024.png"
if [[ ! -s "$app_icon" ]]; then
  fail 'AppIcon PNG is missing or empty'
elif [[ "$(sips -g pixelWidth -g pixelHeight "$app_icon" 2>/dev/null | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w "x" h}')" != "1024x1024" ]]; then
  fail 'AppIcon must be exactly 1024x1024 pixels'
elif ! rg -q 'Soundscape-AppIcon-1024\.png' Resources/Assets.xcassets/AppIcon.appiconset/Contents.json; then
  fail 'AppIcon catalog does not reference the generated PNG'
else
  pass 'AppIcon asset'
fi

if ! rg -q 'path: Resources' project.yml || ! rg -q 'buildPhase: resources' project.yml; then
  fail 'XcodeGen resource build phase is missing'
elif ! rg -q '<key>UIBackgroundModes</key>' Resources/Info.plist 2>/dev/null; then
  fail 'generated Info.plist is missing background audio metadata'
else
  pass 'release resource metadata'
fi

if ! rg -q 'ITSAppUsesNonExemptEncryption: false' project.yml; then
  fail 'App Store export compliance declaration is missing'
else
  pass 'App Store export compliance declaration'
fi

google_client_id="$(plutil -extract GIDClientID raw Resources/Info.plist 2>/dev/null || true)"
google_server_client_id="$(plutil -extract GIDServerClientID raw Resources/Info.plist 2>/dev/null || true)"
google_url_scheme="$(plutil -extract CFBundleURLTypes.1.CFBundleURLSchemes.0 raw Resources/Info.plist 2>/dev/null || true)"
if [[ -z "$google_client_id" || -z "$google_server_client_id" ]]; then
  fail 'native Google OAuth client and server audience must both be configured'
elif [[ "$google_url_scheme" != "com.googleusercontent.apps.${google_client_id%.apps.googleusercontent.com}" ]]; then
  fail 'Google callback scheme must match the native iOS OAuth client'
elif rg -n 'aqku1hh67fhsoku7nqn4rk7fi3l43l?mh' Sources Resources project.yml >/dev/null; then
  fail 'desktop Google OAuth client leaked into the iOS app'
else
  pass 'native Google OAuth configuration'
fi

if ! rg -q 'account: String = "panorama_token"' Sources/Soundscape/Shared/Infrastructure/KeychainTokenStore.swift || \
   ! rg -q 'let sessionId: String' Sources/Soundscape/Shared/Contracts/IdentityContracts.swift || \
   rg -n 'let token: String|LoginCredentials[^{]*\{[^}]*username' Sources/Soundscape/Shared/Contracts/IdentityContracts.swift >/dev/null; then
  fail 'unified auth must persist sessionId as panorama_token and use email login'
else
  pass 'unified auth native session contract'
fi

if rg -n 'id\.isMultiple\(of:|id[[:space:]]*%' Sources/Soundscape/Features/Explore >/dev/null; then
  fail 'Explore geometry must not depend on backend primary keys'
else
  pass 'backend-independent Explore geometry'
fi

if ! rg -q '\.frame\(maxWidth: \.infinity, maxHeight: \.infinity, alignment: \.top\)' Sources/Soundscape/Features/DiscoveryMap/DiscoveryMapView.swift; then
  fail 'Discovery Map root must remain top-aligned in every load state'
else
  pass 'top-aligned Discovery Map root'
fi

if rg -n 'Button\("获取位置"|await model\.(locate|suggestTitle|suggestCover)\(' Sources/Soundscape/Features/Create/CreateSoundscapeView.swift >/dev/null; then
  fail 'Create flow must acquire location and generate AI metadata automatically'
elif ! rg -q 'createThinking' Sources/Soundscape/Features/Create/CreateSoundscapeView.swift || ! rg -q '\.task\(id: isActive\)' Sources/Soundscape/Features/Create/CreateSoundscapeView.swift; then
  fail 'Create flow must expose an explicit AI thinking state'
else
  pass 'automatic Create enrichment flow'
fi

if ! rg -q 'openPlayer' Sources/Soundscape/Features/Explore/ExploreView.swift || \
   ! rg -q 'openPlayer' Sources/Soundscape/Features/DiscoveryMap/DiscoveryMapView.swift || \
   ! rg -q 'openPlayer' Sources/Soundscape/Features/Rankings/RankingsView.swift || \
   ! rg -q 'openPlayer' Sources/Soundscape/Features/Library/LibraryView.swift; then
  fail 'Every playable soundscape entry point must open the turntable'
else
  pass 'turntable playback entry points'
fi

automatic_recommendation_flow="$(sed -n '/private func handleAutomaticLaunch()/,/^    }$/p' Sources/Soundscape/App/RootTabView.swift)"
private_input_recommendation_flow="$(sed -n '/private func makeSoundscape()/,/^    }$/p' Sources/Soundscape/Features/ForYou/ForYouView.swift)"
if printf '%s\n%s\n' "$automatic_recommendation_flow" "$private_input_recommendation_flow" | rg -n '\.first\b|\.explore\(' >/dev/null; then
  fail 'For You recommendation entry points must not select the first catalog item'
elif ! printf '%s\n' "$automatic_recommendation_flow" | rg -q 'matching\.returningRecommendations\(' || \
     ! printf '%s\n' "$private_input_recommendation_flow" | rg -q 'matching\.recommendations\(for:'; then
  fail 'For You recommendation entry points must use ResonanceMatching'
else
  pass 'ranked For You recommendation entry points'
fi

matching_configuration='Sources/Soundscape/Shared/Matching/ResonanceMatcher.swift'
if ! rg -q 'creatorIntentWeight: Double = 0\.1' "$matching_configuration" || \
   ! rg -q 'collectivePerceptionWeight: Double = 0\.3' "$matching_configuration" || \
   ! rg -q 'userArousalWeight: Double = 0\.6' "$matching_configuration" || \
   ! rg -q 'sessionArousal, 0\.24' "$matching_configuration" || \
   ! rg -q 'longTermArousal, 0\.08' "$matching_configuration"; then
  fail 'resonance matching weight hierarchy changed outside its typed contract'
else
  pass 'resonance matching weight hierarchy'
fi

app_container='Sources/Soundscape/App/AppContainer.swift'
protected_state_store='Sources/Soundscape/Shared/Persistence/ProtectedFileResonanceStateStore.swift'
if ! rg -q 'let matching: any ResonanceMatching' "$app_container" || \
   ! rg -q 'LocalResonanceMatchingService\(' "$app_container" || \
   ! rg -q 'store: ProtectedFileResonanceStateStore\(\)' "$app_container" || \
   ! rg -q 'AudioPlayerController\(repository: soundscapes, matching: matching\)' "$app_container"; then
  fail 'live resonance matching dependency wiring is incomplete'
elif ! rg -q '\.completeFileProtection' "$protected_state_store" || \
     ! rg -q '\.atomic' "$protected_state_store" || \
     ! rg -q 'personalization-v1\.json' "$protected_state_store"; then
  fail 'local personalization state must remain atomic and completely file-protected'
else
  pass 'protected resonance matching dependency wiring'
fi

if rg -q 'private struct VinylRecord' Sources/Soundscape/Features/Player/TurntablePlayerView.swift || \
   ! rg -q 'VinylRecordArtwork\(isRotating: player\.isPlaying\)' Sources/Soundscape/Features/Player/TurntablePlayerView.swift || \
   ! rg -q 'VinylRecordArtwork\(isRotating: player\.isPlaying\)' Sources/Soundscape/Shared/DesignSystem/VinylIndicatorButton.swift; then
  fail 'Player and floating control must share one vinyl artwork'
else
  pass 'single shared vinyl artwork'
fi

if rg -q 'exploreEyebrow|exploreDetail' Sources/Soundscape/Features/Explore/ExploreView.swift || \
   rg -q 'createEyebrow|createDetail' Sources/Soundscape/Features/Create/CreateSoundscapeView.swift; then
  fail 'Explore and Create must omit redundant eyebrow and detail copy'
else
  pass 'primary titles omit redundant eyebrow and detail copy'
fi

if [[ "$failures" -ne 0 ]]; then
  printf 'SUMMARY failures=%s\n' "$failures" >&2
  exit 1
fi
printf 'SUMMARY failures=0\n'
