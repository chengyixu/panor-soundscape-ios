import XCTest
@testable import Soundscape

final class DiscoveryMapLayoutTests: XCTestCase {
    func testMapUsesMostOfAvailablePhoneContentHeight() {
        XCTAssertGreaterThanOrEqual(
            DiscoveryMapLayout.mapHeight(availableHeight: 620),
            480
        )
    }

    func testMapHeightRemainsBoundedOnShortScreens() {
        XCTAssertEqual(
            DiscoveryMapLayout.mapHeight(availableHeight: 420),
            360
        )
    }

    func testOverviewRegionContainsAsiaArchiveCoordinates() throws {
        let items = [
            soundscape(id: 1, latitude: 34.6937569, longitude: 135.5014539),
            soundscape(id: 2, latitude: -7.8998373, longitude: 110.0512724),
            soundscape(id: 3, latitude: 29.6580086, longitude: 91.1310328),
        ]

        let region = try XCTUnwrap(DiscoveryMapViewport.overviewRegion(for: items))

        XCTAssertGreaterThan(region.span.latitudeDelta, 42)
        XCTAssertGreaterThan(region.span.longitudeDelta, 44)
        XCTAssertEqual(region.center.latitude, 13.3969598, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, 113.31624335, accuracy: 0.0001)
    }

    func testSingleCoordinateKeepsReadableLocalSpan() throws {
        let region = try XCTUnwrap(DiscoveryMapViewport.overviewRegion(for: [TestFixtures.soundscape]))

        XCTAssertEqual(region.span.latitudeDelta, 0.24, accuracy: 0.0001)
        XCTAssertEqual(region.span.longitudeDelta, 0.24, accuracy: 0.0001)
    }

    private func soundscape(id: Int, latitude: Double, longitude: Double) -> Soundscape {
        Soundscape(
            id: id,
            ownerID: "2",
            authorName: "wilsonxu",
            title: "Map \(id)",
            description: "",
            audioURL: nil,
            coverURL: nil,
            coverIsAI: false,
            latitude: latitude,
            longitude: longitude,
            locationName: "",
            category: "地方",
            promptText: "",
            personalSocial: 0.5,
            memoryPresent: 0.5,
            durationSeconds: 1,
            isPublic: true,
            playCount: 0,
            fullPlayCount: 0,
            saveCount: 0,
            createdAt: ""
        )
    }
}
