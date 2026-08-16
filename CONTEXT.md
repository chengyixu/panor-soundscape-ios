# Context

## Product

**SOUNDSCAPE** is an intent-first listening experience built around personalized, infinitely looping audio and a tactile full-screen turntable player. First-time users begin with unrestricted text, speech, environmental recording, or optional guided Q&A. Returning users enter an automatically playing algorithm-selected soundscape.

The canonical experience contract is `docs/product/experience.md`. It owns product-facing behavior, privacy, navigation, playback, save, share, and turntable interaction requirements. Runtime and implementation documents reference that contract rather than redefining it.

The interaction contract applies to both native iOS and the web client. Native iOS is the reference client and first implementation priority; the web client mirrors the same product behavior wherever browser platform constraints permit.

The executable uses the accepted five-surface shell: For You, Explore, Map, Contribute, and Me. Rankings is a mode inside Explore. `RootTabView` owns the single custom bottom-navigation renderer and the single full-screen turntable presentation; feature views may request playback but never present another player or navigation system. The player removes the shell completely, accepts a natural center-origin right swipe to Explore without stopping audio, and restores from Explore with a center-origin left swipe. Explicit `探索` and `唱片机` actions provide discoverable fallbacks without adding another navigation bar or mini player. For You owns first-use private composition and returning recommendation entry. Save/share, immutable offline snapshots, remote command-center controls, and full private-input retention remain separate implementation slices governed by the canonical contract.

## Resonance matching

- Both first-use composition and returning launch use one `ResonanceMatching` contract; neither may fall back to the first public catalog item.
- Ranking is a staged local baseline: retrieve the public catalog, hard-filter, hydrate features, score, then apply MMR-style diversity.
- Creator intent, collective perception, and user arousal have canonical top-level weights of `0.10`, `0.30`, and `0.60` respectively.
- User arousal separates explicit current intent, a six-hour session representation, and a slower long-term representation. Temporary “Not now” feedback remains session-only.
- Raw private query, transcript, recording, and memory text is never persisted. Local state contains numeric profiles plus attributable bounded impressions and outcomes, written atomically with complete file protection.
- `SoundscapeFeatureProviding` is the contract for later backend embeddings and reviewed perceptual labels; the current provider derives deterministic features from existing metadata.
- Contextual bandits remain out of scope until the exposure-to-outcome chain contains enough real attributable data.

The canonical implementation contract is `docs/domains/resonance-matching.md`.

## Design language

- Every non-player surface uses the warm field-notebook palette, tonal screen background, terracotta eyebrow, rounded title typography, shared raised surfaces, and common action styles from `Shared/DesignSystem`.
- Every non-player surface uses the same custom five-item bottom bar. Native `TabView` or Liquid Glass tab chrome cannot coexist with it, and the player shows no bottom navigation at all.
- The title hierarchy uses restrained semantic `title` and `title2` tokens; feature screens do not use oversized fixed-point display text.
- Colors, spacing, corner radii, shadows, buttons, fields, tags, status labels, loading, empty, and error states are centralized; feature views do not invent parallel visual primitives.
- The turntable player is the dark counterpart: a rotating record, direct-manipulation tonearm, persistent title and creator attribution, and restrained secondary actions without a conventional transport-control row.
- XCUITest captures the five primary surfaces plus identity and turntable states, and separately navigates all five tabs at Accessibility XXXL Dynamic Type.

## Runtime environments

| Environment | Soundscape API | Unified auth |
|---|---|---|
| Canonical production contract | `https://www.panor.tech/soundscape/api` | `https://www.panor.tech/api/auth` |
| Unit tests | Injected in-memory repository or `URLProtocol` transport | Injected token store plus a signed real-Keychain round trip |
| XCUITests | Live app dependencies on the selected simulator | Unique per-test Keychain service supplied through `SOUNDSCAPE_KEYCHAIN_SERVICE` |

URLs live once in `APIEnvironment`; features never hardcode routes or hosts.
As of July 22, 2026, the canonical Soundscape route is live publicly. The app fails explicitly instead of falling back to another product path. Release requires a green live contract preflight against this route.

## Secrets and identity

- Registration and login email/password credentials are sent only to the unified auth API over HTTPS.
- The unified auth `sessionId` is stored in Keychain through `AuthTokenStore` under account `panorama_token` and is sent as a Bearer credential for session lookup and logout.
- Native Google Sign-In uses iOS client `692072605697-s1fr5grsef9srf2mnduq26fpa1tf1m8e.apps.googleusercontent.com` with server audience `692072605697-04nj1ecjnapmje7p2blouqac59ob59uj.apps.googleusercontent.com`; the Google Auth Platform audience is external and **In production** as of August 10, 2026.
- Native Sign in with Apple exchanges the Apple identity token and authorization code through `POST /api/auth/apple`; the backend verifies Apple issuer, signature, expiry, and audience before creating a unified session.
- Tokens, passwords, audio bytes, exact coordinates, and private soundscapes must not be logged.
- Anonymous users may explore, view maps/rankings, play, and request AI metadata. Publishing, saving, feedback, and library operations require authentication.

