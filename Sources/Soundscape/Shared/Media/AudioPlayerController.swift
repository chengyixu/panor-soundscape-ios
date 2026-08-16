import AVFoundation
import Foundation
import Observation
import OSLog

enum AudioPlaybackEngineState: Equatable {
    case loading
    case playing
}

@MainActor
protocol AudioPlaybackEngine: AnyObject {
    var onProgress: ((Double, Double?) -> Void)? { get set }
    var onStateChanged: ((AudioPlaybackEngineState) -> Void)? { get set }
    var onEnded: (() -> Void)? { get set }
    var onFailure: ((AppError) -> Void)? { get set }

    func load(url: URL) throws
    func play() throws
    func restart() throws
    func pause()
    func stop()
    func setVolume(_ volume: Float, duration: TimeInterval)
}

@MainActor
protocol PlaybackAudioSession: AnyObject {
    var onInterruptionBegan: (() -> Void)? { get set }
    var onInterruptionEnded: ((Bool) -> Void)? { get set }
    var onOutputRouteLost: (() -> Void)? { get set }

    func activate() async throws
    func deactivate() async throws
}

@MainActor
final class SystemAudioPlaybackEngine: AudioPlaybackEngine {
    var onProgress: ((Double, Double?) -> Void)?
    var onStateChanged: ((AudioPlaybackEngineState) -> Void)?
    var onEnded: (() -> Void)?
    var onFailure: ((AppError) -> Void)?

    private let logger = Logger(subsystem: "tech.panor.soundscape", category: "playback")
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var itemStatusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var notificationObservers: [NSObjectProtocol] = []
    private var volumeTask: Task<Void, Never>?
    private var targetVolume: Float = 1

