# Playback Domain

## Ownership

`AudioPlayerController` is the single app-wide playback owner. Views request `toggle`, `pause`, or `stop`; they never create `AVPlayer` instances or configure `AVAudioSession` directly.

## Lifecycle

- Playback activates a `.playback` / `.spokenAudio` session with Bluetooth A2DP and AirPlay support.
- iOS 27 uses native asynchronous session activation and deactivation; iOS 18–26 runs the synchronous compatibility API away from the main thread.
- Activation and deactivation operations are serialized so cleanup from an old request cannot deactivate newer playback.
- Progress and duration remain observable for telemetry and system media controls; the foreground turntable deliberately exposes no mini player or progress bar.
- End-of-item, route loss, playback failure, and audio interruptions are explicit state transitions.
- Eligible interruptions resume only when the system supplies `shouldResume` and playback was active before interruption.
- Removing the active output route pauses playback and shows a user-visible error.
- Session deactivation failures remain visible rather than becoming silent cleanup.

## Telemetry

Listening telemetry reports only newly listened seconds. Reports are serialized so pause/resume cycles cannot race or double-count prior progress. Completion reports the remaining segment before the audio session deactivates.

## Test seam

AVFoundation is behind `AudioPlaybackEngine` and `PlaybackAudioSession`. Controller tests use contract-bound in-memory implementations and cover progress, pause/resume accounting, completion, and route loss.
