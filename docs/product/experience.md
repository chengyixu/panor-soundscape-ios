# SOUNDSCAPE Domain Context

Last updated: 2026-07-30

## Product Identity

- The canonical product name is **SOUNDSCAPE**.

### Client Scope

- This experience contract applies to native iOS and the web client.
- Native iOS is the reference client and first implementation priority.
- The web client mirrors the same interaction model while expressing unavoidable browser constraints without introducing a separate product metaphor.

## Core Experience

### Primary Navigation

SOUNDSCAPE keeps all existing product capabilities while limiting primary navigation to five items:

1. **For You / 为你** — first-use open input and returning-session personalized turntable playback.
2. **Explore / 探索** — public waterfall discovery with Rankings incorporated as an Explore section or mode.
3. **Map / 地图** — geographic discovery.
4. **Contribute / 发布** — authenticated public recording, upload, enrichment, and publishing.
5. **Me / 我的** — offline saved snapshots, private kept inputs, published contributions, account, synchronization, storage, and settings.

Private text, speech, environmental recording, and guided Q&A belong to For You. They never imply publication. Contribute is a separate, explicitly public flow.

Explore uses a top-level segmented switch with **Discover** and **Rankings** modes. Discover contains the public waterfall feed. Rankings preserves the existing ranking lanes inside the Explore surface and does not create a sixth primary navigation item.

- All five non-player surfaces use one consistently aligned custom bottom-navigation bar.
- Native `TabView` or Liquid Glass tab chrome never appears alongside the custom bar.
- The entire bottom-navigation system is absent while the full-screen turntable is active.

- Discover cards may show silent animated cover previews.
- Each card shows only its cover preview, title, and one short creator or coarse-place source line.
- Save, Share, descriptions, statistics, and other details remain behind the intentional transition into turntable playback.
- Scrolling the waterfall feed never autoplays or replaces audio from the global player.
- Tapping a card intentionally crossfades that public soundscape into the global turntable player in For You.

### First Session

The user begins with an open input surface. They may:

- type anything they want;
- record anything they want, including speech, environmental sound, or a mixture of both;
- choose a guided question-and-answer process when they want help expressing their intent.

The algorithm analyzes and parses the submitted input. The algorithm itself will be specified separately.

The first screen uses this product language:

> **Start with anything.**  
> Type what’s on your mind, speak freely, or record the world around you.

- The text field is available immediately.
- The microphone is a primary input control.
- **Guide me** opens the optional guided Q&A path.
- There are no onboarding slides or explanatory screens before the input surface.
- The five-item tab bar is visible on the first-ever input screen with For You selected.
- Explore, Map, Contribute, and Me remain immediately accessible; submitting a first input is never a navigation gate.
- The turntable may establish the listening metaphor on this screen, but its tonearm remains parked outside the record and no soundscape autoplays before the first input is submitted.

### Guided Q&A

- Guided Q&A is adaptive rather than a fixed questionnaire.
- SOUNDSCAPE asks one question at a time and asks only for information it still needs.
- The flow has a hard maximum of three questions.
- The flow ends early as soon as there is enough signal to produce a soundscape.
- Every question offers **Make my soundscape now**, allowing the user to stop answering immediately.
- Guided Q&A must not become a personality test or long onboarding form.

### Private Input Draft

- Unsubmitted text and in-progress guided Q&A answers remain private and are preserved when the user moves to another primary surface.
- Returning to For You restores the draft exactly where the user left it.
- The draft is encrypted locally and survives closing and reopening SOUNDSCAPE.
- A returning session still opens with automatic soundscape playback; swiping down restores the unfinished draft in the private composer.
- Signing in does not upload or synchronize unfinished draft text or guided Q&A answers; private drafts remain device-local.
- The draft is cleared only after submission or an explicit clear action.

### Returning Session

When the user opens SOUNDSCAPE again, the app presents a soundscape selected for them by the algorithm.

- The recommended soundscape begins playing automatically when the returning session opens.
- The turntable opens in its active playback state with the record rotating and the stylus resting on the record.
- The user is taken directly into the turntable listening experience rather than a feed or intermediate home screen.
- Returning from the background restores the exact Active Playback Session, including its soundscape, Recommendation Stream position, preserved loop phase, and play or pause state.
- A soundscape paused by parking the stylus remains paused when the app returns from the background.
- A Cold Launch begins a new listening session with a fresh algorithm-selected soundscape and automatic playback.