    func load(url: URL) throws {
        stop()
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.volume = targetVolume
        self.player = player
        trace("load url=\(url.absoluteString)")
        onStateChanged?(.loading)

        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self, weak item] _, _ in
            Task { @MainActor [weak self, weak item] in
                guard let self, let item else { return }
                switch item.status {
                case .unknown:
                    self.trace("item status=unknown")
                case .readyToPlay:
                    self.trace("item status=ready duration=\(item.duration.seconds)")
                case .failed:
                    let detail = item.error.map { String(describing: $0) } ?? "AVPlayerItem failed"
                    self.trace("item status=failed detail=\(detail)")
                    self.onFailure?(.transport(detail))
                @unknown default:
                    self.trace("item status=unknown-default")
                }
            }
        }

        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self, weak player] _, _ in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player else { return }
                switch player.timeControlStatus {
                case .paused:
                    self.trace("timeControl=paused")
                case .waitingToPlayAtSpecifiedRate:
                    self.trace("timeControl=waiting reason=\(player.reasonForWaitingToPlay?.rawValue ?? "unknown")")
                    self.onStateChanged?(.loading)
                case .playing:
                    self.trace("timeControl=playing rate=\(player.rate)")
                    self.onStateChanged?(.playing)
                @unknown default:
                    self.trace("timeControl=unknown-default")
                }
            }
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self, weak item] time in
            let elapsed = time.seconds.isFinite ? max(0, time.seconds) : 0
            let rawDuration = item?.duration.seconds
            let duration = rawDuration?.isFinite == true ? rawDuration : nil
            Task { @MainActor [weak self] in self?.onProgress?(elapsed, duration) }
        }

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.onEnded?() }
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] notification in
            let failure = notification.userInfo?["AVPlayerItemFailedToPlayToEndErrorKey"] as? Error
            let detail = failure.map { String(describing: type(of: $0)) } ?? "AVPlayerItem"
            Task { @MainActor [weak self] in self?.onFailure?(.transport(detail)) }
        })
    }

    func play() throws {
        guard let player else { throw AppError.invalidRequest(loc(.errorCannotPlay)) }
        trace("play requested")
        player.play()
    }

    func restart() throws {
        guard let player else { throw AppError.invalidRequest(loc(.errorCannotPlay)) }
        trace("restart requested")
        onStateChanged?(.loading)
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()
    }

    func pause() {
        trace("pause requested")
        player?.pause()
    }

    func stop() {
        volumeTask?.cancel()
        volumeTask = nil
        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    func setVolume(_ volume: Float, duration: TimeInterval) {
        targetVolume = min(1, max(0, volume))
        volumeTask?.cancel()
        guard let player else { return }
        let startVolume = player.volume
        let steps = max(1, Int(duration * 60))
        volumeTask = Task { @MainActor [weak player] in
            for step in 1...steps {
                guard !Task.isCancelled, let player else { return }
                let progress = Float(step) / Float(steps)
                player.volume = startVolume + ((targetVolume - startVolume) * progress)
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func trace(_ message: String) {
        logger.debug("\(message, privacy: .public)")
#if DEBUG
        NSLog("%@", "[SoundscapePlayback] \(message)")
#endif
    }
}

@MainActor
final class SystemPlaybackAudioSession: PlaybackAudioSession {
    var onInterruptionBegan: (() -> Void)?
    var onInterruptionEnded: ((Bool) -> Void)?
    var onOutputRouteLost: (() -> Void)?

    private let session = AVAudioSession.sharedInstance()
    private let logger = Logger(subsystem: "tech.panor.soundscape", category: "audio-session")
    private var notificationObservers: [NSObjectProtocol] = []

    init() {
        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let type = rawType.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) else { return }
                switch type {
                case .began:
                    self?.onInterruptionBegan?()
                case .ended:
                    self?.onInterruptionEnded?(AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume))
                @unknown default:
                    self?.onInterruptionBegan?()
                }
            }
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                guard rawReason.flatMap(AVAudioSession.RouteChangeReason.init(rawValue:)) == .oldDeviceUnavailable else { return }
                self?.onOutputRouteLost?()
            }
        })
    }

    func activate() async throws {
        do {
            try await AudioSessionLifecycle.activate(.playback)
        } catch {
            let failure = error as NSError
            logger.error("activation failed domain=\(failure.domain, privacy: .public) code=\(failure.code)")
            throw AppError.audioPlaybackUnavailable
        }
        let outputs = session.currentRoute.outputs.map(\.portType.rawValue).joined(separator: ",")
        logger.debug("activated volume=\(self.session.outputVolume) outputs=\(outputs, privacy: .public)")
#if DEBUG
        NSLog("%@", "[SoundscapePlayback] session activated volume=\(session.outputVolume) outputs=\(outputs)")
#endif
    }

    func deactivate() async throws {
        do {
            try await AudioSessionLifecycle.deactivate()
        } catch {
            let failure = error as NSError
            logger.error("deactivation failed domain=\(failure.domain, privacy: .public) code=\(failure.code)")
            throw AppError.audioPlaybackUnavailable
        }
    }
}

@MainActor
@Observable
final class AudioPlayerController {
    enum Source: Equatable {
        case madeForYou
        case explore
        case map
        case rankings
        case library
        case direct

        func line(for soundscape: Soundscape) -> String {
            let location = soundscape.locationDisplay
            let author = soundscape.authorDisplay
            return switch self {
            case .madeForYou: "\(author) · \(loc(.playerMadeForYou)) · \(location)"
            case .explore: "\(author) · \(loc(.playerFromExplore)) · \(location)"
            case .map: "\(author) · \(loc(.playerFromMap)) · \(location)"
            case .rankings: "\(author) · \(loc(.playerFromRankings)) · \(location)"
            case .library: "\(author) · \(loc(.playerYourRecording)) · \(location)"
            case .direct: "\(author) · \(location)"
            }
        }
    }

    enum Phase: Equatable {
        case idle
        case loading
        case playing
        case paused
    }

    private(set) var current: Soundscape?
    private(set) var presentedSoundscape: Soundscape?
    private(set) var source: Source = .direct
    private(set) var phase: Phase = .idle
    private(set) var elapsedSeconds = 0
    private(set) var durationSeconds = 0
    private(set) var error: AppError?

