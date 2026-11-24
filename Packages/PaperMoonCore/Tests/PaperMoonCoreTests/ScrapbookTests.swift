import XCTest
import PaperMoonCore

/// 다락방 숨은 종이학 스크랩북과 비밀 서랍.
final class ScrapbookTests: XCTestCase {
    func testCraneGoalIsTwelve() {
        XCTAssertEqual(GameState.craneGoal, 12)
        XCTAssertEqual(World.paperMoon.collectibles.filter { $0.kind == .crane }.count, 12)
    }

    func testCraneSpotsMatchTheirRooms() {
        let world = World.paperMoon
        for collectible in world.collectibles {
            XCTAssertNotNil(world.room(collectible.room), "\(collectible.id) 방이 없다")
            XCTAssertTrue(world.collectibles(in: collectible.room).contains { $0.id == collectible.id })
        }
    }

    func testCollectingCraneAddsItToScrapbook() {
        let engine = TestHelp.engine(at: .atticLanding, stage: .attic)
        let events = engine.collect(.craneAtticLanding)
        XCTAssertTrue(events.contains(.collectibleFound(.craneAtticLanding)))
        XCTAssertTrue(engine.state.hasCollected(.craneAtticLanding))
        XCTAssertEqual(engine.state.collectedCranes, 1)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "창틀의 종이학"))
    }

    func testCollectedCraneLeavesTheScene() {
        let engine = TestHelp.engine(at: .atticLanding, stage: .attic)
        XCTAssertTrue(engine.visibleCollectibles.contains { $0.id == .craneAtticLanding })
        _ = engine.collect(.craneAtticLanding)
        XCTAssertFalse(engine.visibleCollectibles.contains { $0.id == .craneAtticLanding })
    }

    func testCollectingTwiceDoesNotDoubleCount() {
        let engine = TestHelp.engine(at: .atticLanding, stage: .attic)
        _ = engine.collect(.craneAtticLanding)
        let events = engine.collect(.craneAtticLanding)
        XCTAssertFalse(events.contains(.collectibleFound(.craneAtticLanding)))
        XCTAssertEqual(engine.state.collectedCranes, 1)
    }

    func testCollectingInWrongRoomIsBlocked() {
        let engine = TestHelp.engine(at: .atticLanding, stage: .attic)
        let events = engine.collect(.craneBelfry)
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertEqual(engine.state.collectedCranes, 0)
    }

    func testStampsAreCollectedButDoNotCountAsCranes() {
        let engine = TestHelp.engine(at: .atticLanding, stage: .attic)
        _ = engine.collect(.stampAttic)
        XCTAssertEqual(engine.state.collectedStamps, 1)
        XCTAssertEqual(engine.state.collectedCranes, 0)
    }

    func testTwelveCranesUnlockSecretDrawer() {
        let engine = Playthrough.collectAllCranes()
        XCTAssertEqual(engine.state.collectedCranes, 12)
        XCTAssertTrue(engine.state.flags.contains(Flags.cranesComplete))
        XCTAssertEqual(engine.summary().collectedCranes, 12)
        XCTAssertFalse(engine.state.secretDrawerOpened)
    }

    func testDrawerStaysShutBeforeTwelveCranes() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            collected: [.craneAtticLanding, .craneAtticLadder]
        )
        let events = engine.openSecretDrawer()
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertFalse(engine.state.secretDrawerOpened)
    }

    func testOpeningDrawerGivesTheGift() {
        let engine = Playthrough.collectAllCranes()
        let events = engine.openSecretDrawer()
        XCTAssertTrue(events.contains(.secretDrawerOpened(.paperMoon)))
        XCTAssertTrue(engine.state.secretDrawerOpened)
        XCTAssertTrue(engine.state.flags.contains(Flags.secretDrawer))
        XCTAssertTrue(TestHelp.hasLine(events, containing: "모빌"))
    }

    func testDrawerOpensOnlyOnce() {
        let engine = Playthrough.collectAllCranes()
        _ = engine.openSecretDrawer()
        let again = engine.openSecretDrawer()
        XCTAssertFalse(again.contains(.secretDrawerOpened(.paperMoon)))
        XCTAssertTrue(TestHelp.hasLine(again, containing: "열린 채"))
    }

    func testSecretGiftHasReadableContent() {
        let gift = World.paperMoon.secretGift
        XCTAssertFalse(gift.title.isEmpty)
        XCTAssertGreaterThanOrEqual(gift.lines.count, 3)
        XCTAssertFalse(gift.keepsake.isEmpty)
    }

    func testCollectedSurvivesSaveRoundTrip() {
        var state = GameState.newGame(at: Date(timeIntervalSince1970: 1_700_000_000))
        state.collected = [.craneAtticLanding, .stampTower]
        state.secretDrawerOpened = true
        guard let data = GameStateCodec.encode(state),
              let decoded = GameStateCodec.decode(data) else {
            return XCTFail("저장 왕복 실패")
        }
        XCTAssertEqual(decoded.collected, state.collected)
        XCTAssertTrue(decoded.secretDrawerOpened)
        XCTAssertEqual(decoded.collectedCranes, 1)
        XCTAssertEqual(decoded.collectedStamps, 1)
    }
}
