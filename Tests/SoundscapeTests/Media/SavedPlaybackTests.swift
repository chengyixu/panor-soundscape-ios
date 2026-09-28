import XCTest
@testable import Soundscape

@MainActor
final class SavedPlaybackTests: XCTestCase {
    private let first = TestFixtures.soundscape
    private let second = TestFixtures.soundscapeWithoutCoordinate

    func testSwitchToSavedKeepsCurrentPositionAndExcludesThePublicCatalog() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setExploreResult(.success([first, second]))
        await repository.setSavedResult(.success([first, first]))
        await player.openPlayer(first, sequence: [first, second])
        try await player.loadVinylCatalog()
        engine.startPlaying()
        engine.progress(elapsed: 12, duration: 699)
        let loads = engine.loadedURLs
        player.setPlaybackMode(.shuffle)

        try await player.setPlaybackCollection(.saved)

        XCTAssertEqual(player.playbackCollection, .saved)
        XCTAssertEqual(player.vinylStream.map(\.id), [first.id])
        XCTAssertEqual(player.candidate(relativeOffset: 1)?.id, first.id)
        XCTAssertEqual(engine.loadedURLs, loads)
        XCTAssertEqual(player.elapsedSeconds, 12)
        XCTAssertEqual(player.playbackMode, .shuffle)
        XCTAssertTrue(player.isPlaying)
    }

    func testUnsavedCurrentSwitchesToFirstSavedAndNeverLeaksIntoNeedlePicker() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([second]))
        await player.openPlayer(first, sequence: [first, second])
        engine.startPlaying()
        try await player.setPlaybackCollection(.saved)
        XCTAssertEqual(player.current?.id, second.id)
        XCTAssertEqual(player.vinylStream.map(\.id), [second.id])
        await player.commitNeedleSelection(first) // stale selection from the previous catalog
        XCTAssertEqual(player.current?.id, second.id)
        await player.selectCandidate(first)
        XCTAssertEqual(player.current?.id, second.id)
    }

    func testSavedContinuousPlaybackWrapsOnlyWithinSavedEvenWhenCatalogReloads() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setExploreResult(.success([first]))
        await repository.setSavedResult(.success([first, second]))
        await player.openPlayer(first)
        try await player.setPlaybackCollection(.saved)
        try await player.loadVinylCatalog()
        player.setPlaybackMode(.continuous)
        engine.startPlaying()
        engine.finish()
        await waitFor { player.current?.id == self.second.id }
        XCTAssertEqual(player.vinylStream.map(\.id), [first.id, second.id])
        engine.startPlaying()
        engine.finish()
        await waitFor { player.current?.id == self.first.id }
    }

    func testSavedShuffleAndNextUseOnlySaved() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([first, second]))
        await player.openPlayer(first)
        try await player.setPlaybackCollection(.saved)
        player.setPlaybackMode(.shuffle)
        engine.startPlaying()
        engine.finish()
        await waitFor { player.current?.id == self.second.id }
        await player.next()
        XCTAssertEqual(player.current?.id, first.id)
    }

    func testEmptyAndFailedSavedLoadsLeaveAllQueueAndAudioUntouched() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await player.openPlayer(first, sequence: [first, second])
        let loads = engine.loadedURLs
        do {
            try await player.setPlaybackCollection(.saved)
            XCTFail("An empty collection needs an explicit empty state")
        } catch let error as AppError {
            XCTAssertEqual(error, .invalidRequest(loc(.playerSavedEmpty)))
        }
        await repository.setSavedResult(.failure(.transport("offline")))
        do {
            try await player.setPlaybackCollection(.saved)
            XCTFail("No cached-success fallback")
        } catch let error as AppError { XCTAssertEqual(error, .transport("offline")) }
        XCTAssertEqual(player.playbackCollection, .all)
        XCTAssertEqual(player.current?.id, first.id)
        XCTAssertEqual(engine.loadedURLs, loads)
        XCTAssertFalse(player.isChangingCollection)
    }

    func testReturningToAllRefetchesCatalogAndKeepsPlayingSavedTrack() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([first]))
        await repository.setExploreResult(.success([first, second]))
        await player.openPlayer(first)
        try await player.setPlaybackCollection(.saved)
        let loads = engine.loadedURLs
        try await player.setPlaybackCollection(.all)
        XCTAssertEqual(player.playbackCollection, .all)
        XCTAssertEqual(player.vinylStream.map(\.id), [first.id, second.id])
        XCTAssertEqual(engine.loadedURLs, loads)
        await player.next()
        XCTAssertEqual(player.current?.id, second.id)
    }

    func testRemovingCurrentSavedTrackAdvancesAndRemovingLastPausesWithoutFallback() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([first, second]))
        await repository.setToggleSaveResult(.success(SaveResponse(saved: false, saveCount: 0)))
        await player.openPlayer(first)
        try await player.setPlaybackCollection(.saved)
        _ = try await player.toggleSaved(first)
        XCTAssertEqual(player.current?.id, second.id)
        XCTAssertEqual(player.vinylStream.map(\.id), [second.id])
        _ = try await player.toggleSaved(second)
        XCTAssertEqual(player.playbackCollection, .saved)
        XCTAssertEqual(player.phase, .paused)
        XCTAssertTrue(player.vinylStream.isEmpty)
        let loads = engine.loadedURLs
        await player.toggle(second)
        engine.finish()
        XCTAssertEqual(engine.loadedURLs, loads)
        XCTAssertEqual(engine.restartCount, 0)
        XCTAssertNotNil(player.error)
    }

    func testLoggingOutClearsSavedQueueAndStopsSavedPlayback() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([first]))
        await player.openPlayer(first)
        try await player.setPlaybackCollection(.saved)
        player.clearSavedSoundscapes()
        XCTAssertNil(player.current)
        XCTAssertNil(player.presentedSoundscape)
        XCTAssertTrue(player.savedSoundscapeIDs.isEmpty)
        XCTAssertEqual(player.playbackCollection, .all)
    }

    func testInFlightSavedRequestCannotRestoreAccountDataAfterClear() async throws {
        let repository = StubSoundscapeRepository()
        let player = makePlayer(repository, StubAudioPlaybackEngine())
        await repository.setSavedResult(.success([first]))
        await repository.suspendNextSavedLoad()
        let changing = Task { try await player.setPlaybackCollection(.saved) }
        for _ in 0..<1000 {
            if await repository.isSavedLoadWaiting { break }
            await Task.yield()
        }
        let waiting = await repository.isSavedLoadWaiting
        XCTAssertTrue(waiting)
        player.clearSavedSoundscapes()
        await repository.resumeSavedLoad()
        do { try await changing.value; XCTFail("Cleared account cannot reappear") }
        catch is CancellationError {}
        XCTAssertNil(player.current)
        XCTAssertTrue(player.savedSoundscapeIDs.isEmpty)
        XCTAssertEqual(player.playbackCollection, .all)
        XCTAssertFalse(player.isChangingCollection)
    }

    func testSavedRefreshFailureClearsStaleQueueAndPauses() async throws {
        let repository = StubSoundscapeRepository()
        let player = makePlayer(repository, StubAudioPlaybackEngine())
        await repository.setSavedResult(.success([first]))
        await player.openPlayer(first)
        try await player.setPlaybackCollection(.saved)
        await repository.setSavedResult(.failure(.transport("offline")))
        do { _ = try await player.refreshSavedSoundscapes(); XCTFail("Expected failure") }
        catch let error as AppError { XCTAssertEqual(error, .transport("offline")) }
        XCTAssertTrue(player.vinylStream.isEmpty)
        XCTAssertEqual(player.phase, .paused)
        XCTAssertEqual(player.playbackCollection, .saved)
    }

    func testReselectingSavedAfterServerRemovalCannotKeepOldQueue() async throws {
        let repository = StubSoundscapeRepository()
        let player = makePlayer(repository, StubAudioPlaybackEngine())
        await repository.setSavedResult(.success([first]))
        await player.openPlayer(first)
        try await player.setPlaybackCollection(.saved)
        await repository.setSavedResult(.success([]))
        do { try await player.setPlaybackCollection(.saved); XCTFail("Expected an empty saved queue") }
        catch let error as AppError { XCTAssertEqual(error, .invalidRequest(loc(.playerSavedEmpty))) }
        XCTAssertTrue(player.vinylStream.isEmpty)
        XCTAssertEqual(player.phase, .paused)
        XCTAssertEqual(player.playbackCollection, .saved)
    }

    func testSavedStartsContinuousButKeepsExplicitShuffleOrPausedCurrent() async throws {
        let repository = StubSoundscapeRepository()
        let player = makePlayer(repository, StubAudioPlaybackEngine())
        await repository.setSavedResult(.success([first]))
        await player.openPlayer(first)
        player.pause()
        try await player.setPlaybackCollection(.saved)
        XCTAssertEqual(player.phase, .paused)
        XCTAssertEqual(player.playbackMode, .continuous)
        player.setPlaybackMode(.repeatOne)
        try await player.setPlaybackCollection(.saved)
        XCTAssertEqual(player.playbackMode, .repeatOne, "An explicit repeat choice is not reset by a refresh")
    }

    func testChoosingSavedFromLibraryRevalidatesAndStartsSavedQueue() async throws {
        let repository = StubSoundscapeRepository()
        let player = makePlayer(repository, StubAudioPlaybackEngine())
        await repository.setSavedResult(.success([first, second]))
        try await player.openSavedPlayer(second)
        XCTAssertEqual(player.current?.id, second.id)
        XCTAssertEqual(player.presentedSoundscape?.id, second.id)
        XCTAssertEqual(player.playbackCollection, .saved)
        XCTAssertEqual(player.vinylStream.map(\.id), [first.id, second.id])
        await player.openPlayer(first, source: .explore)
        XCTAssertEqual(player.playbackCollection, .all)
    }

    func testSavedAutomaticAdvanceDoesNotReopenDismissedPlayer() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([first, second]))
        try await player.openSavedPlayer(first)
        player.setPlaybackMode(.continuous)
        player.dismissPlayer(stopPlayback: false)
        engine.startPlaying()
        engine.finish()
        await waitFor { player.current?.id == self.second.id }
        XCTAssertNil(player.presentedSoundscape)
    }

    func testStoppingBeforeScheduledAutoAdvanceCannotRestartSavedAudio() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([first, second]))
        try await player.openSavedPlayer(first)
        engine.startPlaying()
        engine.finish()
        player.clearSavedSoundscapes()
        for _ in 0..<100 { await Task.yield() }
        XCTAssertNil(player.current)
        XCTAssertEqual(player.phase, .idle)
        XCTAssertEqual(engine.loadedURLs.count, 1)
    }

    func testPausingDuringSavedLoadDoesNotStartAnotherRecordingLater() async throws {
        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let player = makePlayer(repository, engine)
        await repository.setSavedResult(.success([second]))
        await player.openPlayer(first)
        engine.startPlaying()
        await repository.suspendNextSavedLoad()
        let changing = Task { try await player.setPlaybackCollection(.saved) }
        for _ in 0..<1000 {
            if await repository.isSavedLoadWaiting { break }
            await Task.yield()
        }
        player.pause()
        await repository.resumeSavedLoad()
        do { try await changing.value; XCTFail("A later pause must win") }
        catch is CancellationError {}
        XCTAssertEqual(player.current?.id, first.id)
        XCTAssertEqual(player.phase, .paused)
        XCTAssertEqual(engine.loadedURLs.count, 1)
    }

    func testSlowSavedSelectionCannotOverrideExplicitAllSelection() async throws {
        let repository = StubSoundscapeRepository()
        let player = makePlayer(repository, StubAudioPlaybackEngine())
        await repository.setSavedResult(.success([second]))
        await repository.setExploreResult(.success([first, second]))
        await player.openPlayer(first)
        await repository.suspendNextSavedLoad()
        let changing = Task { try await player.setPlaybackCollection(.saved) }
        for _ in 0..<1000 {
            if await repository.isSavedLoadWaiting { break }
            await Task.yield()
        }
        try await player.setPlaybackCollection(.all)
        await repository.resumeSavedLoad()
        do { try await changing.value; XCTFail("Older request must be cancelled") }
        catch is CancellationError {}
        XCTAssertEqual(player.playbackCollection, .all)
        XCTAssertEqual(player.current?.id, first.id)
    }

    private func makePlayer(_ repository: StubSoundscapeRepository, _ engine: StubAudioPlaybackEngine) -> AudioPlayerController {
        AudioPlayerController(repository: repository, engine: engine, audioSession: StubPlaybackAudioSession())
    }

    private func waitFor(_ predicate: () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<1000 {
            if predicate() { return }
            await Task.yield()
        }
        XCTAssertTrue(predicate(), file: file, line: line)
    }
}