    private let repository: any SoundscapeRepository
    private let matching: (any ResonanceMatching)?
    private let engine: any AudioPlaybackEngine
    private let audioSession: any PlaybackAudioSession
    private let logger = Logger(subsystem: "tech.panor.soundscape", category: "playback-telemetry")
    private var reportedThroughSeconds = 0
    private var shouldResumeAfterInterruption = false
    private var telemetryTask: Task<Void, Never>?
    private var personalizationTask: Task<Void, Never>?
    private var audioSessionOperation: Task<Void, Never>?
    private var playbackRequestGeneration = 0
    private var playbackRequested = false
    private var engineHasLoadedItem = false
    private(set) var recommendationStream: [Soundscape] = []
    private(set) var currentSequenceIndex: Int?
    private(set) var savedSoundscapeIDs: Set<Int> = []
    private var recommendationContexts: [Int: RecommendationContext] = [:]
    private var recordedImpressionKeys: Set<String> = []
    private var completedRecommendationSoundscapeIDs: Set<Int> = []

    var isPlaying: Bool { phase == .playing }
    var isBuffering: Bool { phase == .loading }
    var canPlayNext: Bool { recommendationStream.count > 1 }
    var sourceLine: String { current.map(source.line(for:)) ?? "" }

    init(
        repository: any SoundscapeRepository,
        matching: (any ResonanceMatching)? = nil,
        engine: any AudioPlaybackEngine = SystemAudioPlaybackEngine(),
        audioSession: any PlaybackAudioSession = SystemPlaybackAudioSession()
    ) {
        self.repository = repository
        self.matching = matching
        self.engine = engine
        self.audioSession = audioSession
        bindLifecycleEvents()
    }

    func toggle(_ soundscape: Soundscape) async {
        if current?.id == soundscape.id, isPlaying {
            pause()
        } else if current?.id == soundscape.id, isBuffering {
            return
        } else if current?.id == soundscape.id {
            await resume()
        } else {
            await play(soundscape)
        }
    }

    func openPlayer(
        _ soundscape: Soundscape,
        sequence: [Soundscape]? = nil,
        source: Source = .direct
    ) async {
        if source != .madeForYou {
            recommendationContexts = [:]
            recordedImpressionKeys = []
            completedRecommendationSoundscapeIDs = []
        }
        if let sequence {
            recommendationStream = sequence.filter { $0.audioURL != nil }
            currentSequenceIndex = recommendationStream.firstIndex(where: { $0.id == soundscape.id })
        } else if recommendationStream.firstIndex(where: { $0.id == soundscape.id }) == nil {
            recommendationStream = [soundscape]
            currentSequenceIndex = 0
        }
        self.source = source
        presentedSoundscape = soundscape
        if current?.id != soundscape.id {
            await play(soundscape)
        } else if phase == .paused || phase == .idle {
            await resume()
        }
    }

    func openRecommendationBatch(_ batch: RecommendationBatch) async {
        guard let first = batch.items.first else {
            error = .invalidRequest(loc(.errorNoPlayableReady))
            return
        }
        recommendationContexts = Dictionary(uniqueKeysWithValues: batch.items.compactMap { item in
            batch.context(for: item.soundscape.id).map { (item.soundscape.id, $0) }
        })
        recordedImpressionKeys = []
        completedRecommendationSoundscapeIDs = []
        await openPlayer(
            first.soundscape,
            sequence: batch.items.map(\.soundscape),
            source: .madeForYou
        )
        recordImpressions(for: [first.soundscape.id])
    }

    func dismissPlayer(stopPlayback: Bool) {
        presentedSoundscape = nil
        if stopPlayback { stop() }
    }

    func presentCurrentPlayer() {
        presentedSoundscape = current
    }

    func next() async {
        guard let nextIndex = nextCandidateIndex else { return }
        await selectCandidate(at: nextIndex)
    }

    func skipCurrent(reason: ResonanceFeedbackReason) async {
        recordResonanceFeedback(ResonanceFeedback(
            kind: .skipped,
            reason: reason,
            listenedSeconds: elapsedSeconds
        ))
        guard let nextIndex = nextCandidateIndex else { return }
        await selectCandidate(at: nextIndex, recordsAdvancement: false)
    }

