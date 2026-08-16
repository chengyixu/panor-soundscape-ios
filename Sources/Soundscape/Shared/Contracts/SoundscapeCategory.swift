import Foundation

enum SoundscapeCategory: String, CaseIterable, Sendable {
    case place = "地方"
    case nature = "自然"
    case architecture = "建筑"
    case natureParks = "自然公园"
    case urbanAmbience = "城市氛围"
    case marketsCafes = "市场与咖啡馆"
    case soundscape = "声景"

    static let creationCases: [SoundscapeCategory] = [.place, .nature, .architecture]

    var localizedTitle: String {
        switch self {
        case .place: loc(.createCategoryPlace)
        case .nature: loc(.createCategoryNature)
        case .architecture: loc(.createCategoryArchitecture)
        case .natureParks: loc(.rankingsNatureParks)
        case .urbanAmbience: loc(.rankingsUrbanAmbience)
        case .marketsCafes: loc(.rankingsMarketsCafes)
        case .soundscape: loc(.soundscapeUnit)
        }
    }

    static func localizedTitle(for rawValue: String) -> String {
        SoundscapeCategory(rawValue: rawValue)?.localizedTitle ?? rawValue
    }
}

extension Soundscape {
    var categoryDisplay: String {
        SoundscapeCategory.localizedTitle(for: category)
    }
}

extension RankingLane {
    var categoryDisplay: String {
        SoundscapeCategory.localizedTitle(for: category)
    }
}
