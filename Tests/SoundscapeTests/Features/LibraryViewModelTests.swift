import XCTest
@testable import Soundscape

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func testVisibilityMutationUsesInverseStateAndReloads() async {
        let repository = StubSoundscapeRepository()
        await repository.setMineResult(.success([TestFixtures.soundscape]))
        let model = LibraryViewModel(repository: repository)

        await model.toggleVisibility(TestFixtures.soundscape)

        let calls = await repository.visibilityCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.id, TestFixtures.soundscape.id)
        XCTAssertEqual(calls.first?.isPublic, false)
        guard case .loaded(let items) = model.state else { return XCTFail("Expected refreshed library") }
        XCTAssertEqual(items, [TestFixtures.soundscape])
        XCTAssertNil(model.mutationError)
    }

    func testLoadPublishesRecordingsAndServerBackedFavoritesIndependently() async {
        let repository = StubSoundscapeRepository()
        await repository.setMineResult(.success([TestFixtures.soundscape]))
        await repository.setSavedResult(.success([TestFixtures.soundscapeWithoutCoordinate]))
        let model = LibraryViewModel(repository: repository)

        await model.load()

        guard case .loaded(let recordings) = model.state else { return XCTFail("Expected recordings") }
        guard case .loaded(let favorites) = model.favoriteState else { return XCTFail("Expected favorites") }
        XCTAssertEqual(recordings, [TestFixtures.soundscape])
        XCTAssertEqual(favorites, [TestFixtures.soundscapeWithoutCoordinate])
    }

    func testFavoriteFailureDoesNotHideOwnedRecordings() async {
        let repository = StubSoundscapeRepository()
        await repository.setMineResult(.success([TestFixtures.soundscape]))
        await repository.setSavedResult(.failure(.transport("offline")))
        let model = LibraryViewModel(repository: repository)

        await model.load()

        guard case .loaded(let recordings) = model.state else { return XCTFail("Expected recordings") }
        XCTAssertEqual(recordings, [TestFixtures.soundscape])
        guard case .failed(let error) = model.favoriteState else { return XCTFail("Expected favorite failure") }
        XCTAssertEqual(error, .transport("offline"))
    }

    func testDeleteFailureRemainsVisibleAndDoesNotFalseRefresh() async {
        let repository = StubSoundscapeRepository()
        await repository.setDeleteResult(.failure(.authenticationRequired))
        let model = LibraryViewModel(repository: repository)

        await model.delete(TestFixtures.soundscape)

        XCTAssertEqual(model.mutationError, .authenticationRequired)
        guard case .idle = model.state else { return XCTFail("Failed mutation must not report refreshed state") }
    }

    func testStaleLoadCannotOverwriteNewerSuccessfulRefresh() async {
        let repository = StubSoundscapeRepository()
        await repository.setMineDelay(.milliseconds(100))
        await repository.setMineResult(.success([]))
        let model = LibraryViewModel(repository: repository)

        async let staleLoad: Void = model.load()
        try? await Task.sleep(for: .milliseconds(10))
        await repository.setMineDelay(nil)
        await repository.setMineResult(.success([TestFixtures.soundscape]))
        async let freshRefresh: Void = model.load()
        _ = await (staleLoad, freshRefresh)

        guard case .loaded(let items) = model.state else { return XCTFail("Expected loaded library") }
        XCTAssertEqual(items, [TestFixtures.soundscape])
    }
}
