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

    func testDeleteFailureRemainsVisibleAndDoesNotFalseRefresh() async {
        let repository = StubSoundscapeRepository()
        await repository.setDeleteResult(.failure(.authenticationRequired))
        let model = LibraryViewModel(repository: repository)

        await model.delete(TestFixtures.soundscape)

        XCTAssertEqual(model.mutationError, .authenticationRequired)
        guard case .idle = model.state else { return XCTFail("Failed mutation must not report refreshed state") }
    }
}
