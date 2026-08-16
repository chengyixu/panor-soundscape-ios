import XCTest
@testable import Soundscape

@MainActor
final class RankingsViewModelTests: XCTestCase {
    func testLoadPublishesRankingLanes() async {
        let repository = StubSoundscapeRepository()
        let lane = RankingLane(category: "地方", items: [TestFixtures.soundscape])
        await repository.setRankingResult(.success([lane]))
        let model = RankingsViewModel(repository: repository)

        await model.load()

        guard case .loaded(let lanes) = model.state else { return XCTFail("Expected loaded state") }
        XCTAssertEqual(lanes, [lane])
    }

    func testLoadPreservesExplicitFailure() async {
        let repository = StubSoundscapeRepository()
        await repository.setRankingResult(.failure(.server(status: 503, code: "rankings_unavailable", message: "稍后再试")))
        let model = RankingsViewModel(repository: repository)

        await model.load()

        guard case .failed(let error) = model.state else { return XCTFail("Expected failed state") }
        XCTAssertEqual(error, .server(status: 503, code: "rankings_unavailable", message: "稍后再试"))
    }
}
