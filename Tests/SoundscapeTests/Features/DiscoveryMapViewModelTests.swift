import XCTest
@testable import Soundscape

@MainActor
final class DiscoveryMapViewModelTests: XCTestCase {
    func testSearchMatchesPlaceAndThemeAndUpdatesSelection() async {
        let repository = StubSoundscapeRepository()
        var item = TestFixtures.soundscape
        item.theme = ListeningTheme(id: 3, title: "City cycling", description: "Along the route", kind: .topic, startsOn: nil, endsOn: nil, recordingCount: 1)
        await repository.setExploreResult(.success([item]))
        let model = DiscoveryMapViewModel(repository: repository)
        await model.load()
        model.query = "CYCLING"
        XCTAssertEqual(model.results.map(\.id), [item.id])
        model.query = "no such recording"
        XCTAssertTrue(model.results.isEmpty)
        XCTAssertNil(model.selectedID)
        model.query = "Bao'an"
        XCTAssertEqual(model.results.map(\.id), [item.id])
    }

    func testSearchThisAreaHandlesAntimeridianAndDoesNotRunOnEveryPan() async {
        let crossing = RecordingMapArea(latitude: 0, longitude: 179, latitudeDelta: 20, longitudeDelta: 8)
        XCTAssertTrue(crossing.contains(latitude: 0, longitude: -179))
        XCTAssertFalse(crossing.contains(latitude: 0, longitude: 150))
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let model = DiscoveryMapViewModel(repository: repository)
        await model.load()
        model.cameraArea = crossing
        XCTAssertEqual(model.results.count, 1, "Panning alone cannot filter the list")
        model.searchThisArea()
        XCTAssertTrue(model.results.isEmpty)
        model.clearArea()
        XCTAssertEqual(model.results.count, 1)
    }

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
