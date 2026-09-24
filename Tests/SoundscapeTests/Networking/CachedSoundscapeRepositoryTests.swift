import XCTest
@testable import Soundscape

final class CachedSoundscapeRepositoryTests: XCTestCase {
    func testFeedRefetchesAfterSuccessSoRemovedContentCannotRemainVisible() async throws {
        let upstream = StubSoundscapeRepository()
        let repository = CachedSoundscapeRepository(upstream: upstream)
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))
        let first = try await repository.explore(category: nil, policy: .cacheFirst)
        XCTAssertEqual(first, [TestFixtures.soundscape])
        await upstream.setExploreResult(.success([]))
        let items = try await repository.explore(category: nil, policy: .cacheFirst)
        XCTAssertTrue(items.isEmpty)
        let count = await upstream.exploreCallCount
        XCTAssertEqual(count, 2)
    }

    func testFeedFailsClosedWhenServerIsUnavailable() async throws {
        let upstream = StubSoundscapeRepository()
        let repository = CachedSoundscapeRepository(upstream: upstream)
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))
        _ = try await repository.explore(category: nil, policy: .cacheFirst)
        await upstream.setExploreResult(.failure(.transport("offline")))
        do {
            _ = try await repository.explore(category: nil, policy: .cacheFirst)
            XCTFail("Previously published content must not outlive server moderation")
        } catch let error as AppError {
            XCTAssertEqual(error, .transport("offline"))
        }
    }

    func testRankingsFailClosedWhenServerIsUnavailable() async throws {
        let upstream = StubSoundscapeRepository()
        let repository = CachedSoundscapeRepository(upstream: upstream)
        _ = try await repository.rankings(policy: .cacheFirst)
        await upstream.setRankingResult(.failure(.transport("offline")))
        do {
            _ = try await repository.rankings(policy: .cacheFirst)
            XCTFail("Rankings must not outlive server moderation")
        } catch let error as AppError {
            XCTAssertEqual(error, .transport("offline"))
        }
    }

    func testConcurrentExploreLoadsShareOneInFlightRequest() async throws {
        let upstream = StubSoundscapeRepository()
        let repository = CachedSoundscapeRepository(upstream: upstream)
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))
        await upstream.setExploreDelay(.milliseconds(100))
        async let first = repository.explore(category: nil, policy: .cacheFirst)
        async let second = repository.explore(category: nil, policy: .cacheFirst)
        _ = try await (first, second)
        let count = await upstream.exploreCallCount
        XCTAssertEqual(count, 1)
    }
}