### Playback Across Primary Surfaces

- Moving from For You to Explore, Map, Contribute, or Me does not pause the active soundscape.
- The small vinyl return control follows the finger directly anywhere within the safe content area. Its drag takes precedence over scrolling, map panning, and screen navigation; a tap opens the full player.
- No compact player, Return Bar, or second playback toolbar appears above the tab bar.
- Swiping right from the full-screen turntable reveals Explore without pausing or replacing the active soundscape.
- Swiping left from Explore restores the same turntable soundscape, playback state, and Recommendation Stream position.
- In-app pause and selection remain exclusive to the full turntable; lock-screen and Control Center media commands remain available as operating-system controls.

### Public Discovery Playback

- Selecting a public soundscape from Explore, Map, or Rankings transitions into the single root-owned turntable player.
- A selected Map sound exposes a Save heart without requiring playback first. It uses the same account-backed saved state as the player and Me.
- The introductory source line identifies the public origin, such as **From Explore**, **From Map**, or **From Rankings**.
- Public discovery never creates a second player or a competing playback session inside another primary surface.
- Public discovery never introduces a compact player or alternate return surface.
- A public discovery entry creates a temporary context-specific sequence for its originating Explore, Map, or Rankings source.
- Next continues through that source's ready-prefetched public sequence instead of silently entering the personalized Recommendation Stream.
- Revealed controls provide **Return to For You** to leave the public sequence and restore personalized listening.
- Entering public discovery suspends the existing personalized soundscape, its play or pause state, and its Recommendation Stream position without replacing them.
- **Return to For You** restores that exact personalized soundscape, playback state, and stream position rather than requesting a fresh recommendation.

### First-Session Payoff

- After the user submits text, a recording, or guided Q&A answers, SOUNDSCAPE immediately presents the first personalized soundscape.
- When that first personalized soundscape is ready, the record begins rotating and the tonearm moves from its parked position onto the record as playback starts.
- The first session must deliver the listening experience before the user leaves the app.
- The user does not need to close and reopen SOUNDSCAPE to receive the first result.

### Input-to-Soundscape Transition

- SOUNDSCAPE does not show a blocking loading screen after input submission.
- The input surface collapses into a living visual transition while the soundscape is constructed.
- The interface acknowledges submission within 300 milliseconds.
- First meaningful audio begins within 5 seconds.
- The active turntable state and richer audio layers appear progressively after playback begins.
- A subtle **Listening · Shaping** state replaces generic spinners and progress percentages.
- Longer processing must not prevent the user from beginning to listen.

## Turntable Player

The native interaction contract was updated on 2026-09-13. This supersedes the earlier first-use gate: every cold launch opens the vinyl player and starts playback. Existing recommendation ranking is unchanged by this interaction revision.

