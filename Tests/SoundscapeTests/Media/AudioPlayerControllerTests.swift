import AVFoundation
import XCTest
@testable import Soundscape

@MainActor
final class AudioPlayerControllerTests: XCTestCase {
    func testMapFavoriteMutationAndRefreshShareOneServerBackedState() async throws {
        let repository = StubSoundscapeRepository()
        await repository.setSavedResult(.success([TestFixtures.soundscape]))
        let player = AudioPlayerController(repository: repository, engine: StubAudioPlaybackEngine(), audioSession: StubPlaybackAudioSession())

        try await player.refreshSavedSoundscapes()
        XCTAssertTrue(player.savedSoundscapeIDs.contains(TestFixtures.soundscape.id))

        await repository.setToggleSaveResult(.success(SaveResponse(saved: false, saveCount: 2)))
        let saved = try await player.toggleSaved(TestFixtures.soundscape)
        XCTAssertFalse(saved)
        XCTAssertFalse(player.savedSoundscapeIDs.contains(TestFixtures.soundscape.id))
    }

    func testSystemEngineCrossfadeSettlesAndParkingStopsBoth() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("crossfade-\(UUID()).caf")
        defer { try? FileManager.default.removeItem(at: url) }
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 441_000)!
        buffer.frameLength = buffer.frameCapacity
        for frame in 0..<Int(buffer.frameLength) {
            buffer.floatChannelData![0][frame] = Float(sin(Double(frame) * 2 * .pi * 220 / 44_100)) * 0.005
        }
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
        }
        var outputs: [AVPlayer] = []
        let engine = SystemAudioPlaybackEngine { item in
            let output = AVPlayer(playerItem: item)
            outputs.append(output)
            return output
        }
        defer { engine.stop() }
        func waitForPlaying(_ output: AVPlayer) async throws {
            for _ in 0..<200 {
                if output.timeControlStatus == .playing { return }
                try await Task.sleep(for: .milliseconds(10))
            }
            XCTFail("Real AVPlayer never reached playing")
        }
        try engine.load(url: url)
        try engine.play()
        try await waitForPlaying(outputs[0])
        try engine.crossfade(to: url, duration: 0.3)
        try engine.play()
        try await waitForPlaying(outputs[1])
        // AVPlayer readiness can be delayed beyond the 0.3 s crossfade on a
        // busy simulator. Verify the settled behavior, not an assumed 80 ms
        // scheduling window; overlap itself is covered by the stubbed engine test.
        try await Task.sleep(for: .milliseconds(700))
        XCTAssertEqual(outputs[0].rate, 0)
        XCTAssertEqual(outputs[1].volume, 1, accuracy: 0.01)
        try engine.crossfade(to: url, duration: 0.3)
        try engine.play()
        engine.pause()
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertTrue(outputs.allSatisfy { $0.rate == 0 }, "Parking must silence outgoing and incoming players")
    }

    func testNeedleBrowsingDucksWithoutPausingAndSameTrackReleaseDoesNotRestart() async {
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(repository: StubSoundscapeRepository(), engine: engine, audioSession: StubPlaybackAudioSession())
        await player.openPlayer(TestFixtures.soundscape)
        engine.startPlaying()
        engine.progress(elapsed: 12, duration: 60)
        player.setBrowsing(true)
        XCTAssertTrue(player.isPlaying)
        XCTAssertTrue(player.isBrowsing)
        XCTAssertEqual(engine.pauseCount, 0)
        XCTAssertEqual(engine.volumeChanges.last?.volume, 0.25)
        await player.commitNeedleSelection(TestFixtures.soundscape)
        XCTAssertEqual(engine.volumeChanges.last?.volume, 1)
        XCTAssertEqual(engine.loadedURLs.count, 1)
        XCTAssertEqual(player.elapsedSeconds, 12)
        XCTAssertFalse(player.isBrowsing)
    }

    func testReleaseOnAnotherTrackCrossfadesWithoutStoppingOldOutputFirst() async {
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(repository: StubSoundscapeRepository(), engine: engine, audioSession: StubPlaybackAudioSession())
        await player.openPlayer(TestFixtures.soundscape)
        engine.startPlaying()
        let stopsBefore = engine.stopCount
        player.setBrowsing(true)
        let candidate = TestFixtures.soundscapeWithoutCoordinate
        await player.commitNeedleSelection(candidate)
        XCTAssertEqual(engine.crossfadeDurations, [0.3])
        XCTAssertEqual(engine.stopCount, stopsBefore)
        XCTAssertEqual(player.current?.id, candidate.id)
        player.pause()
        engine.startPlaying()
        XCTAssertEqual(player.phase, .paused, "A queued engine callback must not undo parking")
        XCTAssertFalse(player.isBrowsing)
    }

    func testCatalogFailureCannotReusePreviouslyLoadedPublicSounds() async throws {
        let repository = StubSoundscapeRepository()
        let player = AudioPlayerController(repository: repository, engine: StubAudioPlaybackEngine(), audioSession: StubPlaybackAudioSession())
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        try await player.loadVinylCatalog()
        XCTAssertEqual(player.availableSoundscapes.count, 1)
        await repository.setExploreResult(.failure(.transport("offline")))
        do { try await player.loadVinylCatalog(); XCTFail("Expected an unavailable server") }
        catch let error as AppError { XCTAssertEqual(error, .transport("offline")) }
        XCTAssertTrue(player.availableSoundscapes.isEmpty)
    }

    func testBlockingCreatorRemovesPlayerAndCatalogCandidatesImmediately() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: StubPlaybackAudioSession())
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        try await player.loadVinylCatalog()
        await player.openPlayer(TestFixtures.soundscape)
        player.removeCreator(TestFixtures.soundscape.ownerID)
        XCTAssertNil(player.current)
        XCTAssertNil(player.presentedSoundscape)
        XCTAssertTrue(player.vinylStream.isEmpty)
    }

    func testDefaultPlayerUsesEntirePlayableCatalog() async throws {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]))
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: StubPlaybackAudioSession())
        await player.openPlayer(TestFixtures.soundscape, sequence: [TestFixtures.soundscape])
        try await player.loadVinylCatalog()
        XCTAssertNotNil(player.presentedSoundscape)
        let catalog = try await repository.explore(category: nil).filter { $0.audioURL != nil }
        XCTAssertEqual(player.vinylStream, catalog)
        XCTAssertEqual(engine.playCount, 1)
    }

    func testRouteLossWhileIncomingSoundBuffersStopsPlayback() async {
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: StubSoundscapeRepository(), engine: engine, audioSession: session)
        await player.openPlayer(TestFixtures.soundscape)
        engine.startPlaying()
        await player.commitNeedleSelection(TestFixtures.soundscapeWithoutCoordinate)
        XCTAssertEqual(player.phase, .loading)
        session.loseOutputRoute()
        XCTAssertEqual(player.phase, .paused)
        XCTAssertEqual(engine.pauseCount, 1)
        engine.startPlaying()
        XCTAssertEqual(player.phase, .paused)
    }
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

    func testDefaultRepeatOneCompletionReportsLoopAndRestartsWithoutDeactivatingSession() async {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)
        await player.play(TestFixtures.soundscape)
        engine.startPlaying()
        engine.progress(elapsed: 690, duration: 699)

        engine.finish()
        await player.flushTelemetry()

        XCTAssertEqual(player.playbackMode, .repeatOne)
        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.elapsedSeconds, 0)
        XCTAssertEqual(engine.restartCount, 1)
        XCTAssertEqual(session.deactivationCount, 0)
        let reports = await repository.reportedPlays
        XCTAssertEqual(reports.map(\.listenedSeconds), [699])
    }

    func testContinuousPlaybackAdvancesToNextTrackAndWraps() async {
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(
            repository: StubSoundscapeRepository(),
            engine: engine,
            audioSession: StubPlaybackAudioSession()
        )
        await player.openPlayer(
            TestFixtures.soundscape,
            sequence: [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]
        )
        player.setPlaybackMode(.continuous)
        engine.startPlaying()

        engine.finish()
        await waitUntil { player.current?.id == TestFixtures.soundscapeWithoutCoordinate.id }
        XCTAssertEqual(engine.restartCount, 0)

        engine.startPlaying()
        engine.finish()
        await waitUntil { player.current?.id == TestFixtures.soundscape.id }
    }

    func testShufflePlaybackDoesNotRepeatCurrentTrackWhenAnotherTrackExists() async {
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(
            repository: StubSoundscapeRepository(),
            engine: engine,
            audioSession: StubPlaybackAudioSession()
        )
        await player.openPlayer(
            TestFixtures.soundscape,
            sequence: [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]
        )
        player.setPlaybackMode(.shuffle)
        engine.startPlaying()

        engine.finish()
        await waitUntil { player.current?.id == TestFixtures.soundscapeWithoutCoordinate.id }

        XCTAssertEqual(engine.restartCount, 0)
        XCTAssertEqual(player.playbackMode, .shuffle)
    }

    func testChangingPlaybackModeDoesNotInterruptCurrentAudio() async {
        let engine = StubAudioPlaybackEngine()
        let player = AudioPlayerController(
            repository: StubSoundscapeRepository(),
            engine: engine,
            audioSession: StubPlaybackAudioSession()
        )
        await player.play(TestFixtures.soundscape)
        engine.startPlaying()
        let loadedURLs = engine.loadedURLs
        let playCount = engine.playCount

        player.setPlaybackMode(.continuous)
        player.setPlaybackMode(.shuffle)

        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(engine.loadedURLs, loadedURLs)
        XCTAssertEqual(engine.playCount, playCount)
        XCTAssertEqual(engine.pauseCount, 0)
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

    private func waitUntil(
        timeoutIterations: Int = 100,
        condition: @MainActor () -> Bool
    ) async {
        for _ in 0..<timeoutIterations {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("Condition did not become true")
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
