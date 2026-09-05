import XCTest
@testable import Soundscape

@MainActor
final class TurntablePlayerTests: XCTestCase {
    func testOpeningTurntableStartsAudioAndPublishesPresentation() async {
        let originalLocale = LocaleManager.shared.current
        LocaleManager.shared.current = .en
        defer { LocaleManager.shared.current = originalLocale }

        let repository = StubSoundscapeRepository()
        let engine = StubAudioPlaybackEngine()
        let session = StubPlaybackAudioSession()
        let player = AudioPlayerController(repository: repository, engine: engine, audioSession: session)

        await player.openPlayer(TestFixtures.soundscape, source: .madeForYou)

        XCTAssertEqual(player.presentedSoundscape, TestFixtures.soundscape)
        XCTAssertEqual(player.current, TestFixtures.soundscape)
        XCTAssertEqual(player.sourceLine, "wilsonxu · Made for you · Bao'an District · 盐田新一村九巷")
        XCTAssertTrue(player.isBuffering)
        XCTAssertFalse(player.isPlaying)

        engine.startPlaying()

        XCTAssertTrue(player.isPlaying)
    }

    func testVerticalGestureBrowsesAndHorizontalGestureParks() {
        XCTAssertEqual(TurntableInteraction.mode(for: CGSize(width: 2, height: -18)), .browse)
        XCTAssertEqual(TurntableInteraction.mode(for: CGSize(width: 20, height: 2)), .park)
        XCTAssertNil(TurntableInteraction.mode(for: CGSize(width: 3, height: 3)))
    }

    func testBrowseDetentsAndParkBoundaryAreStable() {
        XCTAssertEqual(TurntableInteraction.detentOffset(for: CGSize(width: 0, height: -120)), 2)
        XCTAssertGreaterThan(
            TurntableInteraction.parkProgress(for: CGSize(width: 60, height: 0), startsParked: false),
            0.5
        )
    }

    func testTrackPickerRowsFollowAConcaveRecordGroove() {
        let center = CGPoint(x: 120, y: 340)
        let points = (-2...2).map {
            TurntableTrackArcLayout.position(
                rowOffset: $0,
                recordCenter: center,
                recordDiameter: 500
            )
        }

        XCTAssertLessThan(points[0].x, points[1].x)
        XCTAssertLessThan(points[1].x, points[2].x)
        XCTAssertGreaterThan(points[3].x, points[4].x)
        XCTAssertEqual(points[0].x, points[4].x, accuracy: 0.5)
        XCTAssertEqual(points[1].x, points[3].x, accuracy: 0.5)
        XCTAssertEqual(points[1].y - points[0].y, points[2].y - points[1].y, accuracy: 0.5)
    }

    func testTonearmHeadshellOverlapsTheArmAndStylusStaysOnTheRecord() {
        let size = CGSize(width: 390, height: 844)
        let recordDiameter: CGFloat = 498
        let recordTop: CGFloat = 101
        let geometry = TonearmAssemblyLayout.geometry(
            in: size,
            recordDiameter: recordDiameter,
            recordTop: recordTop,
            parkProgress: 0,
            browseOffset: 0
        )
        let recordCenter = CGPoint(x: recordDiameter * 0.26, y: recordTop + recordDiameter / 2)

        XCTAssertLessThan(
            hypot(geometry.headshellStart.x - geometry.headAnchor.x, geometry.headshellStart.y - geometry.headAnchor.y),
            geometry.headLength
        )
        XCTAssertLessThan(
            hypot(geometry.stylusTip.x - recordCenter.x, geometry.stylusTip.y - recordCenter.y),
            recordDiameter / 2
        )
    }

    func testTonearmBrowsingMovesTheStylusAlongThePivotArcAndKeepsTheNeedleTangent() {
        let size = CGSize(width: 390, height: 844)
        let recordDiameter: CGFloat = 498
        let recordTop: CGFloat = 101
        let resting = TonearmAssemblyLayout.geometry(
            in: size,
            recordDiameter: recordDiameter,
            recordTop: recordTop,
            parkProgress: 0,
            browseOffset: 0
        )
        let browsed = TonearmAssemblyLayout.geometry(
            in: size,
            recordDiameter: recordDiameter,
            recordTop: recordTop,
            parkProgress: 0,
            browseOffset: 2
        )

        let restingRadius = hypot(resting.headAnchor.x - resting.pivot.x, resting.headAnchor.y - resting.pivot.y)
        let browsedRadius = hypot(browsed.headAnchor.x - browsed.pivot.x, browsed.headAnchor.y - browsed.pivot.y)
        let radialAngle = atan2(browsed.headAnchor.y - browsed.pivot.y, browsed.headAnchor.x - browsed.pivot.x)

        XCTAssertLessThan(browsed.headAnchor.y, resting.headAnchor.y)
        XCTAssertLessThan(browsed.headAnchor.x, resting.headAnchor.x, "Browsing must follow the pivot arc instead of a vertical line")
        XCTAssertEqual(browsedRadius, restingRadius, accuracy: 0.01)
        XCTAssertEqual(browsed.headAngle, radialAngle + (.pi / 2), accuracy: 0.0001)
    }