## Native capabilities

- Microphone: explicit user action only.
- Location: when-in-use, optional, and requested separately from microphone permission.
- Photos: picker-scoped access for a cover image.
- Audio playback/recording: AVFoundation; interruptions and route changes must surface as explicit states.

## Session language

- **First Session** — The user's first SOUNDSCAPE session, which begins with private input and does not autoplay before the user provides a personalization signal.
- **Returning Session** — Any later app session, which opens directly into an automatically playing algorithm-selected soundscape unless an existing global playback session is resumed.
- **Active Playback Session** — The in-memory global soundscape, stream position, and play or pause state preserved while the app moves between foreground and background.
- **Cold Launch** — A launch after the prior app process and Active Playback Session have ended, which begins a fresh autoplay recommendation.

## Playback language

- **Tonearm** — The direct-manipulation arm used to control stylus contact and browse ready soundscape candidates.
- **Stylus** — The endpoint whose contact with the record determines whether the active soundscape is playing or paused.
- **Paused Phase** — The exact loop position preserved while the stylus is outside the record.
- **Record Rotation** — The continuous platter motion that persists independently of playback and never represents elapsed audio time.
- **Browse Mode** — The temporary tonearm-drag state in which the active sound is softened and filtered while silent ready candidates appear on the record.
- **Recommendation Stream** — The unbounded personalized sequence exposed through the tonearm without pages, a terminal item, or a fixed visible queue.
- **Stable Stream Position** — A candidate's fixed identity and relative position after it first appears during the current listening session.
- **Ready Window** — The five-item visible Recommendation Stream window whose audio and display metadata are fully available before interaction.
- **Ready Edge** — The elastic interaction boundary at the end of currently audio-ready stream positions.
- **Selection Detent** — A discrete candidate boundary that must be crossed before tonearm release can change the active soundscape.
- **Cancel Zone** — The protected movement range around the current candidate in which release exits Browse Mode without changing soundscapes.
- **Selection Transition** — The synchronized audio and visual handoff from the ducked active soundscape to a committed stream candidate.
- **Tonearm Hit Area** — The invisible accessible touch envelope surrounding the full visible tonearm assembly.
- **Pivot Arc** — The mechanically constrained path the tonearm follows around its fixed base while finger movement is projected onto that path.
- **Contact Boundary** — The record edge that separates on-record Browse Mode from off-record Park Intent.
- **Park Intent** — The off-record tonearm state that preserves the current soundscape selection and pauses it on release.
- **Browse Reveal Threshold** — The intentional on-record movement required before the hidden Recommendation Stream becomes visible.
- **Playback Metadata** — The active soundscape title and Source Line shown below the record only outside Browse Mode.
- **Source Line** — The context-aware attribution that identifies a human creator, personalized origin, place, or public discovery source without inventing an author.
- **Reference Chrome** — The persistent top-left navigation action and top-right Save action that remain outside the turntable's playback metaphor.
- **Primary Navigation Renderer** — The single custom five-item bottom bar owned by `RootTabView` and shown only on non-player surfaces.
- **Player Reveal Gesture** — A natural center-origin right swipe from the player that reveals Explore without changing playback, paired with a center-origin left swipe from Explore that restores the player; explicit surface actions mirror both transitions.

## Creation automation

- Entering Create automatically requests location permission and resolves a coarse place; there is no manual location button.
- Audio completion automatically requests AI title/description, then a watermarked AI cover.
- Generated text becomes editable only after the title request completes; a user-uploaded cover can replace the AI result.
- Location and AI failures are explicit but preserve the recording draft.

## Local cache

- Public Explore and Rankings responses use one actor-isolated memory/disk cache shared by all tabs.
- Freshness is five minutes; offline stale fallback is bounded to seven days.
- Pull-to-refresh explicitly requests the backend and updates the canonical cache.
- Create, save, visibility, and delete mutations invalidate public cache state.
- Authenticated Library responses and credentials are not persisted in the public cache.

## Deployment parity

`scripts/ci.sh` generates the Xcode project, runs guards, builds a signed stable-runtime iOS Simulator target, and runs hermetic tests. Simulator signing must remain enabled because Keychain requires the generated application identifier entitlement. Production API compatibility is checked separately by `scripts/verify-api-contract.sh` because live-network tests are not hermetic.
