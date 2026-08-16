import XCTest
@testable import Soundscape

final class CachedSoundscapeRepositoryTests: XCTestCase {
    func testFreshExploreCacheAvoidsRepeatedBackendLoads() async throws {
        let upstream = StubSoundscapeRepository()
        let cache = InMemoryPublicSoundscapeCache()
        let repository = CachedSoundscapeRepository(upstream: upstream, cache: cache)
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))

        _ = try await repository.explore(category: nil, policy: .cacheFirst)
        _ = try await repository.explore(category: nil, policy: .cacheFirst)

        let callCount = await upstream.exploreCallCount
        XCTAssertEqual(callCount, 1)
    }

    func testForcedRefreshBypassesFreshCache() async throws {
        let upstream = StubSoundscapeRepository()
        let cache = InMemoryPublicSoundscapeCache()
        let repository = CachedSoundscapeRepository(upstream: upstream, cache: cache)
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))
        _ = try await repository.explore(category: nil, policy: .cacheFirst)

        _ = try await repository.explore(category: nil, policy: .reloadIgnoringCache)

        let callCount = await upstream.exploreCallCount
        XCTAssertEqual(callCount, 2)
    }

    func testStaleExploreCacheSurvivesBackendFailure() async throws {
        let upstream = StubSoundscapeRepository()
        let cache = InMemoryPublicSoundscapeCache()
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
        let repository = CachedSoundscapeRepository(
            upstream: upstream,
            cache: cache,
            freshness: 60,
            now: clock.current
        )
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))
        _ = try await repository.explore(category: nil, policy: .cacheFirst)
        clock.set(Date(timeIntervalSince1970: 1_061))
        await upstream.setExploreResult(.failure(.transport("offline")))

        let items = try await repository.explore(category: nil, policy: .cacheFirst)

        XCTAssertEqual(items, [TestFixtures.soundscape])
        let callCount = await upstream.exploreCallCount
        XCTAssertEqual(callCount, 2)
    }

    func testConcurrentExploreLoadsShareOneBackendRequest() async throws {
        let upstream = StubSoundscapeRepository()
        let cache = InMemoryPublicSoundscapeCache()
        let repository = CachedSoundscapeRepository(upstream: upstream, cache: cache)
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))
        await upstream.setExploreDelay(.milliseconds(100))

        async let first = repository.explore(category: nil, policy: .cacheFirst)
        async let second = repository.explore(category: nil, policy: .cacheFirst)
        _ = try await (first, second)

        let callCount = await upstream.exploreCallCount
        XCTAssertEqual(callCount, 1)
    }

    func testExpiredStaleCacheDoesNotHideBackendFailure() async throws {
        let upstream = StubSoundscapeRepository()
        let cache = InMemoryPublicSoundscapeCache()
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
        let repository = CachedSoundscapeRepository(
            upstream: upstream,
            cache: cache,
            freshness: 60,
            maximumStaleAge: 120,
            now: clock.current
        )
        await upstream.setExploreResult(.success([TestFixtures.soundscape]))
        _ = try await repository.explore(category: nil, policy: .cacheFirst)
        clock.set(Date(timeIntervalSince1970: 1_121))
        await upstream.setExploreResult(.failure(.transport("offline")))

        do {
            _ = try await repository.explore(category: nil, policy: .cacheFirst)
            XCTFail("Expected the backend failure after the stale ceiling")
        } catch let error as AppError {
            XCTAssertEqual(error, .transport("offline"))
        }
    }
}

private final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var now: Date

    init(now: Date) { self.now = now }

    func current() -> Date {
        lock.withLock { now }
    }

    func set(_ date: Date) {
        lock.withLock { now = date }
    }
}

private actor InMemoryPublicSoundscapeCache: PublicSoundscapeCaching {
    private var exploreEntries: [String: CacheEntry<[Soundscape]>] = [:]
    private var rankingEntry: CacheEntry<[RankingLane]>?

    func explore(for key: String) -> CacheEntry<[Soundscape]>? { exploreEntries[key] }
    func saveExplore(_ entry: CacheEntry<[Soundscape]>, for key: String) { exploreEntries[key] = entry }
    func rankings() -> CacheEntry<[RankingLane]>? { rankingEntry }
    func saveRankings(_ entry: CacheEntry<[RankingLane]>) { rankingEntry = entry }
    func removeAll() {
        exploreEntries = [:]
        rankingEntry = nil
    }
}
