import XCTest
@testable import Soundscape

final class ProtectedFileResonanceStateStoreTests: XCTestCase {
    func testRoundTripAndReset() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("personalization.json")
        let store = ProtectedFileResonanceStateStore(fileURL: fileURL)
        let state = ResonancePersonalizationState(
            profile: ResonanceProfile(longTerm: .calmNature, longTermObservations: 2),
            impressions: [],
            feedback: []
        )

        try await store.save(state)
        let restored = try await store.load()
        XCTAssertEqual(restored, state)

        try await store.reset()
        let resetState = try await store.load()
        XCTAssertNil(resetState)
    }
}
