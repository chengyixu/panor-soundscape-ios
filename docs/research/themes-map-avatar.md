# Themes, map discovery and avatar direction

## Research question
How can Soundscape group participatory event/topic recordings, make geographic browsing intentional, and replace the rigid generated portraits without changing uploaded photos or adding a tracking dependency?

## Findings and decision

1. **Themes are collections, not acoustic categories.** Freesound's public collection/pack workflows distinguish groupings from sound tags. A topic or event can contain street, music and nature recordings. Keep the current sound category and add one optional primary theme for this first end-to-end slice. A moderator creates an ongoing topic or dated event; listeners discover it, hear approved contributions and enter Share with its ID already selected. No inferred membership/backfill. [1]
2. **Use seed-driven local rendering, with a pinned algorithm.** DiceBear explicitly supports deterministic PRNG-based avatars and self-hosting; its software license does not automatically cover every artist's style. Character-heavy styles have a different visual tone, and a remote avatar URL would expose its seed and create availability/rate-limit dependencies. [2–4]
3. **Adapt Boring Avatars' Marble renderer to native SwiftUI.** The official project accepts a seed/name and a controlled color palette, and its source is MIT-licensed. At commit `d0ff2582a8921b643a89de4a4912be28938a828b`, Marble uses three seed-derived colors and two transformed blurred shapes. Keep that simple proven construction, replace the loud default palette with restrained moss, slate and dusk palettes, and render locally in Canvas. Preserve the copyright/license in the app bundle. Uploaded photos still win through the existing `CreatorAvatarResolver`; all generated portraits/artwork share this renderer. [5–7]
4. **A map needs an explicit search task, not more decorative controls.** Apple's search guidance emphasizes discoverability, useful results and filters. Use a persistent search field for sound/title/creator/place/theme text, a result count, a list toggle, and explicit Search this area / Show all. Panning alone must not silently discard the user's results. Use MapKit's camera-change context rather than reading UI internals. [8]

## Implementation boundaries
- Server-owned theme IDs; titles/descriptions/dates have bounded validation. Topic/event creation is moderator-only. Theme counts and themed feeds use the same public/approved/not-suspended/not-blocked predicate. Uploading to a theme never grants publication.
- First release uses one primary theme per recording, not tags, follows, memberships or a multi-taxonomy system. Past events remain discoverable; dates describe the event, not a deadline for uploading late recordings.
- Map search searches **recordings** by metadata; it is not general street-address geocoding. It combines with visible-area filtering and preserves antimeridian behavior.
- Artwork changes are intentional versioned appearance changes, not random redraws on every launch. No photos are overwritten. Visual taste is a design judgment, not something a hash/unit test proves.

## Sources
[1] Freesound, public homepage and collection announcement (accessed September 28, 2026): https://freesound.org/ ; field-recording pack example: https://freesound.org/people/hayley.suviste/packs/45006/ . Primary product evidence, not a specification for Soundscape.
[2] DiceBear introduction: https://www.dicebear.com/introduction/ . Official deterministic-generation documentation.
[3] DiceBear licenses: https://www.dicebear.com/licenses/ . Official software-vs-artwork licensing distinction.
[4] DiceBear self-hosting: https://www.dicebear.com/recipes/self-host-the-http-api/ . Official deployment/privacy boundary.
[5] Boring Avatars README, pinned source: https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/README.md . Official variants, seed and palette interface.
[6] Boring Avatars Marble source: https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/components/avatar-marble.tsx ; utilities: https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/src/lib/utilities.ts . Inspected implementation.
[7] Boring Avatars MIT license: https://github.com/boringdesigners/boring-avatars/blob/d0ff2582a8921b643a89de4a4912be28938a828b/LICENSE . Copyright 2021 boringdesigners.
[8] Apple, Design intuitive search experiences, WWDC26: https://developer.apple.com/videos/play/wwdc2026/292/ . Official design guidance. Map API signatures additionally verified against the installed stable SDK before implementation.

## Limitations
Search results and page fetching were intermittently unavailable. Decisions above rely on retrieved official documentation and the actual pinned source, not secondary popularity counts. No claim of pixel-identical SVG-to-Canvas rasterization is made; the rendering engines differ.
