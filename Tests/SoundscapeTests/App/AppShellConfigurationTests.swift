import XCTest
@testable import Soundscape

final class AppShellConfigurationTests: XCTestCase {
    func testPrimaryTabsMatchAcceptedFourSurfaceOrder() {
        XCTAssertEqual(
            AppShellTab.allCases,
            [.explore, .map, .contribute, .me]
        )
        XCTAssertEqual(AppShellTab.allCases.count, 4)
        XCTAssertFalse(AppShellTab.allCases.map(\.title).contains("为你"))
    }

    func testRankingsLivesInsideExplore() {
        XCTAssertEqual(ExploreSurfaceMode.allCases, [.discover, .rankings])
        XCTAssertFalse(AppShellTab.allCases.map(\.title).contains("榜单"))
    }
}
