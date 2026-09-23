import XCTest
@testable import Soundscape

final class LibraryFilterLayoutTests: XCTestCase {
    func testMeIncludesFavoritesAsAFirstClassFilter() {
        XCTAssertEqual(LibraryFilter.allCases, [.recordings, .publicItems, .privateItems, .favorites])
    }

    func testFilterColumnsFillTheEntireAvailableWidth() {
        let availableWidth: CGFloat = 358
        let itemWidth = LibraryFilterLayout.itemWidth(availableWidth: availableWidth)

        XCTAssertEqual(
            itemWidth * CGFloat(LibraryFilter.allCases.count)
                + LibraryFilterLayout.spacing * CGFloat(LibraryFilter.allCases.count - 1),
            availableWidth,
            accuracy: 0.001
        )
    }

    func testFilterColumnsRemainEqualOnCompactWidths() {
        XCTAssertEqual(LibraryFilterLayout.itemWidth(availableWidth: 280), 64, accuracy: 0.001)
    }
}
