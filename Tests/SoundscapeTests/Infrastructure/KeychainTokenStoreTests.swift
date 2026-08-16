import XCTest
@testable import Soundscape

final class KeychainTokenStoreTests: XCTestCase {
    func testTokenRoundTripUsesRealKeychain() async throws {
        let store = KeychainTokenStore(
            service: "tech.panor.soundscape.tests.\(UUID().uuidString)",
            account: "round-trip"
        )
        try? await store.clear()
        defer { Task { try? await store.clear() } }

        try await store.setToken("keychain-round-trip")

        let token = try await store.token()
        XCTAssertEqual(token, "keychain-round-trip")
        try await store.clear()
        let clearedToken = try await store.token()
        XCTAssertNil(clearedToken)
    }
}
