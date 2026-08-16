import Foundation
import Observation
import SwiftUI

enum AppLocale: String, CaseIterable, Sendable {
    case zhHans = "zh-Hans"
    case en = "en"
    case zhHant = "zh-Hant"

    var displayName: String {
        switch self {
        case .zhHans: "简体中文"
        case .en: "English"
        case .zhHant: "繁體中文"
        }
    }

    var shortName: String {
        switch self {
        case .zhHans: "中"
        case .en: "EN"
        case .zhHant: "繁"
        }
    }
}

@MainActor
@Observable
final class LocaleManager {
    static let shared = LocaleManager()

    private static let storageKey = "soundscape.app-locale"
    nonisolated(unsafe) private static var _cachedLocale: AppLocale = .zhHans

    var current: AppLocale {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.storageKey)
            Self._cachedLocale = current
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let locale = AppLocale(rawValue: raw) {
            current = locale
            Self._cachedLocale = locale
        } else {
            current = .zhHans
            Self._cachedLocale = .zhHans
        }
    }

    func string(_ key: SoundscapeLocale) -> String {
        key.localized(for: current)
    }

    nonisolated static func localize(_ key: SoundscapeLocale) -> String {
        key.localized(for: _cachedLocale)
    }

    nonisolated static var sharedLocale: AppLocale {
        _cachedLocale
    }
}

extension View {
    func withLocale(_ locale: LocaleManager = .shared) -> some View {
        self.environment(locale)
    }
}
