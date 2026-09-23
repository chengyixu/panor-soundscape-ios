import Foundation

/// A stable five-groove viewport. Browsing never changes the audio player.
struct TonearmSelection {
    private var ids: [Int]
    private var windowStart = 0
    private var smallSlots: [Int: Int] = [:]
    private(set) var selectedSlot = 0

    init(ids: [Int], currentID: Int?) {
        var seen = Set<Int>()
        let unique = ids.filter { seen.insert($0).inserted }
        guard !unique.isEmpty else { self.ids = []; return }
        let currentIndex = currentID.flatMap { unique.firstIndex(of: $0) } ?? 0
        if unique.count <= 5 {
            self.ids = unique
            smallSlots[0] = unique[currentIndex]
            let remaining = unique.filter { $0 != unique[currentIndex] }.shuffled()
            for (slot, id) in zip([-2, -1, 1, 2].shuffled(), remaining) {
                smallSlots[slot] = id
            }
        } else {
            // Rotate once so the current recording starts on the middle groove.
            let start = (currentIndex - 2 + unique.count) % unique.count
            self.ids = Array(unique[start...]) + Array(unique[..<start])
        }
    }

    var slots: [Int: Int] {
        if ids.count <= 5 { return smallSlots }
        return Dictionary(uniqueKeysWithValues: (-2...2).map { ($0, ids[(windowStart + $0 + 2) % ids.count]) })
    }

    var selectedID: Int? { slots[selectedSlot] }

    mutating func select(slot: Int) {
        guard let nearest = slots.keys.sorted().min(by: { abs($0 - slot) < abs($1 - slot) }) else { return }
        selectedSlot = nearest
    }

    @discardableResult mutating func advanceEdge(_ direction: Int) -> Bool {
        guard ids.count > 5, direction != 0 else { return false }
        windowStart = (windowStart + (direction > 0 ? 1 : -1) + ids.count) % ids.count
        selectedSlot = direction > 0 ? 2 : -2
        return true
    }
}
