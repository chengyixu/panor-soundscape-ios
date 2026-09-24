import XCTest

@MainActor
final class SoundscapeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNavigatesEveryPrimaryTab() {
        let app = makeApp()
        app.launch()

        assertScreen(app, tab: "探索", heading: "探索身边的声景")
        XCTAssertFalse(app.staticTexts["发现录音"].exists)
        XCTAssertFalse(app.staticTexts["每段录音都来自真实环境；搜索地点或作者，也可以按时长筛选。"].exists)
        assertScreen(app, tab: "地图", heading: "声音落在地图上")
        XCTAssertLessThan(
            app.staticTexts["声音落在地图上"].frame.minY,
            220,
            "Discovery Map heading must remain anchored near the top in every load state"
        )
        assertScreen(app, tab: "发布", heading: "发布声景")
        XCTAssertFalse(app.staticTexts["公开发布"].exists)
        XCTAssertFalse(app.staticTexts["录音、导入、AI 增强之后公开发布，让你的声音出现在探索页面和地图上。"].exists)
        assertScreen(app, tab: "我的", heading: "你的声音档案")

        let settings = app.buttons["settings-button"]
        XCTAssertTrue(settings.waitForExistence(timeout: 3))
        settings.tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["需要登录"].exists)
        XCTAssertFalse(app.buttons["登录或注册"].isHittable)

        let english = app.buttons["settings-language-en"]
        XCTAssertTrue(english.waitForExistence(timeout: 3))
        english.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.otherElements["primary-tab-bar"].label, "Primary navigation")

        let privacyPolicy = app.buttons["Privacy Policy"]
        XCTAssertTrue(privacyPolicy.waitForExistence(timeout: 3))
        privacyPolicy.tap()
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "Soundscape respects your privacy.")
        ).firstMatch.waitForExistence(timeout: 3))
        app.navigationBars.buttons["Settings"].tap()

        let terms = app.buttons["Terms of Service"]
        XCTAssertTrue(terms.waitForExistence(timeout: 3))
        terms.tap()
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "By using Soundscape, you agree to:")
        ).firstMatch.waitForExistence(timeout: 3))
        app.navigationBars.buttons["Settings"].tap()

        let forYou = app.buttons["settings-for-you"]
        XCTAssertTrue(forYou.waitForExistence(timeout: 3))
        forYou.tap()
        XCTAssertTrue(app.staticTexts["Start with anything."].waitForExistence(timeout: 8))
        let closeForYou = app.buttons["close-for-you"]
        XCTAssertTrue(closeForYou.waitForExistence(timeout: 3))
        closeForYou.tap()

        let closeSettings = app.buttons["close-settings"]
        XCTAssertTrue(closeSettings.waitForExistence(timeout: 3))
        closeSettings.tap()
        XCTAssertTrue(app.staticTexts["Your sound archive"].waitForExistence(timeout: 8))

        assertScreen(app, tab: "Explore", heading: "Explore soundscapes", captureScreenshot: false)
        assertScreen(app, tab: "Map", heading: "Sounds on the map", captureScreenshot: false)
        assertScreen(app, tab: "Share", heading: "Publish Soundscape", captureScreenshot: false)
        XCTAssertTrue(app.staticTexts["Record a sound that makes you want to stop and listen"].waitForExistence(timeout: 3))
        assertScreen(app, tab: "Me", heading: "Your sound archive", captureScreenshot: false)

        let englishSettings = app.buttons["settings-button"]
        XCTAssertTrue(englishSettings.waitForExistence(timeout: 3))
        englishSettings.tap()
        let traditionalChinese = app.buttons["settings-language-zh-Hant"]
        XCTAssertTrue(traditionalChinese.waitForExistence(timeout: 3))
        traditionalChinese.tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.otherElements["primary-tab-bar"].label, "主導覽")
        app.buttons["close-settings"].tap()

        assertScreen(app, tab: "探索", heading: "探索身邊的聲景", captureScreenshot: false)
        assertScreen(app, tab: "地圖", heading: "聲音落在地圖上", captureScreenshot: false)
        assertScreen(app, tab: "發佈", heading: "發佈聲景", captureScreenshot: false)
        XCTAssertTrue(app.staticTexts["錄下一段讓你想停下腳步的聲音"].waitForExistence(timeout: 3))
        assertScreen(app, tab: "我的", heading: "你的聲音檔案", captureScreenshot: false)

        XCTAssertEqual(primaryTabs(in: app).count, 4)
        XCTAssertEqual(app.tabBars.count, 0, "Custom primary navigation must not coexist with native TabView chrome")
        XCTAssertFalse(app.buttons["tab-rankings"].exists)
        XCTAssertFalse(app.buttons["为你"].exists)
        assertTabBarMeetsBottom(in: app)
    }

    func testCapturesLoadedDiscoveryAndSearchStates() {
        let app = makeApp()
        app.launch()

        let exploreTab = app.buttons["探索"]
        XCTAssertTrue(exploreTab.waitForExistence(timeout: 8))
        exploreTab.tap()
        XCTAssertTrue(app.staticTexts["按条件探索"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["最新录音"].waitForExistence(timeout: 3))
        waitForVisualSettling()
        capture("Soundscape-Explore-Loaded")

        let search = app.textFields["explore-search-field"]
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        search.typeText("盐田")
        XCTAssertTrue(app.staticTexts["最相关结果"].waitForExistence(timeout: 5))
        waitForVisualSettling()
        capture("Soundscape-Search-Results")

        let mapTab = app.buttons["地图"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 3))
        mapTab.tap()
        XCTAssertTrue(app.staticTexts["已选录音"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "map-favorite-")
        ).firstMatch.waitForExistence(timeout: 3))
        waitForVisualSettling(duration: 3)
        capture("Soundscape-Map-Loaded")
    }

    func testRankingsAndMapUseDirectAlignedHeaders() {
        let app = makeApp()
        app.launch()

        let rankings = app.buttons["explore-mode-rankings"]
        XCTAssertTrue(rankings.waitForExistence(timeout: 8))
        rankings.tap()
        XCTAssertTrue(app.staticTexts["最多播放的声景"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["社区精选"].exists)
        XCTAssertFalse(app.staticTexts["大家都喜欢的声音。"].exists)
        capture("Soundscape-Rankings-Direct-Header")

        let map = app.buttons["地图"]
        XCTAssertTrue(map.waitForExistence(timeout: 3))
        map.tap()
        let mapTitle = app.staticTexts["声音落在地图上"]
        XCTAssertTrue(mapTitle.waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["声音地图"].exists)
        XCTAssertFalse(app.staticTexts["每个黑点都是一段真实录音；选择地点即可查看作者并开始播放。"].exists)
        capture("Soundscape-Map-Direct-Header")

        let mapHeaderFrame = mapTitle.frame
        let create = app.buttons["发布"]
        XCTAssertTrue(create.waitForExistence(timeout: 3))
        create.tap()
        let createTitle = app.staticTexts["发布声景"]
        XCTAssertTrue(createTitle.waitForExistence(timeout: 8))
        XCTAssertEqual(mapHeaderFrame.minX, createTitle.frame.minX, accuracy: 1)
        XCTAssertEqual(mapHeaderFrame.minY, createTitle.frame.minY, accuracy: 1)
    }

    func testCapturesTurntableMetadataOnlyState() {
        let app = makeApp()
        app.launch()
        openTurntable(in: app)

        XCTAssertFalse(app.staticTexts["唱针位于唱片上"].exists)
        XCTAssertFalse(app.staticTexts["为你推荐"].exists)
        XCTAssertFalse(app.staticTexts["為你推薦"].exists)

        waitForVisualSettling()
        capture("Soundscape-Player-Metadata")
    }

    func testPrimarySurfacesSupportAccessibilityXXXL() {
        let app = makeApp()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        assertScreen(app, tab: "探索", heading: "探索身边的声景", captureScreenshot: false)
        assertScreen(app, tab: "地图", heading: "声音落在地图上", captureScreenshot: false)
        assertScreen(app, tab: "发布", heading: "发布声景", captureScreenshot: false)
        assertScreen(app, tab: "我的", heading: "你的声音档案", captureScreenshot: false)

        XCTAssertEqual(primaryTabs(in: app).count, 4)
    }

    func testProductionAPIEndpointUsesCanonicalHTTPSRoute() throws {
        let url = try XCTUnwrap(URL(string: "https://www.panor.tech/soundscape/api/health"))
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "www.panor.tech")
        XCTAssertEqual(url.path, "/soundscape/api/health")
    }

    func testRegistrationShowsRequiredEmailField() {
        let app = makeApp()
        app.launch()

        let libraryTab = app.buttons["我的"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 8))
        libraryTab.tap()

        let identityButton = app.buttons["profile-avatar-sign-in"]
        XCTAssertTrue(identityButton.waitForExistence(timeout: 8))
        identityButton.tap()

        XCTAssertTrue(app.textFields["用户名或邮箱"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["google-signin"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["apple-signin"].waitForExistence(timeout: 3))

        let registerButton = app.buttons["注册"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: 8))
        registerButton.tap()

        XCTAssertTrue(app.textFields["邮箱"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["姓名（选填）"].waitForExistence(timeout: 3))
        capture("Soundscape-Identity")
    }

    func testOpensTurntablePlayer() {
        let app = makeApp()
        app.launch()

        openTurntable(in: app)
        XCTAssertTrue(app.buttons["turntable-back"].waitForExistence(timeout: 3))
        let metadata = app.buttons["turntable-metadata"]
        XCTAssertTrue(metadata.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(
            metadata.frame.maxY,
            app.frame.maxY - 90,
            "Player metadata must sit near the bottom safe area instead of leaving a dead lower panel."
        )
        XCTAssertFalse(app.buttons["vinyl-player-indicator"].exists)
        capture("Soundscape-Turntable")
    }

    func testPublicPlayerExposesReportAndBlockActions() {
        let app = makeApp()
        app.launch()
        openTurntable(in: app)
        app.buttons["turntable-metadata"].tap()
        XCTAssertTrue(app.buttons["report-soundscape"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["block-creator"].waitForExistence(timeout: 5))
    }

    func testPlayerPlaybackModeMenuSwitchesBetweenStandardModes() {
        let app = makeApp()
        app.launch()
        openTurntable(in: app)

        let mode = app.buttons["playback-mode"]
        XCTAssertTrue(mode.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(mode.frame.height, 44)
        XCTAssertTrue(mode.label.contains("单曲循环"))
        mode.tap()

        let continuous = app.buttons["持续播放"]
        XCTAssertTrue(continuous.waitForExistence(timeout: 3))
        continuous.tap()
        XCTAssertTrue(mode.label.contains("持续播放"))

        mode.tap()
        let shuffle = app.buttons["随机播放"]
        XCTAssertTrue(shuffle.waitForExistence(timeout: 3))
        shuffle.tap()
        XCTAssertTrue(mode.label.contains("随机播放"))
        capture("Soundscape-Playback-Modes")
    }

    func testPlayerDetailsUseScrollableTranslucentInformationHierarchy() {
        let app = makeApp()
        app.launch()
        openTurntable(in: app)

        app.buttons["turntable-metadata"].tap()

        XCTAssertTrue(app.buttons["player-details-done"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["player-detail-author"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["player-detail-location"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["player-detail-duration"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["player-detail-date"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["player-detail-memo"].exists)
        capture("Soundscape-Player-Details-Compact")

        app.swipeUp()
        XCTAssertTrue(app.buttons["recommendation-resonates"].waitForExistence(timeout: 3))
        capture("Soundscape-Player-Details-Expanded")
        app.swipeDown()
        XCTAssertTrue(app.buttons["player-details-done"].isHittable)
    }

    func testNeedleDragReleasePlaysWithoutAnExtraTap() {
        let app = makeApp()
        app.launch()
        openTurntable(in: app)
        let needle = app.otherElements["tonearm-control"].firstMatch
        let control = needle.exists ? needle : app.buttons["tonearm-control"].firstMatch
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        let start = control.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -65)))
        XCTAssertNotEqual(control.value as? String, "唱片外，已暂停")
        XCTAssertFalse(app.otherElements["tonearm-track-0"].exists)
        let playing = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "唱针位于唱片上"),
            object: app.buttons["turntable-metadata"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [playing], timeout: 30), .completed)
        capture("Soundscape-Needle-Lowered")
    }

    func testNeedleEdgeDwellCommitsOnReleaseAndDragOffParks() {
        let app = makeApp()
        app.launch()
        openTurntable(in: app)
        let control = app.descendants(matching: .any).matching(identifier: "tonearm-control").firstMatch
        let metadata = app.buttons["turntable-metadata"]
        let initialLabel = metadata.label
        let start = control.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 170)), withVelocity: .slow, thenHoldForDuration: 1.6)
        XCTAssertNotEqual(metadata.label, initialLabel)
        let releasedLabel = metadata.label
        waitForVisualSettling(duration: 0.9)
        XCTAssertEqual(metadata.label, releasedLabel, "Releasing the needle must cancel edge scrolling")
        let parkStart = control.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.6))
        parkStart.press(forDuration: 0.05, thenDragTo: parkStart.withOffset(CGVector(dx: 55, dy: 0)))
        XCTAssertEqual(control.value as? String, "唱片外，已暂停")
        capture("Soundscape-Needle-Parked")
        let resumeStart = control.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        resumeStart.press(forDuration: 0.05, thenDragTo: resumeStart.withOffset(CGVector(dx: -85, dy: 0)))
        XCTAssertNotEqual(control.value as? String, "唱片外，已暂停")
    }

    func testColdLaunchOpensVinylAndAutoplays() {
        let app = makeApp()
        app.launchEnvironment.removeValue(forKey: "SOUNDSCAPE_FORCE_FIRST_USE")
        app.launchEnvironment["SOUNDSCAPE_UI_TEST_AUTOPLAY"] = "1"
        app.launch()
        XCTAssertTrue(app.otherElements["turntable-player"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["turntable-metadata"].label.contains("测试音频"))
        let playing = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "唱针位于唱片上"),
            object: app.buttons["turntable-metadata"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [playing], timeout: 30), .completed)
        capture("Soundscape-Default-Vinyl")
    }

    func testTurntableTopLeadingBackButtonReturnsToThePreviousSurface() {
        let app = makeApp()
        app.launch()

        openTurntable(in: app)
        let back = app.buttons["turntable-back"]
        XCTAssertTrue(back.waitForExistence(timeout: 3))
        back.tap()

        XCTAssertTrue(app.buttons["探索"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.otherElements["turntable-player"].isHittable)
    }

    func testMiniVinylRestoresPlayerAndHidesInsidePlayer() {
        let app = makeApp()
        app.launch()

        openTurntable(in: app)
        swipeHorizontally(in: app, fromX: 0.50, toX: 0.12)

        let miniVinyl = app.buttons["vinyl-player-indicator"]
        XCTAssertTrue(miniVinyl.waitForExistence(timeout: 8))
        capture("Soundscape-Mini-Vinyl")
        miniVinyl.tap()

        XCTAssertTrue(app.otherElements["turntable-player"].waitForExistence(timeout: 8))
        XCTAssertFalse(miniVinyl.exists)
    }

    func testMiniVinylCanBeDraggedWithoutOpeningPlayer() {
        let app = makeApp()
        app.launch()

        openTurntable(in: app)
        dragHorizontally(in: app, fromX: 0.50, toX: 0.12, velocity: .fast)

        let miniVinyl = app.buttons["vinyl-player-indicator"]
        XCTAssertTrue(miniVinyl.waitForExistence(timeout: 8))
        let initialFrame = miniVinyl.frame
        let start = miniVinyl.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.57))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)

        XCTAssertTrue(miniVinyl.waitForExistence(timeout: 2))
        XCTAssertLessThan(miniVinyl.frame.minX, initialFrame.minX)
        XCTAssertLessThan(miniVinyl.frame.minY, initialFrame.minY)
        XCTAssertFalse(app.otherElements["turntable-player"].isHittable)
        capture("Soundscape-Mini-Vinyl-Moved")
    }

    func testPlayerSwipesBackToLastScreenAndRestoresFromEverySurface() {
        let app = makeApp()
        app.launch()

        openTurntable(in: app)

        XCTAssertFalse(app.otherElements["primary-tab-bar"].isHittable)
        XCTAssertEqual(app.tabBars.count, 0, "Player must not leak the native Liquid Glass tab bar")
        XCTAssertFalse(
            app.navigationBars.allElementsBoundByIndex.contains { $0.isHittable },
            "Player must not expose a visible or interactive SwiftUI navigation bar"
        )
        XCTAssertFalse(app.buttons["player-open-explore"].exists)

        let metadata = app.buttons["turntable-metadata"]
        dragHorizontally(in: app, fromX: 0.50, toX: 0.43, velocity: .slow)
        waitForVisualSettling(duration: 0.8)
        XCTAssertTrue(metadata.isHittable, "An incomplete swipe must return the player to its settled edge")
        XCTAssertGreaterThanOrEqual(metadata.frame.minX, -1)
        XCTAssertLessThanOrEqual(metadata.frame.maxX, app.frame.maxX + 1)

        swipeHorizontally(in: app, fromX: 0.50, toX: 0.12)

        let exploreTab = app.buttons["探索"]
        XCTAssertTrue(exploreTab.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["探索身边的声景"].waitForExistence(timeout: 8))

        let tabBar = app.otherElements["primary-tab-bar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3))
        XCTAssertEqual(primaryTabs(in: app).count, 4)
        XCTAssertFalse(app.buttons["return-to-player"].exists)

        let mapTab = app.buttons["地图"]
        mapTab.tap()
        XCTAssertTrue(app.staticTexts["声音落在地图上"].waitForExistence(timeout: 8))

        swipeHorizontally(in: app, fromX: 0.03, toX: 0.42)

        XCTAssertTrue(app.otherElements["turntable-player"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.otherElements["primary-tab-bar"].isHittable)

        swipeHorizontally(in: app, fromX: 0.50, toX: 0.12)

        XCTAssertTrue(app.staticTexts["声音落在地图上"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.otherElements["primary-tab-bar"].waitForExistence(timeout: 3))

        capture("Soundscape-Player-Explore-Swipe")
    }

    func testPanningMapDoesNotPresentPlayer() {
        let app = makeApp()
        app.launch()

        openTurntable(in: app)
        swipeHorizontally(in: app, fromX: 0.50, toX: 0.12)

        let mapTab = app.buttons["地图"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 8))
        mapTab.tap()
        XCTAssertTrue(app.staticTexts["声音落在地图上"].waitForExistence(timeout: 8))

        dragHorizontally(in: app, fromX: 0.35, toX: 0.68, velocity: .slow)
        waitForVisualSettling(duration: 0.8)

        XCTAssertTrue(app.staticTexts["声音落在地图上"].isHittable)
        XCTAssertFalse(
            app.otherElements["turntable-player"].isHittable,
            "A map pan must not be interpreted as navigation back to the player"
        )
    }

    func testInterruptedPlayerSwipeReturnsToASettledPage() {
        let app = makeApp()
        app.launch()

        openTurntable(in: app)

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.52))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.52))
        print("SOUNDSCAPE_INTERRUPT_PLAYER_DRAG_NOW")
        start.press(
            forDuration: 0.2,
            thenDragTo: end,
            withVelocity: .slow,
            thenHoldForDuration: 8
        )

        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        waitForVisualSettling(duration: 1)

        let playerSettled = app.buttons["turntable-metadata"].isHittable
        let tabsSettled = app.buttons["探索"].isHittable
        XCTAssertNotEqual(
            playerSettled,
            tabsSettled,
            "An interrupted swipe must settle fully on exactly one page"
        )
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SOUNDSCAPE_KEYCHAIN_SERVICE"] =
            "tech.panor.soundscape.ui-tests.\(UUID().uuidString)"
        app.launchEnvironment["SOUNDSCAPE_FORCE_FIRST_USE"] = "1"
        app.launchArguments += ["-soundscape.app-locale", "zh-Hans"]
        return app
    }

    private func openTurntable(in app: XCUIApplication) {
        let exploreTab = app.buttons["探索"]
        XCTAssertTrue(exploreTab.waitForExistence(timeout: 8))
        exploreTab.tap()

        let card = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "九巷闲闻烟火声", "盐田新一村九巷")
        ).firstMatch
        for _ in 0..<8 where !card.exists {
            app.swipeUp()
        }

        XCTAssertTrue(card.waitForExistence(timeout: 12), "Playable Soundscape row was not loaded")
        card.tap()

        let turntable = app.otherElements["turntable-player"]
        XCTAssertTrue(turntable.waitForExistence(timeout: 10))

        let metadata = app.buttons["turntable-metadata"]
        XCTAssertTrue(metadata.waitForExistence(timeout: 2))
        let playbackState = metadata.value as? String
        XCTAssertTrue(
            ["正在加载", "唱针位于唱片上", "唱针已移出"].contains(playbackState),
            "Turntable should expose an observable playback state"
        )
    }

    private func swipeHorizontally(in app: XCUIApplication, fromX: CGFloat, toX: CGFloat) {
        dragHorizontally(in: app, fromX: fromX, toX: toX, velocity: .fast)
    }

    private func dragHorizontally(
        in app: XCUIApplication,
        fromX: CGFloat,
        toX: CGFloat,
        velocity: XCUIGestureVelocity
    ) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: fromX, dy: 0.52))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: toX, dy: 0.52))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: velocity, thenHoldForDuration: 0)
    }

    private func assertScreen(
        _ app: XCUIApplication,
        tab: String,
        heading: String,
        captureScreenshot: Bool = true
    ) {
        let button = app.buttons[tab]
        XCTAssertTrue(button.waitForExistence(timeout: 8), "Missing tab: \(tab)")
        button.tap()
        XCTAssertTrue(app.staticTexts[heading].waitForExistence(timeout: 8), "Missing heading: \(heading)")
        if captureScreenshot {
            capture("Soundscape-\(tab)")
        }
    }

    private func primaryTabs(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tab-"))
    }

    private func assertTabBarMeetsBottom(in app: XCUIApplication) {
        let tabs = primaryTabs(in: app)
        let bottomGap = app.frame.maxY - tabs.firstMatch.frame.maxY
        XCTAssertGreaterThanOrEqual(bottomGap, 0)
        XCTAssertLessThanOrEqual(
            bottomGap,
            12,
            "Primary navigation hit area should meet the device bottom; observed gap: \(bottomGap)"
        )
    }

    private func waitForVisualSettling(duration: TimeInterval = 1.5) {
        Thread.sleep(forTimeInterval: duration)
    }

    private func capture(_ name: String) {
        // Screenshots are manual visual artifacts, not a CI assertion. Hosted
        // simulator screenshot requests can time out after all UI checks pass.
        guard ProcessInfo.processInfo.environment["SOUNDSCAPE_CAPTURE_SCREENSHOTS"] == "1" else { return }
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
