import XCTest
@testable import Soundscape

final class DiskPublicSoundscapeCacheTests: XCTestCase {
    func testSavedExploreDataSurvivesCacheRecreation() async throws {
        let fileURL = temporaryFileURL()
        let savedAt = Date(timeIntervalSince1970: 1_000)
        let first = DiskPublicSoundscapeCache(fileURL: fileURL)
        try await first.saveExplore(
            CacheEntry(value: [TestFixtures.soundscape], savedAt: savedAt),
            for: "all"
        )

        let second = DiskPublicSoundscapeCache(fileURL: fileURL)
        let restored = try await second.explore(for: "all")

        XCTAssertEqual(restored?.value, [TestFixtures.soundscape])
        XCTAssertEqual(restored?.savedAt, savedAt)
    }

    func testCorruptCacheStartsEmptyInsteadOfCrashing() async throws {
        let fileURL = temporaryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: fileURL)

        let cache = DiskPublicSoundscapeCache(fileURL: fileURL)

        let restored = try await cache.explore(for: "all")
        XCTAssertNil(restored)
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("public-content-v1.json", isDirectory: false)
    }
}