    func recordVisibleRecommendationWindow() {
        let soundscapeIDs = Set((-2...2).compactMap { candidate(relativeOffset: $0)?.id })
        recordImpressions(for: Array(soundscapeIDs))
    }

    func recordResonanceFeedback(_ feedback: ResonanceFeedback) {
        guard let current,
              let context = recommendationContexts[current.id] else { return }
        enqueueFeedback(feedback, soundscape: current, context: context)
    }

    func clearRecommendationPersonalization() {
        recommendationContexts = [:]
        recordedImpressionKeys = []
        completedRecommendationSoundscapeIDs = []
    }

    func candidate(relativeOffset: Int) -> Soundscape? {
        guard !recommendationStream.isEmpty else { return current }
        let center = currentSequenceIndex
            ?? current.flatMap { current in recommendationStream.firstIndex(where: { $0.id == current.id }) }
            ?? 0
        let index = (center + relativeOffset).modulo(recommendationStream.count)
        return recommendationStream[index]
    }

    func selectCandidate(_ soundscape: Soundscape) async {
        guard let index = recommendationStream.firstIndex(where: { $0.id == soundscape.id }) else {
            await openPlayer(soundscape, source: source)
            return
        }
        await selectCandidate(at: index)
    }

    func setBrowsing(_ browsing: Bool) {
        engine.setVolume(browsing ? 0.25 : 1, duration: 0.15)
    }

    @discardableResult
    func toggleSavedCurrent() async -> Bool? {
        guard let current else { return nil }
        do {
            let response = try await repository.toggleSave(id: current.id)
            if response.saved { savedSoundscapeIDs.insert(current.id) }
            else { savedSoundscapeIDs.remove(current.id) }
            if response.saved {
                recordResonanceFeedback(ResonanceFeedback(
                    kind: .saved,
                    listenedSeconds: elapsedSeconds
                ))
            }
            error = nil
            return response.saved
        } catch let appError as AppError {
            error = appError
        } catch let underlyingError {
            error = .transport(String(describing: type(of: underlyingError)))
        }
        return nil
    }

    func play(_ soundscape: Soundscape) async {
        guard let url = soundscape.audioURL else {
            current = soundscape
            error = .invalidRequest(loc(.errorNoAudio))
            return
        }

        reportCurrentPlay()
        engine.stop()
        engineHasLoadedItem = false
        playbackRequested = true
        current = soundscape
        elapsedSeconds = 0
        durationSeconds = max(0, soundscape.durationSeconds)
        reportedThroughSeconds = 0
        error = nil
        phase = .loading
        playbackRequestGeneration += 1
        let requestGeneration = playbackRequestGeneration

        do {
            try await activateSession()
            guard requestGeneration == playbackRequestGeneration,
                  current?.id == soundscape.id,
                  playbackRequested else {
                if current == nil || !playbackRequested { deactivateSession() }
                return
            }
            try engine.load(url: url)
            engineHasLoadedItem = true
            guard playbackRequested else {
                engine.pause()
                phase = .paused
                return
            }
            try engine.play()
        } catch let appError as AppError {
            handlePlaybackFailure(appError)
        } catch let underlyingError {
            handlePlaybackFailure(.transport(String(describing: type(of: underlyingError))))
        }
    }

    func pause() {
        guard current != nil, phase != .idle, phase != .paused else { return }
        playbackRequested = false
        if phase == .loading { playbackRequestGeneration += 1 }
        engine.pause()
        phase = .paused
        shouldResumeAfterInterruption = false
        reportCurrentPlay()
    }

    func stop() {
        playbackRequestGeneration += 1
        reportCurrentPlay()
        engine.stop()
        engineHasLoadedItem = false
        playbackRequested = false
        deactivateSession()
        current = nil
        presentedSoundscape = nil
        recommendationStream = []
        recommendationContexts = [:]
        recordedImpressionKeys = []
        completedRecommendationSoundscapeIDs = []
        currentSequenceIndex = nil
        phase = .idle
        elapsedSeconds = 0
        durationSeconds = 0
        reportedThroughSeconds = 0
        shouldResumeAfterInterruption = false
        error = nil
    }

