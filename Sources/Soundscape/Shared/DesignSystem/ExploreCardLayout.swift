import CoreGraphics

enum ExploreCardLayout {
    static let regularCoverHeight: CGFloat = 164
    static let accessibilityCoverHeight: CGFloat = 240

    static func coverHeight(isAccessibilitySize: Bool) -> CGFloat {
        isAccessibilitySize ? accessibilityCoverHeight : regularCoverHeight
    }

    static func estimatedHeight(for soundscape: Soundscape) -> Double {
        let titleHeight = soundscape.displayTitle.count > 12 ? 48.0 : 28.0
        return Double(regularCoverHeight) + titleHeight + 96.0
    }
}
