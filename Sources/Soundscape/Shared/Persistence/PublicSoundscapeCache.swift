import Foundation

struct CacheEntry<Value: Codable & Sendable>: Codable, Sendable {
    let value: Value
    let savedAt: Date
}

protocol PublicSoundscapeCaching: Sendable {
    func explore(for key: String) async throws -> CacheEntry<[Soundscape]>?
    func saveExplore(_ entry: CacheEntry<[Soundscape]>, for key: String) async throws
    func rankings() async throws -> CacheEntry<[RankingLane]>?
    func saveRankings(_ entry: CacheEntry<[RankingLane]>) async throws
    func removeAll() async throws
}

actor DiskPublicSoundscapeCache: PublicSoundscapeCaching {
    private struct Snapshot: Codable {
        var explore: [String: CacheEntry<[Soundscape]>] = [:]
        var rankings: CacheEntry<[RankingLane]>?
    }

    private let fileURL: URL
    private var snapshot: Snapshot

    init(fileURL: URL = DiskPublicSoundscapeCache.defaultFileURL()) {
        self.fileURL = fileURL
        snapshot = Self.load(from: fileURL)
    }

    func explore(for key: String) -> CacheEntry<[Soundscape]>? {
        snapshot.explore[key]
    }

    func saveExplore(_ entry: CacheEntry<[Soundscape]>, for key: String) throws {
        snapshot.explore[key] = entry
        try persist()
    }

    func rankings() -> CacheEntry<[RankingLane]>? {
        snapshot.rankings
    }

    func saveRankings(_ entry: CacheEntry<[RankingLane]>) throws {
        snapshot.rankings = entry
        try persist()
    }

    func removeAll() throws {
        snapshot = Snapshot()
        try persist()
    }

    private func persist() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func load(from fileURL: URL) -> Snapshot {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return Snapshot()
        }
        return snapshot
    }

    private static func defaultFileURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Soundscape", isDirectory: true)
            .appendingPathComponent("public-content-v1.json", isDirectory: false)
    }
}
