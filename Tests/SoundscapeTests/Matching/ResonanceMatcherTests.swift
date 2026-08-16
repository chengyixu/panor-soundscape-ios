import XCTest
@testable import Soundscape

final class ResonanceMatcherTests: XCTestCase {
    func testUserArousalOutranksMatchingCreatorWords() throws {
        let creatorMatch = makeSoundscape(id: 1, author: "creator-a", title: "Busy station", prompt: "A calm place to slow down")
        let userMatch = makeSoundscape(id: 2, author: "creator-b", title: "Forest rain", prompt: "Field recording")
        let provider = StubSoundscapeFeatureProvider(features: [
            1: .init(
                creatorIntent: .calm,
                collectivePerception: .highEnergyUrban,
                creatorIntentText: creatorMatch.promptText,
                collectiveText: creatorMatch.title,
                editorialQuality: 0.8,
                novelty: 0.4,
                suddenNoiseRisk: 0.8,
                loopStability: 0.3
            ),
            2: .init(
                creatorIntent: .neutral,
                collectivePerception: .calmNature,
                creatorIntentText: userMatch.promptText,
                collectiveText: userMatch.title,
                editorialQuality: 0.75,
                novelty: 0.5,
                suddenNoiseRisk: 0.05,
                loopStability: 0.95
            )
        ])
        let request = ResonanceRequest(
            mode: .shift,
            queryText: "I need a calm place to slow down",
            currentState: AffectState(pleasantness: 0.3, arousal: 0.9),
            targetState: AffectState(pleasantness: 0.75, arousal: 0.2),
            confidence: 0.95
        )

        let ranked = ResonanceMatcher(featureProvider: provider).rank(
            [creatorMatch, userMatch],
            request: request,
            profile: .empty,
            limit: 2
        )

        XCTAssertEqual(ranked.first?.soundscape.id, 2)
        XCTAssertGreaterThan(
            ranked[0].score.userArousal * 0.6,
            ranked[0].score.creatorIntent * 0.1
        )
    }

    func testSessionPreferenceDominatesConflictingLongTermPreference() throws {
        let nature = makeSoundscape(id: 1, author: "nature", title: "Forest")
        let urban = makeSoundscape(id: 2, author: "city", title: "Night train")
        let provider = StubSoundscapeFeatureProvider(features: [
            1: .init(collectivePerception: .calmNature),
            2: .init(collectivePerception: .calmUrban)
        ])
        let profile = ResonanceProfile(
            longTerm: .calmNature,
            session: .calmUrban,
            longTermObservations: 20,
            sessionObservations: 3
        )
        let request = ResonanceRequest(mode: .mirror, confidence: 0.25)

        let ranked = ResonanceMatcher(featureProvider: provider).rank(
            [nature, urban],
            request: request,
            profile: profile,
            limit: 2
        )

        XCTAssertEqual(ranked.first?.soundscape.id, 2)
        XCTAssertGreaterThan(ranked[0].score.sessionArousal, ranked[0].score.longTermArousal)
    }

    func testHardFiltersRejectPrivateUnplayableBlockedAndUnsafeCandidates() throws {
        let privateItem = makeSoundscape(id: 1, isPublic: false)
        let unplayable = makeSoundscape(id: 2, audioURL: nil)
        let blocked = makeSoundscape(id: 3)
        let unsafe = makeSoundscape(id: 4)
        let eligible = makeSoundscape(id: 5)
        let provider = StubSoundscapeFeatureProvider(features: [
            1: .init(),
            2: .init(),
            3: .init(),
            4: .init(suddenNoiseRisk: 0.95),
            5: .init(suddenNoiseRisk: 0.05)
        ])
        let profile = ResonanceProfile(blockedSoundscapeIDs: [3])
        let request = ResonanceRequest(mode: .focus, avoidances: [.suddenNoise], confidence: 0.8)

        let ranked = ResonanceMatcher(featureProvider: provider).rank(
            [privateItem, unplayable, blocked, unsafe, eligible],
            request: request,
            profile: profile,
            limit: 10
        )

        XCTAssertEqual(ranked.map(\.soundscape.id), [5])
    }

    func testDiversityRerankingAvoidsRepeatedCreatorAndPlace() throws {
        let first = makeSoundscape(id: 1, author: "same", location: "same-place", category: "nature")
        let duplicate = makeSoundscape(id: 2, author: "same", location: "same-place", category: "nature")
        let alternative = makeSoundscape(id: 3, author: "different", location: "far-place", category: "city")
        let provider = StubSoundscapeFeatureProvider(features: [
            1: .init(collectivePerception: .calmNature, editorialQuality: 0.95),
            2: .init(collectivePerception: .calmNature, editorialQuality: 0.94),
            3: .init(collectivePerception: .calmUrban, editorialQuality: 0.86)
        ])

        let ranked = ResonanceMatcher(featureProvider: provider).rank(
            [first, duplicate, alternative],
            request: ResonanceRequest(mode: .focus, confidence: 0.8),
            profile: .empty,
            limit: 3
        )

        XCTAssertEqual(ranked[0].soundscape.id, 1)
        XCTAssertEqual(ranked[1].soundscape.id, 3)
        XCTAssertEqual(ranked.map(\.role), [.closest, .alternate, .surprise])
    }

    private func makeSoundscape(
        id: Int,
        author: String = "creator",
        title: String = "Sound",
        prompt: String = "",
        location: String = "place",
        category: String = "soundscape",
        isPublic: Bool = true,
        audioURL: URL? = URL(string: "https://example.com/audio.m4a")
    ) -> Soundscape {
        Soundscape(
            id: id,
            ownerID: author,
            authorName: author,
            title: title,
            description: "",
            audioURL: audioURL,
            coverURL: nil,
            coverIsAI: false,
            latitude: 22.5,
            longitude: 114,
            locationName: location,
            category: category,
            promptText: prompt,
            personalSocial: 0.5,
            memoryPresent: 0.5,
            durationSeconds: 120,
            isPublic: isPublic,
            playCount: 0,
            fullPlayCount: 0,
            saveCount: 0,
            createdAt: "2026-08-14 00:00:00"
        )
    }
}

private struct StubSoundscapeFeatureProvider: SoundscapeFeatureProviding {
    let features: [Int: SoundscapeMatchingFeatures]

    func features(for soundscape: Soundscape) -> SoundscapeMatchingFeatures {
        features[soundscape.id] ?? SoundscapeMatchingFeatures()
    }
}