    func dismissError() {
        error = nil
    }

    func flushTelemetry() async {
        await telemetryTask?.value
        await audioSessionOperation?.value
    }

    func flushPersonalization() async {
        await personalizationTask?.value
    }

    private func resume() async {
        guard let current else { return }
        guard let url = current.audioURL else {
            error = .invalidRequest(loc(.errorNoAudio))
            return
        }
        playbackRequested = true
        phase = .loading
        playbackRequestGeneration += 1
        let requestGeneration = playbackRequestGeneration
        do {
            try await activateSession()
            guard requestGeneration == playbackRequestGeneration,
                  self.current?.id == current.id,
                  playbackRequested else {
                if self.current == nil || !playbackRequested { deactivateSession() }
                return
            }
            if !engineHasLoadedItem {
                try engine.load(url: url)
                engineHasLoadedItem = true
            }
            try engine.play()
            error = nil
        } catch let appError as AppError {
            handlePlaybackFailure(appError)
        } catch let underlyingError {
            handlePlaybackFailure(.transport(String(describing: type(of: underlyingError))))
        }
    }

    private func selectCandidate(at index: Int, recordsAdvancement: Bool = true) async {
        guard recommendationStream.indices.contains(index) else { return }
        let candidate = recommendationStream[index]
        if recordsAdvancement, let current, current.id != candidate.id {
            recordResonanceFeedback(ResonanceFeedback(
                kind: .advanced,
                listenedSeconds: elapsedSeconds
            ))
        }
        currentSequenceIndex = index
        presentedSoundscape = candidate
        engine.setVolume(1, duration: 0.18)
        await play(candidate)
        recordImpressions(for: [candidate.id])
    }

    private var nextCandidateIndex: Int? {
        guard canPlayNext else { return nil }
        let currentIndex = currentSequenceIndex
            ?? current.flatMap { current in recommendationStream.firstIndex(where: { $0.id == current.id }) }
            ?? 0
        return recommendationStream.index(after: currentIndex) == recommendationStream.endIndex
            ? recommendationStream.startIndex
            : recommendationStream.index(after: currentIndex)
    }

    private func bindLifecycleEvents() {
        engine.onStateChanged = { [weak self] state in
            guard let self else { return }
            switch state {
            case .loading: self.phase = .loading
            case .playing: self.phase = .playing
            }
        }
        engine.onProgress = { [weak self] elapsed, duration in
            guard let self else { return }
            self.elapsedSeconds = max(0, Int(elapsed.rounded(.down)))
            if let duration { self.durationSeconds = max(0, Int(duration.rounded(.down))) }
        }
        engine.onEnded = { [weak self] in self?.handlePlaybackEnded() }
        engine.onFailure = { [weak self] error in self?.handlePlaybackFailure(error) }
        audioSession.onInterruptionBegan = { [weak self] in self?.handleInterruptionBegan() }
        audioSession.onInterruptionEnded = { [weak self] shouldResume in self?.handleInterruptionEnded(shouldResume: shouldResume) }
        audioSession.onOutputRouteLost = { [weak self] in self?.handleOutputRouteLost() }
    }

    private func handlePlaybackEnded() {
        if durationSeconds > 0 { elapsedSeconds = durationSeconds }
        if let current,
           recommendationContexts[current.id] != nil,
           completedRecommendationSoundscapeIDs.insert(current.id).inserted {
            recordResonanceFeedback(ResonanceFeedback(
                kind: .completed,
                listenedSeconds: elapsedSeconds
            ))
        }
        reportCurrentPlay()
        elapsedSeconds = 0
        reportedThroughSeconds = 0
        phase = .loading
        do {
            try engine.restart()
            error = nil
        } catch let appError as AppError {
            handlePlaybackFailure(appError)
        } catch let underlyingError {
            handlePlaybackFailure(.transport(String(describing: type(of: underlyingError))))
        }
    }

    private func handlePlaybackFailure(_ playbackError: AppError) {
        engine.pause()
        playbackRequested = false
        phase = .paused
        shouldResumeAfterInterruption = false
        reportCurrentPlay()
        deactivateSession()
        error = playbackError
    }

