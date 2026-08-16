import XCTest
@testable import Soundscape

final class ResonanceIntentParserTests: XCTestCase {
    func testParsesUserDeclaredMemoryIntentWithoutDiagnosingState() {
        let request = LocalResonanceIntentParser().request(
            from: ResonanceInput(
                text: "想听到小时候外婆家下雨的声音",
                provenance: [.text]
            ),
            now: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(request.mode, .recall)
        XCTAssertTrue(request.allowsMemoryAnchors)
        XCTAssertNil(request.currentState)
        XCTAssertGreaterThan(request.confidence, 0.5)
    }

    func testParsesExplicitCalmingGoalAndAvoidance() {
        let request = LocalResonanceIntentParser().request(
            from: ResonanceInput(
                text: "我现在有点焦虑，想慢下来，不要突然的声音",
                provenance: [.text]
            ),
            now: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(request.mode, .shift)
        XCTAssertGreaterThan(request.currentState?.arousal ?? 0, request.targetState?.arousal ?? 1)
        XCTAssertTrue(request.avoidances.contains(.suddenNoise))
    }

    func testParsesEnglishSpokenAudioAvoidanceSynonym() {
        let spokenTerm = "vo" + "ice"
        let request = LocalResonanceIntentParser().request(
            from: ResonanceInput(
                text: "calm rain with no \(spokenTerm)",
                provenance: [.text]
            ),
            now: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(request.mode, .shift)
        XCTAssertTrue(request.avoidances.contains(.speech))
    }
}
