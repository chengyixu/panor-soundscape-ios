import XCTest
@testable import Soundscape

final class MasonryColumnPlannerTests: XCTestCase {
    func testDistributesEveryItemExactlyOnceAcrossTwoColumns() {
        let items = [
            Item(id: 1, height: 320),
            Item(id: 2, height: 240),
            Item(id: 3, height: 310),
            Item(id: 4, height: 220)
        ]

        let columns = MasonryColumnPlanner.columns(for: items, estimatedHeight: \Item.height)

        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns.flatMap { $0 }.map(\.id).sorted(), [1, 2, 3, 4])
        XCTAssertTrue(columns.allSatisfy { !$0.isEmpty })
    }

    func testPlacesNextItemInCurrentlyShorterColumn() {
        let items = [
            Item(id: 1, height: 400),
            Item(id: 2, height: 200),
            Item(id: 3, height: 150)
        ]

        let columns = MasonryColumnPlanner.columns(for: items, estimatedHeight: \Item.height)

        XCTAssertEqual(columns[0].map(\.id), [1])
        XCTAssertEqual(columns[1].map(\.id), [2, 3])
    }
}

private struct Item {
    let id: Int
    let height: Double
}
