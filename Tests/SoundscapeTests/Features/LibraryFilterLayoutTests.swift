import XCTest
@testable import Soundscape

final class LibraryFilterLayoutTests: XCTestCase {
    func testMeIncludesFavoritesAsAFirstClassFilter() {
        XCTAssertEqual(LibraryFilter.allCases, [.recordings, .publicItems, .privateItems, .favorites, .review])
    }

    func testModeratorGetsFifthMeFilterAndListenersKeepFour() {
        XCTAssertEqual(LibraryFilter.visibleFilters(canModerate: false), [.recordings, .publicItems, .privateItems, .favorites])
        XCTAssertEqual(LibraryFilter.visibleFilters(canModerate: true), [.recordings, .publicItems, .privateItems, .favorites, .review])
    }

    func testReviewColumnsCanScrollRatherThanTruncatingOnCompactPhones() {
        let availableWidth: CGFloat = 358
        let itemWidth = LibraryFilterLayout.itemWidth(availableWidth: availableWidth)
        XCTAssertGreaterThan(
            itemWidth * CGFloat(LibraryFilter.allCases.count)
                + LibraryFilterLayout.spacing * CGFloat(LibraryFilter.allCases.count - 1),
            availableWidth
        )
    }

    func testFilterColumnsRemainEqualOnCompactWidths() {
        XCTAssertEqual(LibraryFilterLayout.itemWidth(availableWidth: 280, itemCount: 4), 76, accuracy: 0.001)
        XCTAssertEqual(LibraryFilterLayout.itemWidth(availableWidth: 280, itemCount: 5), 76, accuracy: 0.001)
    }
}
