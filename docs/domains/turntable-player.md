# Turntable Player Domain

Every playable entry point may open the same full-screen turntable through `AudioPlayerController.openPlayer`. The controller owns the presented soundscape, current recording, source context, stable Recommendation Stream, and current sequence index. Feature views never operate on AVFoundation directly.

Playback follows an explicit `idle → loading → playing ↔ paused` state driven by `AVPlayer.timeControlStatus`; calling `play()` is not proof that audio output started. The record keeps rotating independently of audio state. The tonearm is the only in-app transport: on-record means play, outside the record means pause, and returning the needle resumes the exact audio position. Lock-screen and Control Center transport remains available through the system audio session.

Tonearm browsing begins after an 11-point gesture threshold. Vertical motion advances 58-point haptic detents through a wrapped Recommendation Stream while five audio-ready candidates appear on the record. Current audio ramps to 25% over 150 milliseconds during Browse and returns to full volume when Browse ends. Releasing the tonearm selects the centered candidate; the visible record and metadata transition without traditional transport or progress chrome.

The player publishes a context-aware source line such as `Made for you · Mong Kok`, `From Explore · Mong Kok`, or `Your recording · Mong Kok`. Metadata opens secondary details. Save mutations remain observable playback errors rather than silently claiming success.

Leaving the turntable dismisses only the presentation and never stops playback. The player contains no bottom bar: a center-origin right swipe or explicit `探索` action reveals Explore, and a center-origin left swipe or explicit `唱片机` action from Explore restores the same turntable session. The player gesture excludes the tonearm's trailing interaction zone so parking and track browsing remain independent. `RootTabView` removes all tab surfaces from the hierarchy while the player is active, preventing hidden native or custom navigation chrome. A true cold launch after first use requests a fresh playable recommendation; a first-ever launch waits for private input; returning from the background preserves sound, position, and pause state.

Listening-time reports are best-effort telemetry. Telemetry failures are logged through the `playback-telemetry` category and never mutate playback state or surface as user-visible playback failures.
