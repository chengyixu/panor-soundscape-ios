import XCTest
@testable import Soundscape

@MainActor
final class ExploreViewModelTests: XCTestCase {
    func testLoadPublishesRepositoryItems() async {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let model = ExploreViewModel(repository: repository)

        await model.load()

        guard case .loaded(let items) = model.state else { return XCTFail("Expected loaded state") }
        XCTAssertEqual(items, [TestFixtures.soundscape])
    }

    func testFailureRemainsDistinctFromEmpty() async {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.failure(.transport("offline")))
        let model = ExploreViewModel(repository: repository)

        await model.load()

        guard case .failed(let error) = model.state else { return XCTFail("Expected failed state") }
        XCTAssertEqual(error, .transport("offline"))
    }
}

