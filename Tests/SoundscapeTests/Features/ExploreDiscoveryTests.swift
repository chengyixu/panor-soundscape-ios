import XCTest
@testable import Soundscape

final class ExploreDiscoveryTests: XCTestCase {
    func testPopularTermsComeOnlyFromLoadedBackendFields() {
        let items = [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]

        let terms = ExploreDiscovery.popularTerms(from: items, limit: 20)
        let allowed = Set(items.flatMap { item in
            [item.categoryDisplay, item.displayTitle, item.authorDisplay]
                + ExploreDiscovery.locationSegments(item.locationName)
        })

        XCTAssertFalse(terms.isEmpty)
        XCTAssertTrue(Set(terms).isSubset(of: allowed))
    }

    func testSearchMatchesRealAuthorAndLocationMetadata() {
        let items = [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]

        XCTAssertEqual(
            ExploreDiscovery.search(items, query: "wilsonxu", scope: .author, durationFilter: nil).map(\.id),
            [TestFixtures.soundscape.id, TestFixtures.soundscapeWithoutCoordinate.id]
        )
        XCTAssertEqual(
            ExploreDiscovery.search(items, query: "盐田", scope: .location, durationFilter: nil).map(\.id),
            [TestFixtures.soundscape.id]
        )
    }

    func testDurationFacetsOnlyExposeRangesPresentInLoadedItems() {
        let values = ExploreDiscovery.facetValues(
            for: .duration,
            items: [TestFixtures.soundscape, TestFixtures.soundscapeWithoutCoordinate]
        )

        XCTAssertEqual(values.map(\.durationFilter), [.underOneMinute, .overFiveMinutes])
    }

    func testFacetValuesNeverInventMissingMetadata() {
        let values = ExploreDiscovery.facetValues(for: .location, items: [TestFixtures.soundscapeWithoutCoordinate])
        XCTAssertTrue(values.isEmpty)
    }
}
