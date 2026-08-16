# Resonance Matching Domain

## Ownership

`ResonanceMatchingContracts` is the single typed contract for request intent, content features, short- and long-term profiles, recommendation attribution, impressions, and feedback. `LocalResonanceMatchingService` owns orchestration and persistence; `ResonanceMatcher` is a deterministic, side-effect-free ranker; `AudioPlayerController` is the only runtime event bridge from playback into personalization.

The iOS implementation follows the staged shape of X-style recommendation systems without copying infrastructure intended for a very large social feed:

1. Normalize the current request into one `ResonanceRequest`.
2. Load the local personalization profile and expire stale session state.
3. Retrieve the current public catalog through `SoundscapeRepository`.
4. Hydrate creator-intent and collective-perception features.
5. Apply hard eligibility and user-avoidance filters.
6. Score every eligible item with an attributable three-layer score.
7. Apply deterministic novelty and MMR-style diversity reranking.
8. Return a typed batch whose contexts connect later impressions and outcomes to the exact request and model version.

The current catalog is small enough to score all eligible content. Approximate nearest-neighbor retrieval, collaborative filtering, learned rankers, and contextual bandits are deliberately deferred until the app has sufficient attributable exposure and outcome data.

## Three-layer score

The canonical top-level weighting is:

| Layer | Meaning | Weight |
|---|---|---:|
| Creator intent | What the recorder declared or attempted to express | `0.10` |
| Collective perception | Shared scene, affect, acoustic, quality, novelty, geographic, and loop characteristics | `0.30` |
| User arousal | What best fits this user's stated goal and learned response now | `0.60` |

Creator intent remains a weak signal: matching words cannot overrule a conflicting acoustic or affective result. Collective perception is the stable content baseline. User arousal is dominant and combines the explicit request with two separate learned representations:

- **Session profile:** recent intent and behavior within a six-hour activity window. Its learned coefficient is three times the long-term coefficient.
- **Long-term profile:** slower-moving preferences learned only from outcomes with durable evidence.
- **Not now:** updates the session representation only; it does not become a permanent dislike.
- **Less like this:** applies a stronger session penalty and a smaller long-term correction without treating one skip as universal evidence about every context.

Supported modes are mirror, shift, escape, focus, recall, and discover. The request expresses user-selected intent and confidence; it must not be interpreted as a diagnosis of mental state.

## Content features

`SoundscapeFeatureProviding` is the replaceable content-understanding seam. The local provider deterministically hydrates existing title, description, prompt, category, and place metadata into:

- creator-intent text and vector;
- collective scene and affect vector;
- editorial quality and novelty;
- speech and sudden-noise risk;
- loop stability.

A backend may later supply CLAP-style semantic embeddings, ARAUS-style collective affect labels, GeoSound-style geographic representations, or reviewed metadata through the same contract. Those models inform retrieval and content understanding; they do not replace the user's own feedback.

## Filtering and reranking

Private, unplayable, blocked, and explicitly avoided items never enter ranking. Sudden-noise risk is a hard filter when requested and a soft penalty in focus or state-shifting contexts. Recent exposure is penalized before reranking.

The ranker then applies maximum-marginal-relevance-style selection across feature similarity, creator, place, and category. The first three positions are explicitly attributed as closest, alternate, and surprise; later positions form the stream. Low request confidence increases controlled exploration, but ranking remains deterministic and testable.

## Learning loop

The player records the selected item immediately and records the five-item browse window when it becomes visible. Playback currently emits attributable advanced, completed, and saved outcomes; the explicit feedback surface emits resonated and skipped outcomes. The typed contract also reserves started, replayed, and goal-reached outcomes for later product slices. Event writes are serialized so playback callbacks cannot reorder profile updates.

Impressions and feedback retain request ID, session ID, model version, candidate source, rank, mode, and content ID. Event history is bounded to the most recent 500 records. This establishes the exposure-to-outcome chain required before any future contextual-bandit work.

## Privacy and control

Raw private composition text, transcripts, recordings, and memory descriptions exist only in the in-memory request. Persisted state contains numeric profiles and attributable structured events, never the request text itself.

`ProtectedFileResonanceStateStore` writes atomically with complete file protection under Application Support. Corrupt or unreadable state fails explicitly rather than silently resetting learned data. Settings exposes a user-controlled reset that removes the full local personalization snapshot.

## Test seams

- `ResonanceMatcherTests` prove the `0.10 / 0.30 / 0.60` hierarchy, session-over-long-term behavior, hard filters, and diversity.
- `ResonanceProfileTests` prove that temporary skips and durable dislikes update different representations.
- `LocalResonanceMatchingServiceTests` prove request privacy, impression deduplication, attributable feedback, session expiry, and returning-user behavior.
- `ProtectedFileResonanceStateStoreTests` prove protected persistence and reset.
- `AudioPlayerControllerTests` prove impression and outcome emission from actual player transitions.
