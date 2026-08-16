import Foundation
import OSLog

actor CachedSoundscapeRepository: SoundscapeRepository {
    private let upstream: any SoundscapeRepository
    private let cache: any PublicSoundscapeCaching
    private let freshness: TimeInterval
    private let maximumStaleAge: TimeInterval
    private let now: @Sendable () -> Date
    private let logger = Logger(subsystem: "tech.panor.soundscape", category: "public-cache")
    private var exploreTasks: [String: Task<[Soundscape], Error>] = [:]
    private var rankingsTask: Task<[RankingLane], Error>?

    init(
        upstream: any SoundscapeRepository,
        cache: any PublicSoundscapeCaching,
        freshness: TimeInterval = 300,
        maximumStaleAge: TimeInterval = 604_800,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.upstream = upstream
        self.cache = cache
        self.freshness = freshness
        self.maximumStaleAge = maximumStaleAge
        self.now = now
    }

    func explore(category: String?, policy: RepositoryReadPolicy) async throws -> [Soundscape] {
        let key = Self.exploreKey(category)
        let cached = await cachedExplore(for: key)
        if policy == .cacheFirst, let cached, isFresh(cached.savedAt) {
            return cached.value
        }

        do {
            let items = try await remoteExplore(category: category, key: key)
            await saveExplore(items, for: key)
            return items
        } catch {
            if let cached, canUseAsFallback(cached.savedAt) { return cached.value }
            throw error
        }
    }

    func rankings(policy: RepositoryReadPolicy) async throws -> [RankingLane] {
        let cached = await cachedRankings()
        if policy == .cacheFirst, let cached, isFresh(cached.savedAt) {
            return cached.value
        }

        do {
            let lanes = try await remoteRankings()
            await saveRankings(lanes)
            return lanes
        } catch {
            if let cached, canUseAsFallback(cached.savedAt) { return cached.value }
            throw error
        }
    }

    func mine() async throws -> [Soundscape] { try await upstream.mine() }

    func create(_ draft: CreateSoundscapeDraft) async throws -> Soundscape {
        let soundscape = try await upstream.create(draft)
        await invalidatePublicCache()
        return soundscape
    }

    func suggestTitle(_ request: TitleSuggestionRequest) async throws -> TitleSuggestion {
        try await upstream.suggestTitle(request)
    }

    func suggestCover(_ request: CoverSuggestionRequest) async throws -> CoverSuggestion {
        try await upstream.suggestCover(request)
    }

    func reportPlay(id: Int, listenedSeconds: Int) async throws -> PlayResponse {
        try await upstream.reportPlay(id: id, listenedSeconds: listenedSeconds)
    }

    func toggleSave(id: Int) async throws -> SaveResponse {
        let response = try await upstream.toggleSave(id: id)
        await invalidatePublicCache()
        return response
    }

    func setVisibility(id: Int, isPublic: Bool) async throws {
        try await upstream.setVisibility(id: id, isPublic: isPublic)
        await invalidatePublicCache()
    }

    func delete(id: Int) async throws {
        try await upstream.delete(id: id)
        await invalidatePublicCache()
    }

    private func remoteExplore(category: String?, key: String) async throws -> [Soundscape] {
        if let task = exploreTasks[key] { return try await task.value }
        let task = Task { [upstream] in
            try await upstream.explore(category: category, policy: .reloadIgnoringCache)
        }
        exploreTasks[key] = task
        defer { exploreTasks[key] = nil }
        return try await task.value
    }

    private func remoteRankings() async throws -> [RankingLane] {
        if let rankingsTask { return try await rankingsTask.value }
        let task = Task { [upstream] in
            try await upstream.rankings(policy: .reloadIgnoringCache)
        }
        rankingsTask = task
        defer { rankingsTask = nil }
        return try await task.value
    }

    private func cachedExplore(for key: String) async -> CacheEntry<[Soundscape]>? {
        do { return try await cache.explore(for: key) }
        catch {
            logger.error("Reading Explore cache failed")
            return nil
        }
    }

    private func saveExplore(_ items: [Soundscape], for key: String) async {
        do { try await cache.saveExplore(CacheEntry(value: items, savedAt: now()), for: key) }
        catch { logger.error("Writing Explore cache failed") }
    }

    private func cachedRankings() async -> CacheEntry<[RankingLane]>? {
        do { return try await cache.rankings() }
        catch {
            logger.error("Reading Rankings cache failed")
            return nil
        }
    }

    private func saveRankings(_ lanes: [RankingLane]) async {
        do { try await cache.saveRankings(CacheEntry(value: lanes, savedAt: now())) }
        catch { logger.error("Writing Rankings cache failed") }
    }

    private func invalidatePublicCache() async {
        do { try await cache.removeAll() }
        catch { logger.error("Invalidating public cache failed") }
    }

    private func isFresh(_ savedAt: Date) -> Bool {
        now().timeIntervalSince(savedAt) < freshness
    }

    private func canUseAsFallback(_ savedAt: Date) -> Bool {
        now().timeIntervalSince(savedAt) <= maximumStaleAge
    }

    private static func exploreKey(_ category: String?) -> String {
        let normalized = category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalized.isEmpty ? "all" : normalized
    }
}