- Preserve the monochrome record, connected tonearm, persistent Back/Save actions, and the restrained metadata hierarchy below the record.
- A compact playback-mode control sits beside the metadata rather than creating a conventional transport row. It uses familiar repeat and shuffle symbols, a native menu, and at least a 44-point hit target.
- Playback modes are **Repeat One** (default, preserving Soundscape's continuous-loop behavior), **Continuous** (advance through the current stream and wrap), and **Shuffle** (choose a different item from the current stream whenever possible). Changing mode never interrupts the sound already playing.
- Drag the needle directly to browse. The current recording continues at 25% volume while dragging; candidate recordings remain silent.
- Release on the vinyl to commit the selected recording and restore normal volume. Switching recordings overlaps audio for 300ms once the incoming stream is playing. Releasing on the current recording preserves its playback position.
- Move the needle right, off the vinyl, and release to pause and park. Drag it back onto the vinyl and release to resume.
- There is no tap-to-lift or separate lower-to-play step. VoiceOver retains explicit play/pause actions.
- The picker includes all available playable public recordings, regardless of the original entry sequence or saved favorites.
- The visible window contains at most five unique playable recordings.
- For up to five recordings, the current recording starts on the middle groove; other recordings are randomly assigned to the remaining grooves once and remain stable during browsing. Empty grooves do not duplicate tracks.
- Longer queues start with the current recording centered. Holding the needle at the upper/lower boundary begins scrolling after 550ms and advances every 380ms while held, wrapping endlessly in either direction. Movement between the five slots never scrolls the window.
- Edge scrolling stops on release, parking, lowering, leaving the player, or entering the background.
- Browsing changes only the pending selection. Audio loading, failures, and playback status remain owned by the audio controller and are never reported as successful before output starts.
- When lowered and actually playing, thin white arc segments rotate around a fine groove. They disappear when the needle is lifted or playback is paused; rotation is not a duration indicator.
- The physical assembly interpolates its motion; reduced-motion disables continuous record movement and animated transitions.
- Track rows can also be tapped. VoiceOver exposes lift, lower/play, park/pause, and adjustable selection actions.
- Playback metadata remains below the record; while dragging, concise release and edge-hold guidance occupies that region.
- Tapping playback metadata opens a dark translucent detail sheet at a compact detent. The sheet expands vertically, then scrolls, while preserving the visible vinyl context behind it.
- The detail sheet presents the sound name, author, related location, duration, recording date, a short memo, and the suitability questionnaire with accessible high-contrast controls.
- Sound-selection mode uses only the five individual track markers and labels; it does not draw a parenthesis-shaped guide line behind them.

### Input Acceptance

- SOUNDSCAPE never rejects a recording because of what it contains or fails to contain.
- Speech, environmental audio, mixed audio, noise, and silence are all valid inputs.
- Recognizable words are not required.
- Sparse or uncertain input produces a more exploratory soundscape rather than an error or forced rerecording.
- The user may add more input voluntarily, but SOUNDSCAPE never requires a replacement recording based on content quality.
- A genuine capture, upload, or file-corruption failure is treated as a technical failure, not as rejection of the user's input.

### Recording Interaction

- On the first microphone tap, SOUNDSCAPE shows a one-time contextual privacy sheet before requesting system microphone permission.
- The privacy sheet says:

  > **SOUNDSCAPE listens only when you record.**  
  > Your recording is private and deleted after analysis unless you choose to keep it.

- The privacy sheet is not shown during app launch and is not repeated after the first accepted microphone flow.
- Tapping the microphone once begins recording immediately; tapping it again finishes the recording.
- Recording does not require a press-and-hold gesture.
- If a soundscape is active, beginning either private input recording or public contribution recording fades it out and pauses it before microphone capture starts.
- Finishing the recording does not automatically resume the previous soundscape.
- Private input proceeds toward its newly shaped soundscape; Contribute remains on its public draft. The previous soundscape can be resumed only through an explicit user action.
- While microphone capture is active, the tab bar remains visible but tab switching is disabled.
- The user must stop and keep the capture or explicitly discard it before leaving the recording surface; SOUNDSCAPE never continues hidden microphone capture on another tab.
- There is no minimum recording duration.
- The recording surface shows a live waveform and elapsed time.
- After 60 seconds, SOUNDSCAPE gently indicates **This is enough to begin** without stopping the recording.
- Recording has a five-minute safety cap to prevent accidental endless capture.
- Reaching the cap automatically finishes and analyzes everything captured; the recording is never discarded because the cap was reached.

## Location

- SOUNDSCAPE does not request location permission automatically during first use or after recording.
- The first personalized soundscape works without location access.
- **Use my location** is an optional control on the input surface.
- When enabled, location may shape recommendations.
- Precise location is not included in saved or shared soundscapes by default.
- Revoking location permission does not reset the user's other personalization data.

## Canonical Terms

- **Input** — Any text, recording, or guided-answer data the user gives SOUNDSCAPE.
- **Recording** — Unrestricted user-recorded audio. It may contain speech, environmental sound, or both.
- **Guided Q&A** — An optional assisted input path, not a mandatory onboarding questionnaire.
- **Soundscape** — The listening experience SOUNDSCAPE presents to the user.

## Recording Privacy

- A recording is private by default and is never published automatically.
- Analysis begins immediately without a blocking recording-review screen.
- After analysis, the raw recording remains private and encrypted for a 10-minute grace period.
- **Keep recording** is available from the result's revealed controls during that grace period.
- If the user does not keep it, the raw recording is permanently deleted when the 10-minute grace period expires.
- SOUNDSCAPE may retain derived personalization signals produced by the analysis.
- Saving the generated soundscape does not keep the original recording.
- Publishing or sharing a recording requires a separate, explicit user action.

## Submitted Text and Q&A Privacy

- Submitted text and guided Q&A answers remain private and are analyzed immediately.
- After analysis, the raw text and answers remain encrypted for the same 10-minute grace period used for recordings.
- **Keep input** is available from the result's revealed controls during that grace period.
- If the user does not keep them, the raw text and answers are permanently deleted when the grace period expires.
- SOUNDSCAPE may retain derived personalization signals produced by the analysis.
- Saving or sharing the generated soundscape does not retain or expose the submitted text or guided answers.

## Kept Raw Inputs

- Raw recordings, submitted text, and guided Q&A answers are retained only after the user explicitly chooses **Keep recording** or **Keep input** during the grace period.
- Kept raw input is encrypted and stored only on the originating device.
- Signing in does not upload, back up, or synchronize kept raw input.
- Me contains a dedicated **Private Inputs** section for managing kept raw input.
- Private Inputs remains visibly separate from Saved soundscapes and public Contributions.
- Opening Private Inputs does not require an additional Face ID, Touch ID, or device-passcode prompt beyond normal access to the unlocked device.
- Keeping raw input is archival only; retained material is not automatically reanalyzed or treated as an ongoing recommendation source.
- **Use again** is the only action that may deliberately return kept raw material to the private input flow for another analysis.
- **Use again** opens the private composer with the selected material loaded and does not begin analysis automatically.
- The user may add or edit context and must explicitly submit before SOUNDSCAPE analyzes it again.
- Saved and shared soundscapes remain independent snapshots and never embed kept raw input.

## Identity and Authentication

- A user can provide input and receive soundscapes without creating an account.
- SOUNDSCAPE creates an anonymous device profile to support personalization across sessions on that device.
- Moving to the next soundscape does not require login.
- Saving a soundscape locally does not require login.
- Login is requested only when the user wants account-backed behavior, including cross-device synchronization or public sharing.

## Public Contribution

- Opening Contribute never presents an immediate login wall.
- A signed-out user may record or upload material and prepare a local public-contribution draft.
- Sign-in is required only when the user continues from the local draft into server-backed enrichment or publishing.
- The Contribute editor persistently displays **Public Contribution** and an audience status of **Visible to everyone**.
- Public visibility remains clear throughout recording, upload, enrichment, and review rather than appearing only in a final warning.
- Publication requires an explicit final **Publish** action.
- Private For You input is never moved into Contribute automatically.

## Playback Interaction

- The soundscape occupies the full turntable screen.
- The active title and Source Line remain below the record throughout playback.
- The five-item tab bar is hidden while the full-screen turntable is active.
- Secondary details and actions remain visually subordinate to the record and tonearm.
- Reference Chrome contains only a top-left Menu or Back action and a top-right Save heart. Playback mode remains a compact metadata-level control, not additional top chrome.
- The Save heart reflects the active soundscape's saved state without becoming part of a transport-control row.
- Tapping Playback Metadata opens a lightweight details sheet containing Share, **Why this soundscape?**, History, and other secondary actions.
- No additional persistent playback toolbar appears when the details sheet is closed.
- Recommendation reasoning is not displayed automatically.
- A future **Why this soundscape?** detail may explain the recommendation when the user explicitly requests it.
- A soundscape has no visible duration in the primary player.
- Repeat One is the default and can play the current sound forever. Continuous advances through and wraps the current stream; Shuffle chooses a different ready stream item whenever possible.
- Playback continues when the user locks the device or switches to another app.
- System media controls provide Pause, Resume, and Next while SOUNDSCAPE is in the background.
- Foreground playback pauses when the user moves the stylus outside the record, a recording requires exclusive microphone capture, or the operating system interrupts the audio session.
- While the current soundscape plays, SOUNDSCAPE maintains a rolling local window of Recommendation Stream candidates, including their audio and display metadata.
- Tonearm selection commits only a candidate inside the audio-ready five-item window and never exposes a loading screen.
- After the transition, SOUNDSCAPE immediately replenishes the rolling stream window.
- The current soundscape crossfades into the selected soundscape; the user is never returned to a feed between soundscapes.
- After moving to the next soundscape, SOUNDSCAPE shows a subtle **Go back** action for five seconds.
- **Previous** remains available as a secondary action for the duration of the current session.
- Returning to a previous soundscape uses a reverse crossfade.
- Session history is temporary and does not automatically save prior soundscapes.
- A subtle tonearm cue is shown during early sessions and disappears after the gesture is learned.
- Save, Share, Previous, and other secondary actions do not recreate a conventional playback-control row.
- Swiping downward on the active soundscape reopens the input experience.
- The active player recedes to reveal the open composer with text input, unrestricted recording, and optional guided Q&A.
- Submitting fresh input transitions directly into a newly selected soundscape.
- Fresh input is not placed in a separate Create tab or traditional home screen.

## Current Social Scope

- Comments are not part of the current SOUNDSCAPE experience.
- The current interface and implementation should not expose placeholder or disabled comment controls.

## Profile Avatar

- The Me profile avatar opens the system photo picker for a signed-in account; signed-out taps lead to sign-in.
- Every creator and every soundscape without custom artwork receives a consistent generated visual: 32 deterministic variations of the same Soundscape wave motif, derived from the stable creator ID or soundscape ID. Variants do not change between devices or launches. The chosen profile photo, if any, replaces only that account's locally displayed avatar.
- Selected photos are orientation-corrected, center-cropped to a 256-point square, encoded as bounded opaque JPEG, and written atomically before replacing the visible avatar. A failed or canceled selection leaves the prior avatar untouched.
- The shared Panor auth service currently has no avatar-write API. Custom photos remain **only on this device** and are never represented as a server-side public photo; generated variants require no storage to remain stable across devices. Me does not display instructional copy about changing avatars.

## Sharing a Soundscape

- Capture uses the same vinyl visual language as playback. After recording or importing audio, the review form immediately has an editable filename-derived title and an optional design-consistent cover; no AI request blocks the flow.
- Title suggestion, photo selection, and AI artwork are three equal actions in one horizontal row in the Share editor. Suggestions are opt-in; when the upstream AI gateway is rate-limited, a brief inline message leaves the draft editable and publishable without a generated cover.
- The category and optional resonance sliders sit behind a disclosure; publication intent and the moderator-approval requirement remain visible before submitting.
- Me has a fifth **Review** filter for authorized moderators, rendered inline with the other four filters rather than as a separate button or modal. Server-side authorization still governs every moderation action.

## Saved Soundscapes

- Me includes a Favorites subtab backed by the authenticated saved-soundscape collection. It lists sounds saved from Map or the player and supports playback and removal.

- Saving preserves an immutable snapshot of the exact experience the user received.
- The snapshot includes the audio composition, loop behavior, title, Source Line, and displayed context needed to replay that version.
- Future algorithm or content changes must not silently mutate a saved soundscape.
- Anonymous users can save snapshots locally on their device.
- A locally saved snapshot includes the audio and metadata needed for complete offline replay.
- SOUNDSCAPE reports Save as successful only after the offline snapshot is actually available on the device.
- If device storage is insufficient, the user receives a clear recovery message rather than a false saved state.
- The Saved sheet shows local storage usage and allows downloaded snapshots to be removed.
- Account login enables cloud backup and cross-device synchronization of saved snapshots.
- The persistent top-right Save heart toggles the active immutable snapshot's saved state.
- The Saved collection opens from Me or the Playback Metadata details sheet rather than through a playback toolbar.
- Selecting a saved snapshot crossfades directly into that saved soundscape.
- Dismissing the Saved collection returns to the current turntable experience.

## Shared Soundscapes

- Sharing creates a public deep link to the exact saved soundscape snapshot.
- If the active soundscape has not already been saved, tapping Share first saves its immutable snapshot and then opens the system share sheet.
- The first implicit save explains: **Sharing also saves this soundscape, so the link always plays the same experience.**
- The implicit-save explanation is shown only once; later shares proceed immediately.
- A recipient can immediately experience the shared soundscape without installing SOUNDSCAPE or creating an account.
- The shared experience includes the soundscape audio, title, Source Line, and an optional caption written by the sharing user.
- Sharing never exposes the user's original input recording, transcript, inferred emotional state, guided Q&A answers, or private algorithm reasoning.
- Private source information can appear only when the user deliberately writes or adds it to the public share.