    private func handleInterruptionBegan() {
        shouldResumeAfterInterruption = isPlaying
        guard isPlaying else { return }
        playbackRequested = false
        engine.pause()
        phase = .paused
        reportCurrentPlay()
    }

    private func handleInterruptionEnded(shouldResume: Bool) {
        let resumeRequested = shouldResumeAfterInterruption && shouldResume
        shouldResumeAfterInterruption = false
        if resumeRequested {
            Task { await resume() }
        }
    }

    private func handleOutputRouteLost() {
        guard isPlaying else { return }
        playbackRequested = false
        engine.pause()
        phase = .paused
        shouldResumeAfterInterruption = false
        reportCurrentPlay()
        error = .invalidRequest(loc(.errorAudioDeviceDisconnected))
    }

    private func reportCurrentPlay() {
        guard let current else { return }
        let listenedSeconds = max(0, elapsedSeconds - reportedThroughSeconds)
        guard listenedSeconds > 0 else { return }
        reportedThroughSeconds = elapsedSeconds
        let previousTask = telemetryTask
        telemetryTask = Task {
            await previousTask?.value
            do {
                _ = try await repository.reportPlay(id: current.id, listenedSeconds: listenedSeconds)
            } catch let appError as AppError {
                logger.error("Playback telemetry failed: \(String(describing: appError), privacy: .private(mask: .hash))")
            } catch let underlyingError {
                logger.error("Playback telemetry failed: \(String(describing: type(of: underlyingError)), privacy: .public)")
            }
        }
    }

    private func recordImpressions(for soundscapeIDs: [Int]) {
        guard let matching else { return }
        let date = Date()
        let impressions = soundscapeIDs.compactMap { soundscapeID -> RecommendationImpression? in
            guard let context = recommendationContexts[soundscapeID] else { return nil }
            let key = "\(context.requestID.uuidString):\(soundscapeID)"
            guard recordedImpressionKeys.insert(key).inserted else { return nil }
            return RecommendationImpression(context: context, shownAt: date)
        }
        guard !impressions.isEmpty else { return }
        let previousTask = personalizationTask
        personalizationTask = Task { @MainActor [weak self] in
            await previousTask?.value
            do {
                try await matching.recordImpressions(impressions)
            } catch let appError as AppError {
                if self?.error == nil { self?.error = appError }
            } catch {
                if self?.error == nil { self?.error = .personalizationUnavailable }
            }
        }
    }

    private func enqueueFeedback(
        _ feedback: ResonanceFeedback,
        soundscape: Soundscape,
        context: RecommendationContext
    ) {
        guard let matching else { return }
        let previousTask = personalizationTask
        personalizationTask = Task { @MainActor [weak self] in
            await previousTask?.value
            do {
                try await matching.recordFeedback(feedback, for: soundscape, context: context)
            } catch let appError as AppError {
                if self?.error == nil { self?.error = appError }
            } catch {
                if self?.error == nil { self?.error = .personalizationUnavailable }
            }
        }
    }

    private func activateSession() async throws {
        let precedingOperation = audioSessionOperation
        let audioSession = self.audioSession
        let activation = Task { @MainActor () -> (any Error)? in
            await precedingOperation?.value
            do {
                try await audioSession.activate()
                return nil
            } catch {
                return error
            }
        }
        audioSessionOperation = Task { @MainActor in
            _ = await activation.value
        }
        if let activationError = await activation.value {
            throw activationError
        }
    }

    private func deactivateSession() {
        let precedingOperation = audioSessionOperation
        let audioSession = self.audioSession
        audioSessionOperation = Task { @MainActor [weak self] in
            await precedingOperation?.value
            do {
                try await audioSession.deactivate()
            } catch let appError as AppError {
                if self?.error == nil { self?.error = appError }
            } catch let underlyingError {
                if self?.error == nil { self?.error = .transport(String(describing: type(of: underlyingError))) }
            }
        }
    }
}

private extension Int {
    func modulo(_ divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        return ((self % divisor) + divisor) % divisor
    }
}
