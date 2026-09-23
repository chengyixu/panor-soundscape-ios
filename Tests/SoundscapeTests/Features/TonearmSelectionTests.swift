import XCTest
@testable import Soundscape

final class TonearmSelectionTests: XCTestCase {
    func testSmallQueuesHaveNoDuplicatesAndStartInTheMiddle() {
        for count in 1...5 {
            let ids = Array(1...count)
            let selection = TonearmSelection(ids: ids, currentID: 1)
            XCTAssertEqual(selection.selectedID, 1)
            XCTAssertEqual(selection.selectedSlot, 0)
            XCTAssertEqual(Set(selection.slots.values), Set(ids))
            XCTAssertEqual(selection.slots.count, count)
            XCTAssertEqual(selection.slots[0], 1)
        }
    }

    func testBrowsingOnlySelectsOccupiedSlotsAndDoesNotReshuffle() {
        var selection = TonearmSelection(ids: [1, 2, 3], currentID: 1)
        let original = selection.slots
        selection.select(slot: -2)
        XCTAssertNotNil(selection.selectedID)
        XCTAssertEqual(selection.slots, original)
        XCTAssertFalse(selection.advanceEdge(-1))
    }

    func testLongQueueWrapsForeverInBothDirections() {
        var selection = TonearmSelection(ids: Array(1...9), currentID: 4)
        XCTAssertEqual(selection.selectedID, 4)
        selection.select(slot: 2)
        let first = selection.selectedID
        XCTAssertTrue(selection.advanceEdge(1))
        XCTAssertNotEqual(selection.selectedID, first)
        let beforeLap = selection.slots
        for _ in 0..<9 { XCTAssertTrue(selection.advanceEdge(1)) }
        XCTAssertEqual(selection.slots, beforeLap)
        for _ in 0..<9 { XCTAssertTrue(selection.advanceEdge(-1)) }
        XCTAssertEqual(selection.slots, beforeLap)
        XCTAssertEqual(selection.slots.count, 5)
        XCTAssertEqual(Set(selection.slots.values).count, 5)
        XCTAssertTrue(selection.advanceEdge(-1))
    }

    func testEmptyAndDuplicateQueuesAreSafe() {
        let empty = TonearmSelection(ids: [], currentID: nil)
        XCTAssertNil(empty.selectedID)
        XCTAssertTrue(empty.slots.isEmpty)
        let duplicates = TonearmSelection(ids: [1, 1, 2], currentID: 1)
        XCTAssertEqual(duplicates.slots.count, 2)
    }
}
