import Foundation

enum AppShellTab: String, CaseIterable, Hashable {
    case explore
    case map
    case contribute
    case me

    var title: String {
        title(for: LocaleManager.sharedLocale)
    }

    func title(for locale: AppLocale) -> String {
        switch self {
        case .explore: SoundscapeLocale.tabExplore.localized(for: locale)
        case .map: SoundscapeLocale.tabMap.localized(for: locale)
        case .contribute: SoundscapeLocale.tabContribute.localized(for: locale)
        case .me: SoundscapeLocale.tabMe.localized(for: locale)
        }
    }

    var systemImage: String {
        switch self {
        case .explore: "magnifyingglass"
        case .map: "map"
        case .contribute: "record.circle"
        case .me: "person"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .explore: "magnifyingglass"
        case .map: "map.fill"
        case .contribute: "record.circle.fill"
        case .me: "person.fill"
        }
    }
}

enum ExploreSurfaceMode: String, CaseIterable, Hashable {
    case discover
    case rankings

    var title: String {
        title(for: LocaleManager.sharedLocale)
    }

    func title(for locale: AppLocale) -> String {
        switch self {
        case .discover: SoundscapeLocale.tabExploreSubtitle.localized(for: locale)
        case .rankings: SoundscapeLocale.tabRankingsSubtitle.localized(for: locale)
        }
    }
}
