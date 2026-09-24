import XCTest
@testable import Soundscape

@MainActor
final class DiscoveryMapViewModelTests: XCTestCase {
    func testLoadFiltersItemsWithoutCoordinatesAndSelectsFirstMarker() async {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscapeWithoutCoordinate, TestFixtures.soundscape]))
        let model = DiscoveryMapViewModel(repository: repository)

        await model.load()

        guard case .loaded(let items) = model.state else { return XCTFail("Expected loaded state") }
        XCTAssertEqual(items, [TestFixtures.soundscape])
        XCTAssertEqual(model.selectedID, TestFixtures.soundscape.id)
    }

    func testReloadReplacesSelectionThatNoLongerExists() async {
        let repository = StubSoundscapeRepository()
        let model = DiscoveryMapViewModel(repository: repository)
        model.selectedID = 999
        await repository.setExploreResult(.success([TestFixtures.soundscape]))

        await model.load()

        XCTAssertEqual(model.selectedID, TestFixtures.soundscape.id)
    }

    func testForcedRefreshBypassesPublicCache() async {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let model = DiscoveryMapViewModel(repository: repository)

        await model.load(forceRefresh: true)

        let policies = await repository.explorePolicies
        XCTAssertEqual(policies.count, 1)
        guard let policy = policies.first else { return }
        guard case .reloadIgnoringCache = policy else {
            return XCTFail("Expected reloadIgnoringCache")
        }
    }

    func testRefreshFailureRemovesUnverifiedMapMarkers() async {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let model = DiscoveryMapViewModel(repository: repository)
        await model.load()
        await repository.setExploreResult(.failure(.transport("offline")))

        await model.load(forceRefresh: true)

        guard case .failed = model.state else { return XCTFail("Unverified markers must not remain visible") }
        XCTAssertNil(model.selectedID)
    }
}
