import XCTest
@testable import Soundscape

final class ExploreCardLayoutTests: XCTestCase {
    func testBackendPrimaryKeyDoesNotChangeCardGeometry() {
        let item15 = makeSoundscape(id: 15)
        let item17 = makeSoundscape(id: 17)

        XCTAssertEqual(
            ExploreCardLayout.estimatedHeight(for: item15),
            ExploreCardLayout.estimatedHeight(for: item17)
        )
    }

    private func makeSoundscape(id: Int) -> Soundscape {
        Soundscape(
            id: id,
            ownerID: "2",
            authorName: "wilsonxu",
            title: "同一声景",
            description: "相同内容只能产生相同布局。",
            audioURL: URL(string: "https://www.panor.tech/soundscape/uploads/audio/sample.m4a"),
            coverURL: URL(string: "https://www.panor.tech/soundscape/uploads/covers/sample.png"),
            coverIsAI: true,
            latitude: 22.579,
            longitude: 113.861,
            locationName: "同一地点",
            category: "地方",
            promptText: "",
            personalSocial: 0.5,
            memoryPresent: 0.5,
            durationSeconds: 60,
            isPublic: true,
            playCount: 0,
            fullPlayCount: 0,
            saveCount: 0,
            createdAt: "2026-07-21 00:00:00"
        )
    }
}
