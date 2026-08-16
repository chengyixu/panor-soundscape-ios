import AVFoundation
import XCTest
@testable import Soundscape

@MainActor
final class AudioPlayerControllerTests: XCTestCase {
    func testPlaybackAudioSessionConfigurationAvoidsRecordOnlyRoutingOptions() {
        let configuration = AudioSessionLifecycle.configuration(for: .playback)

        XCTAssertEqual(configuration.category, .playback)
        XCTAssertEqual(configuration.mode, .spokenAudio)
        XCTAssertEqual(configuration.options, [])
    }

    func testRecordingAudioSessionConfigurationKeepsRequiredInputRouting() {
        let configuration = AudioSessionLifecycle.configuration(for: .recording)

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .default)
        XCTAssertEqual(configuration.options, [.defaultToSpeaker, .allowBluetoothHFP])
    }

    func testPlayActivatesSessionLoadsURLAndTracksProgress() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        await player.play(TestFixtures.soundscape)
        engine.startPlaying()
        engine.progress(elapsed: 12.8, duration: 699.4)

        XCTAssertEqual(session.activationCount, 1)
        XCTAssertEqual(engine.loadedURLs, [TestFixtures.soundscape.audioURL!])
        XCTAssertEqual(engine.playCount, 1)
        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.elapsedSeconds, 12)
        XCTAssertEqual(player.durationSeconds, 699)
    }

    func testPlayDoesNotClaimAudioIsPlayingBeforeEngineStartsOutput() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        await player.play(TestFixtures.soundscape)

        XCTAssertFalse(player.isPlaying)
    }

    func testStopDuringSessionActivationNeverStartsPlayback() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        session.suspendActivation = true
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        let playTask = Task { await player.play(TestFixtures.soundscape) }
        while session.activationCount == 0 { await Task.yield() }
        player.stop()
        session.finishActivation()
        await playTask.value
        await player.flushTelemetry()

        XCTAssertNil(player.current)
        XCTAssertEqual(engine.loadedURLs, [])
        XCTAssertEqual(engine.playCount, 0)
        XCTAssertEqual(session.deactivationCount, 2)
    }

    func testParkingNeedleDuringBufferingPreventsDeferredPlayback() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        session.suspendActivation = true
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        let playTask = Task { await player.play(TestFixtures.soundscape) }
        while session.activationCount == 0 { await Task.yield() }
        player.pause()
        session.finishActivation()
        await playTask.value
        await player.flushTelemetry()

        XCTAssertEqual(player.phase, .paused)
        XCTAssertEqual(player.current, TestFixtures.soundscape)
        XCTAssertEqual(engine.loadedURLs, [])
        XCTAssertEqual(engine.playCount, 0)
        XCTAssertEqual(session.deactivationCount, 1)
    }

    func testReplacingNeedleAfterEarlyPauseLoadsAndResumesCurrentTrack() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        session.suspendActivation = true
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        let playTask = Task { await player.play(TestFixtures.soundscape) }
        while session.activationCount == 0 { await Task.yield() }
        player.pause()
        session.finishActivation()
        await playTask.value

        session.suspendActivation = false
        await player.toggle(TestFixtures.soundscape)

        XCTAssertEqual(engine.loadedURLs, [TestFixtures.soundscape.audioURL!])
        XCTAssertEqual(engine.playCount, 1)
    }

    func testNewPlaybackWaitsForPendingSessionDeactivation() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        await player.play(TestFixtures.soundscape)
        session.suspendDeactivation = true
        player.stop()
        let nextPlay = Task { await player.play(TestFixtures.soundscapeWithoutCoordinate) }
        while session.deactivationCount == 0 { await Task.yield() }

        XCTAssertEqual(session.activationCount, 1)
        XCTAssertEqual(engine.loadedURLs, [TestFixtures.soundscape.audioURL!])

        session.finishDeactivation()
        await nextPlay.value

        XCTAssertEqual(session.activationCount, 2)
        XCTAssertEqual(
            engine.loadedURLs,
            [TestFixtures.soundscape.audioURL!, TestFixtures.soundscapeWithoutCoordinate.audioURL!]
        )
    }

    func testPauseAndResumeReportOnlyNewListeningTime() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)
        await player.play(TestFixtures.soundscape)
        engine.startPlaying()

        engine.progress(elapsed: 12, duration: 699)
        player.pause()
        await player.toggle(TestFixtures.soundscape)
        engine.startPlaying()
        engine.progress(elapsed: 20, duration: 699)
        player.pause()
        await player.flushTelemetry()

        let reports = await repository.reportedPlays
        XCTAssertEqual(reports.map(\.listenedSeconds), [12, 8])
    }

    func testCompletionReportsLoopAndRestartsWithoutDeactivatingSession() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)
        await player.play(TestFixtures.soundscape)
        engine.startPlaying()
        engine.progress(elapsed: 690, duration: 699)

        engine.finish()
        await player.flushTelemetry()

        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.elapsedSeconds, 0)
        XCTAssertEqual(engine.restartCount, 1)
        XCTAssertEqual(session.deactivationCount, 0)
        let reports = await repository.reportedPlays
        XCTAssertEqual(reports.map(\.listenedSeconds), [699])
    }

    func testNextAdvancesConfiguredSequenceAndWraps() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        await player.openPlayer(
            TestFixtures.soundscape,
            sequence: [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate],
            source: .madeForYou
        )
        await player.next()

        XCTAssertEqual(player.current?.id, TestFixtures.soundscapeWithoutCoordinate.id)
        XCTAssertEqual(player.presentedSoundscape?.id, TestFixtures.soundscapeWithoutCoordinate.id)
        XCTAssertEqual(engine.loadedURLs.last, TestFixtures.soundscapeWithoutCoordinate.audioURL)

        await player.next()

        XCTAssertEqual(player.current?.id, TestFixtures.soundscape.id)
        XCTAssertEqual(player.presentedSoundscape?.id, TestFixtures.soundscape.id)
    }

    func testBrowseDucksAndRestoresPlaybackVolume() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        await player.openPlayer(TestFixtures.soundscape)
        player.setBrowsing(true)
        player.setBrowsing(false)

        XCTAssertEqual(engine.volumeChanges.count, 2)
        XCTAssertEqual(engine.volumeChanges[0].volume, 0.25)
        XCTAssertEqual(engine.volumeChanges[0].duration, 0.15)
        XCTAssertEqual(engine.volumeChanges[1].volume, 1)
    }

    func testRecommendationStreamWrapsRelativeCandidates() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        await player.openPlayer(
            TestFixtures.soundscape,
            sequence: [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]
        )

        XCTAssertEqual(player.candidate(relativeOffset: -1)?.id, TestFixtures.soundscapeWithoutCoordinate.id)
        XCTAssertEqual(player.candidate(relativeOffset: 2)?.id, TestFixtures.soundscape.id)
    }

    func testLostOutputRoutePausesAndSurfacesVisibleError() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)
        await player.play(TestFixtures.soundscape)
        engine.startPlaying()
        engine.progress(elapsed: 5, duration: 699)

        session.loseOutputRoute()
        await player.flushTelemetry()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.error, .invalidRequest(loc(.errorAudioDeviceDisconnected)))
        let reports = await repository.reportedPlays
        XCTAssertEqual(reports.map(\.listenedSeconds), [5])
    }

    func testTelemetryFailureDoesNotSurfaceAsPlaybackNetworkError() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)
        await repository.setReportPlayResult(.failure(.transport("telemetry offline")))
        await player.play(TestFixtures.soundscape)
        engine.startPlaying()
        engine.progress(elapsed: 5, duration: 699)

        player.pause()
        await player.flushTelemetry()

        XCTAssertNil(player.error)
    }

    func testOpeningRecommendationBatchRecordsOnlyThePlayingImpression() async throws {
        let repository = StubSoundscapeRepository()
        let matching = StubResonanceMatchingService()
        let player = AudioPlayerController(
            repository: repository,
            matching: matching,
            engine: StubAudioPlaybackEngine(),
            audioSession: StubPlaybackAudioSession()
        )
        let batch = recommendationBatch()

        await player.openRecommendationBatch(batch)
        await player.flushPersonalization()

        let impressions = await matching.impressions
        XCTAssertEqual(impressions.map(\.context.soundscapeID), [TestFixtures.soundscape.id])
    }

    func testVisibleRecommendationWindowRecordsEachCandidateOnce() async throws {
        let repository = StubSoundscapeRepository()
        let matching = StubResonanceMatchingService()
        let player = AudioPlayerController(
            repository: repository,
            matching: matching,
            engine: StubAudioPlaybackEngine(),
            audioSession: StubPlaybackAudioSession()
        )
        let batch = recommendationBatch()

        await player.openRecommendationBatch(batch)
        player.recordVisibleRecommendationWindow()
        player.recordVisibleRecommendationWindow()
        await player.flushPersonalization()

        let impressions = await matching.impressions
        XCTAssertEqual(Set(impressions.map(\.context.soundscapeID)), Set(batch.items.map(\.soundscape.id)))
        XCTAssertEqual(impressions.count, batch.items.count)
    }

    func testAdvancingRecommendationRecordsListenedSeconds() async throws {
        let repository = StubSoundscapeRepository()
        let matching = StubResonanceMatchingService()
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(
            repository: repository,
            matching: matching,
            engine: engine,
            audioSession: StubPlaybackAudioSession()
        )
        let batch = recommendationBatch()
        await player.openRecommendationBatch(batch)
        engine.startPlaying()
        engine.progress(elapsed: 6, duration: 699)

        await player.next()
        await player.flushPersonalization()

        let feedback = await matching.feedback
        XCTAssertEqual(feedback.first?.feedback.kind, .advanced)
        XCTAssertEqual(feedback.first?.feedback.listenedSeconds, 6)
        XCTAssertEqual(feedback.first?.context.soundscapeID, TestFixtures.soundscape.id)
    }

    func testLoopCompletionAndSaveFeedPersonalization() async throws {
        let repository = StubSoundscapeRepository()
        let matching = StubResonanceMatchingService()
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(
            repository: repository,
            matching: matching,
            engine: engine,
            audioSession: StubPlaybackAudioSession()
        )
        await player.openRecommendationBatch(recommendationBatch())
        engine.startPlaying()
        engine.progress(elapsed: 699, duration: 699)

        engine.finish()
        _ = await player.toggleSavedCurrent()
        await player.flushPersonalization()

        let kinds = await matching.feedback.map(\.feedback.kind)
        XCTAssertEqual(kinds, [.completed, .saved])
    }

    func testExplicitNotNowRecordsOneSkipWithoutImplicitAdvance() async throws {
        let repository = StubSoundscapeRepository()
        let matching = StubResonanceMatchingService()
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(
            repository: repository,
            matching: matching,
            engine: engine,
            audioSession: StubPlaybackAudioSession()
        )
        await player.openRecommendationBatch(recommendationBatch())
        engine.startPlaying()
        engine.progress(elapsed: 4, duration: 699)

        await player.skipCurrent(reason: .notNow)
        await player.flushPersonalization()

        let feedback = await matching.feedback
        XCTAssertEqual(feedback.map(\.feedback.kind), [.skipped])
        XCTAssertEqual(feedback.first?.feedback.reason, .notNow)
        XCTAssertEqual(player.current?.id, TestFixtures.soundscapeWithoutCoordinate.id)
    }

    private func recommendationBatch() -> RecommendationBatch {
        let score = RecommendationScore(
            creatorIntent: 0.5,
            collectivePerception: 0.7,
            explicitArousal: 0.8,
            sessionArousal: 0.6,
            longTermArousal: 0.4,
            userArousal: 0.72,
            geographicFit: 0.5,
            novelty: 0.4,
            repetitionPenalty: 0,
            riskPenalty: 0,
            total: 0.7
        )
        let items = [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]
            .enumerated()
            .map { index, soundscape in
                MatchedSoundscape(
                    soundscape: soundscape,
                    role: index == 0 ? .closest : .alternate,
                    source: .session,
                    score: score,
                    featureVector: .calmNature
                )
            }
        return RecommendationBatch(
            request: ResonanceRequest(mode: .focus, requestedAt: Date(timeIntervalSince1970: 10)),
            sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            modelVersion: "test",
            candidateCount: 2,
            items: items
        )
    }
}
