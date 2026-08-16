import XCTest
@testable import Soundscape

final class LocalResonanceMatchingServiceTests: XCTestCase {
    func testRecommendationsPersistSessionIntentWithoutLoggingPrivateQuery() async throws {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let store = InMemoryResonanceStateStore()
        let service = LocalResonanceMatchingService(
            repository: repository,
            store: store,
            now: { Date(timeIntervalSince1970: 100) }
        )
        let request = ResonanceRequest(
            mode: .recall,
            queryText: "private childhood memory",
            confidence: 0.8,
            allowsMemoryAnchors: true,
            requestedAt: Date(timeIntervalSince1970: 100)
        )

        let batch = try await service.recommendations(for: request, limit: 5)
        let snapshot = await store.snapshot()
        let state = try XCTUnwrap(snapshot)

        XCTAssertEqual(batch.items.map(\.soundscape.id), [TestFixtures.soundscape.id])
        XCTAssertEqual(state.profile.lastMode, .recall)
        XCTAssertNotNil(state.profile.session)
        XCTAssertTrue(state.impressions.isEmpty)
        XCTAssertFalse(String(decoding: try JSONEncoder().encode(state), as: UTF8.self).contains(request.queryText))
    }

    func testImpressionsAreDeduplicatedAndBecomeRecentExposure() async throws {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let store = InMemoryResonanceStateStore()
        let service = LocalResonanceMatchingService(
            repository: repository,
            store: store,
            now: { Date(timeIntervalSince1970: 100) }
        )
        let batch = try await service.recommendations(
            for: ResonanceRequest(mode: .discover, requestedAt: Date(timeIntervalSince1970: 100)),
            limit: 5
        )
        let context = try XCTUnwrap(batch.context(for: TestFixtures.soundscape.id))
        let impression = RecommendationImpression(context: context, shownAt: Date(timeIntervalSince1970: 101))

        try await service.recordImpressions([impression, impression])
        let snapshot = await store.snapshot()
        let state = try XCTUnwrap(snapshot)

        XCTAssertEqual(state.impressions.count, 1)
        XCTAssertEqual(state.profile.recentlyExposedSoundscapeIDs, [TestFixtures.soundscape.id])
    }

    func testFeedbackUpdatesProfilesAndRetainsRawEvent() async throws {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let store = InMemoryResonanceStateStore()
        let service = LocalResonanceMatchingService(
            repository: repository,
            store: store,
            now: { Date(timeIntervalSince1970: 100) }
        )
        let batch = try await service.recommendations(
            for: ResonanceRequest(mode: .focus, requestedAt: Date(timeIntervalSince1970: 100)),
            limit: 5
        )
        let context = try XCTUnwrap(batch.context(for: TestFixtures.soundscape.id))
        let feedback = ResonanceFeedback(kind: .saved, listenedSeconds: 30)

        try await service.recordFeedback(feedback, for: TestFixtures.soundscape, context: context)
        let snapshot = await store.snapshot()
        let state = try XCTUnwrap(snapshot)

        XCTAssertEqual(state.feedback.last?.feedback, feedback)
        XCTAssertGreaterThan(state.profile.sessionObservations, 1)
        XCTAssertEqual(state.profile.longTermObservations, 1)
    }

    func testReturningRecommendationsReuseLastModeAfterSessionRefresh() async throws {
        let repository = StubSoundscapeRepository()
        await repository.setExploreResult(.success([TestFixtures.soundscape]))
        let store = InMemoryResonanceStateStore(state: ResonancePersonalizationState(
            profile: ResonanceProfile(
                longTerm: .calmNature,
                longTermObservations: 5,
                lastMode: .focus,
                lastSessionActivityAt: Date(timeIntervalSince1970: 0)
            ),
            impressions: [],
            feedback: []
        ))
        let service = LocalResonanceMatchingService(
            repository: repository,
            store: store,
            now: { Date(timeIntervalSince1970: 7 * 60 * 60) }
        )

        let batch = try await service.returningRecommendations(limit: 5)
        let snapshot = await store.snapshot()
        let state = try XCTUnwrap(snapshot)

        XCTAssertEqual(batch.request.mode, .focus)
        XCTAssertEqual(state.profile.longTerm, .calmNature)
        XCTAssertNotNil(state.profile.session)
    }
}
