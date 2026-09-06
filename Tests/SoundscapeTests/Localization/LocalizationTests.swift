import Foundation
import XCTest
@testable import Soundscape

@MainActor
final class LocalizationTests: XCTestCase {
    func testEveryLocaleHasAValueForEveryKey() {
        for locale in AppLocale.allCases {
            for key in SoundscapeLocale.allCases {
                XCTAssertFalse(
                    key.localized(for: locale).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Missing \(locale.rawValue) localization for \(key)"
                )
            }
        }
    }

    func testEnglishCatalogContainsNoHanCharacters() {
        for key in SoundscapeLocale.allCases {
            let value = key.localized(for: .en)
            XCTAssertFalse(
                containsHanCharacters(value),
                "English localization for \(key) contains Han characters: \(value)"
            )
        }
    }

    func testPlayerMetadataDoesNotExposeRecommendationSourceAndServerErrorsFollowSelectedLocale() {
        let originalLocale = LocaleManager.shared.current
        defer { LocaleManager.shared.current = originalLocale }

        LocaleManager.shared.current = .en
        XCTAssertEqual(
            AudioPlayerController.Source.madeForYou.line(for: TestFixtures.soundscape),
            "wilsonxu · Bao'an District · 盐田新一村九巷"
        )
        XCTAssertEqual(
            AppError.server(status: 503, code: "rankings_unavailable", message: "稍后再试").userMessage,
            SoundscapeLocale.errorServerFailed.localized(for: .en)
        )

        LocaleManager.shared.current = .zhHans
        XCTAssertEqual(
            AudioPlayerController.Source.madeForYou.line(for: TestFixtures.soundscape),
            "wilsonxu · Bao'an District · 盐田新一村九巷"
        )

        LocaleManager.shared.current = .zhHant
        XCTAssertEqual(
            AudioPlayerController.Source.madeForYou.line(for: TestFixtures.soundscape),
            "wilsonxu · Bao'an District · 盐田新一村九巷"
        )
    }

    private func containsHanCharacters(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF,
                 0x4E00...0x9FFF,
                 0xF900...0xFAFF,
                 0x20000...0x2FA1F,
                 0x30000...0x323AF:
                true
            default:
                false
            }
        }
    }
}
