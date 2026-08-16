# Domain Index

| Domain | Responsibility | Backend/native boundary |
|---|---|---|
| Explore | Public two-column waterfall and category filtering | `GET /soundscapes` |
| Discovery Map | Geographic browsing and selected-place callout | `GET /soundscapes`, MapKit |
| Rankings | Horizontal CD-style category lanes | `GET /rankings` |
| Creation | Record/import, metadata, cover, AI generation, publish | AVFoundation, PhotosUI, CoreLocation, `/ai/*`, `POST /soundscapes` |
| Playback | One authoritative audio session and play completion reporting | AVPlayer, `POST /soundscapes/{id}/play` |
| Resonance Matching | Intent normalization, safe ranking, diversity, and private short-/long-term learning | Local matcher and protected Application Support state |
| Identity | Register, login, current user, secure token lifecycle | `/api/panor/auth/*`, Keychain |
| Library | Authenticated ownership, visibility, and deletion | `/me/soundscapes`, visibility, delete |

Each domain owns presentation state but shares immutable `Soundscape` identity and repository contracts.

Playback lifecycle details are defined in `playback.md`. Recommendation and personalization details are defined in `resonance-matching.md`. Cross-domain release invariants are defined in `../release-checklist.md`.
