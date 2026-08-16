# How It Works

## Dependency direction

`Features -> Shared Contracts <- Shared Infrastructure`

- `Shared/Contracts` owns domain models, repository protocols, API path constants, and authentication contracts.
- `Shared/Networking` is the only layer allowed to use `URLSession` or construct HTTP requests.
- `Shared/Persistence` owns the actor-isolated public-content cache and protected personalization snapshots.
- `Shared/Matching` owns deterministic intent parsing, metadata feature hydration, and side-effect-free ranking.
- `Shared/Infrastructure` owns Keychain and live dependency assembly.
- `Features` own presentation state and views. They depend on protocols, never concrete networking types.
- `App` composes dependencies and navigation.

## State

Screen owners are `@MainActor @Observable` models held with `@State`. Every async screen exposes loading, loaded, empty, and error states. Recording and publishing use explicit enums rather than coupled booleans.

## Contracts

Wire DTOs decode backend snake_case exactly once and map into immutable domain models. Multipart upload names match FastAPI form fields. API errors decode structured FastAPI details when available and otherwise retain the HTTP status without exposing response bodies containing private data.

## Public content cache

Explore and Rankings use one shared `CachedSoundscapeRepository`. Fresh entries are reused for five minutes, concurrent identical loads share one backend request, and successful public mutations invalidate the cache. A manual pull-to-refresh bypasses fresh data. If the backend is unavailable, the last successful public snapshot may be shown for up to seven days. Cache snapshots are atomically persisted under the app caches directory and corrupted snapshots fail open as an empty cache. Authenticated Library data is never written to this public cache.

## Resonance matching

For You never selects the first catalog item. First-use private composition is parsed into a typed `ResonanceRequest`; returning launch derives a low-confidence request from protected local history. Both paths call the same `ResonanceMatching` contract and open one attributed `RecommendationBatch` in the turntable.

The local ranker mirrors a staged production recommender: candidate retrieval, hard filtering, feature hydration, scoring, and MMR-style diversity reranking. The top-level score fixes creator intent at `0.10`, collective perception at `0.30`, and user arousal at `0.60`. User arousal keeps explicit current intent, a six-hour session profile, and a slower long-term profile separate; session learning has three times the coefficient of long-term learning.

The player records attributable impressions and listening outcomes back through the same service. Only numeric profiles and structured event contexts persist, using atomic complete-file-protection writes; raw private request text is never part of the persisted state. Full details and future backend seams are defined in `docs/domains/resonance-matching.md`.

## UI

The design uses white and near-black surfaces, editorial typography, hairline rules, restrained radii, and no decorative card shadows. Search, map, creation, rankings, identity, and library surfaces share the same monochrome system. Motion is limited to meaningful transforms and opacity and respects Reduce Motion.

## Automatic creation enrichment

Opening Create immediately requests when-in-use location permission and acquires one coarse place fix. Location denial is non-fatal. Finishing a recording or importing audio automatically runs the canonical backend title/description request followed by AI cover generation. The UI exposes `思考中…` while generation is active, then unlocks the generated text for editing and keeps photo upload as an explicit override. Title requests use a 60-second timeout and cover requests use 180 seconds; backend failure remains inline in the review form instead of discarding the draft.

## Turntable playback

Playable soundscape entry points open one full-screen physical turntable through `AudioPlayerController.openPlayer`. The record rotates continuously; putting the tonearm on the record plays or resumes the exact loop phase, and moving it outside pauses. A vertical tonearm drag enters Browse after an 11-point threshold, ducks current audio to 25%, exposes five wrapped Recommendation Stream candidates on the record, and uses restrained haptic detents. Releasing selects the centered candidate and restores full volume. `RootTabView` removes the complete five-surface shell while the player is active: no custom tab bar, native `TabView`, mini player, or persistent playback toolbar remains. A natural center-origin right swipe or the explicit `探索` action reveals Explore without stopping audio; a center-origin left swipe or the explicit `唱片机` action restores the same player.
