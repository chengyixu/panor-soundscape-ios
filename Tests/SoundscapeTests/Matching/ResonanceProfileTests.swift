import XCTest
@testable import Soundscape

final class ResonanceProfileTests: XCTestCase {
    func testNotNowChangesSessionWithoutChangingLongTermProfile() {
        var profile = ResonanceProfile(
            longTerm: .calmNature,
            session: .calmNature,
            longTermObservations: 8,
            sessionObservations: 2
        )
        let originalLongTerm = profile.longTerm

        profile.apply(
            ResonanceFeedback(kind: .skipped, reason: .notNow, listenedSeconds: 3),
            content: .calmNature,
            mode: .focus,
            at: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(profile.longTerm, originalLongTerm)
        XCTAssertNotEqual(profile.session, .calmNature)
    }

    func testExplicitDislikeUpdatesLongTermProfileMoreSlowlyThanSession() throws {
        var profile = ResonanceProfile(
            longTerm: .calmNature,
            session: .calmNature,
            longTermObservations: 8,
            sessionObservations: 2
        )

        profile.apply(
            ResonanceFeedback(kind: .skipped, reason: .dislike, listenedSeconds: 2),
            content: .calmNature,
            mode: .discover,
            at: Date(timeIntervalSince1970: 10)
        )

        let session = try XCTUnwrap(profile.session)
        let longTerm = try XCTUnwrap(profile.longTerm)
        XCTAssertLessThan(session.similarity(to: .calmNature), longTerm.similarity(to: .calmNature))
        XCTAssertEqual(profile.sessionObservations, 3)
        XCTAssertEqual(profile.longTermObservations, 9)
    }

    func testSessionExpiresWithoutErasingLongTermTaste() {
        var profile = ResonanceProfile(
            longTerm: .calmNature,
            session: .calmUrban,
            longTermObservations: 4,
            sessionObservations: 2,
            sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            lastSessionActivityAt: Date(timeIntervalSince1970: 0)
        )

        profile.expireSessionIfNeeded(
            now: Date(timeIntervalSince1970: 7 * 60 * 60),
            timeout: 6 * 60 * 60
        )

        XCTAssertNil(profile.session)
        XCTAssertEqual(profile.longTerm, .calmNature)
        XCTAssertNotEqual(profile.sessionID, UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    }
}