    func testPlayerAndExploreSwipesAreDirectionalAndAvoidTheTonearm() {
        XCTAssertTrue(TurntableNavigationGesture.shouldDismissPlayer(
            translation: CGSize(width: -100, height: 8),
            startX: 195,
            width: 390
        ))
        XCTAssertFalse(TurntableNavigationGesture.shouldDismissPlayer(
            translation: CGSize(width: -100, height: 8),
            startX: 330,
            width: 390
        ))
        XCTAssertFalse(TurntableNavigationGesture.shouldDismissPlayer(
            translation: CGSize(width: 40, height: 110),
            startX: 70,
            width: 390
        ))
        XCTAssertTrue(TurntableNavigationGesture.shouldPresentPlayer(
            translation: CGSize(width: 100, height: 8),
            startX: 195,
            width: 390
        ))
        XCTAssertFalse(TurntableNavigationGesture.shouldPresentPlayer(
            translation: CGSize(width: -100, height: 8),
            startX: 195,
            width: 390
        ))
        XCTAssertFalse(TurntableNavigationGesture.shouldPresentPlayer(
            translation: CGSize(width: 100, height: 8),
            startX: 195,
            width: 390,
            requiresLeadingEdge: true
        ))
        XCTAssertTrue(TurntableNavigationGesture.shouldPresentPlayer(
            translation: CGSize(width: 100, height: 8),
            startX: 20,
            width: 390,
            requiresLeadingEdge: true
        ))
    }

    func testAutomaticRecommendationNeverOverridesUserNavigationOrPlayback() {
        XCTAssertTrue(AutomaticPlayerLaunchPolicy.shouldPresentRecommendation(
            hasNavigatedSinceLaunch: false,
            hasCurrentSoundscape: false,
            hasPresentedSoundscape: false
        ))
        XCTAssertFalse(AutomaticPlayerLaunchPolicy.shouldPresentRecommendation(
            hasNavigatedSinceLaunch: true,
            hasCurrentSoundscape: false,
            hasPresentedSoundscape: false
        ))
        XCTAssertFalse(AutomaticPlayerLaunchPolicy.shouldPresentRecommendation(
            hasNavigatedSinceLaunch: false,
            hasCurrentSoundscape: true,
            hasPresentedSoundscape: true
        ))
    }

    func testFloatingVinylDefaultPositionSitsAboveTheTabBar() {
        let center = VinylIndicatorLayout.baseCenter(
            in: CGSize(width: 390, height: 844),
            safeAreaBottom: 34
        )

        XCTAssertEqual(center.x, 348, accuracy: 0.01)
        XCTAssertEqual(center.y, 716, accuracy: 0.01)
    }

    func testFloatingVinylDefaultPositionAccountsForDevicesWithoutBottomInset() {
        let center = VinylIndicatorLayout.baseCenter(
            in: CGSize(width: 390, height: 844),
            safeAreaBottom: 0
        )

        XCTAssertEqual(center.x, 348, accuracy: 0.01)
        XCTAssertEqual(center.y, 750, accuracy: 0.01)
    }

    func testFloatingVinylDragStaysInsideSafeContentBounds() {
        let size = CGSize(width: 390, height: 844)
        let offset = VinylIndicatorLayout.clampedOffset(
            CGSize(width: -1_000, height: -1_000),
            in: size,
            safeAreaTop: 59,
            safeAreaBottom: 34
        )
        let center = VinylIndicatorLayout.baseCenter(in: size, safeAreaBottom: 34)

        XCTAssertEqual(center.x + offset.width, 42, accuracy: 0.01)
        XCTAssertEqual(center.y + offset.height, 97, accuracy: 0.01)
    }

}
