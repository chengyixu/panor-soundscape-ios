# ADR 0002: Intent-First Five-Surface Application Shell

- Status: Accepted
- Date: 2026-07-30

## Context

The existing native client opens into a five-tab public-content shell: Explore, Map, Create, Rankings, and Library. The accepted SOUNDSCAPE experience instead requires first-use private input, returning-session automatic personalized playback, and direct gesture-driven personalization. Existing public exploration, geographic discovery, contribution, rankings, library, and identity capabilities must continue to exist, while primary navigation must contain no more than five items.

Private algorithm input and public sound contribution are different user intents. Keeping both behind one Create concept would make privacy and publication behavior unpredictable.

## Decision

The native application uses these five primary surfaces:

1. **For You / 为你** — first-use input and returning-session personalized turntable playback.
2. **Explore / 探索** — the public waterfall feed and existing ranking lanes, presented through a top-level **Discover / Rankings** segmented switch.
3. **Map / 地图** — geographic discovery.
4. **Contribute / 发布** — the existing authenticated public recording and upload pipeline.
5. **Me / 我的** — offline saved snapshots, published contributions, account, synchronization, storage, and settings.

Private input remains inside For You and is never routed through Contribute. Contribute remains explicitly public and authenticated. Rankings no longer consumes a primary navigation slot.

The active soundscape is a global playback session presented by `RootTabView`. The five normal surfaces share one custom bottom-navigation renderer; native `TabView` chrome is forbidden because it creates a second, visually incompatible navigation system. While the turntable is active, the complete app shell leaves the hierarchy and no bottom bar is visible. Swiping right reveals Explore without stopping audio, and swiping left from Explore restores the same turntable session.

The complete interaction and privacy behavior remains canonical in `docs/product/experience.md`.

## Consequences

- `RootTabView` must be replaced or reshaped around the five accepted surfaces.
- Existing Explore, Map, Create, Rankings, Library, identity, media, cache, and SPZ infrastructure is reused rather than discarded.
- The SPZ-reuse portion of the preceding consequence is superseded by ADR 0004; the remaining feature infrastructure continues to be reused.
- Rankings becomes the second top-level mode inside Explore while preserving its existing lanes, feature implementation, and tests.
- The existing Create feature is renamed and reframed as public contribution.
- New For You, private-input, recommendation-session, immutable-save, share, looping-playback, background-control, and prefetch contracts are required.
- The application shell must host one global playback session, one custom five-item bottom bar on non-player surfaces, and zero bottom navigation while the turntable is active.
- Existing UI tests that assert the old five tab labels must be replaced with tests for the accepted shell.
