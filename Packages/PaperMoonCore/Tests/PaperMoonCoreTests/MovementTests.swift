import XCTest
import PaperMoonCore

final class MovementTests: XCTestCase {
    func testGameStartsInFirstRoomOfAttic() {
        let engine = GameEngine(world: .paperMoon)
        XCTAssertEqual(engine.state.stage, .attic)
        XCTAssertEqual(engine.state.room, .atticLanding)
        XCTAssertTrue(engine.state.inventory.isEmpty)
        XCTAssertFalse(engine.state.finished)
    }

    func testMoveRightWrapsAroundThreeRooms() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.moveRight()
        XCTAssertEqual(engine.state.room, .atticToyCloset)
        _ = engine.moveRight()
        XCTAssertEqual(engine.state.room, .atticMoonWindow)
        _ = engine.moveRight()
        XCTAssertEqual(engine.state.room, .atticLanding)
    }

    func testMoveLeftWrapsBackwards() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.moveLeft()
        XCTAssertEqual(engine.state.room, .atticMoonWindow)
    }

    func testChangingRoomClearsSelectedItem() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.tap(.rockingHorse)
        _ = engine.tapInventoryItem(.keyShardOval)
        XCTAssertEqual(engine.selectedItem, .keyShardOval)

        _ = engine.moveRight()
        XCTAssertNil(engine.selectedItem)
    }

    func testLockedRoomBlocksEntryWithoutLantern() {
        let engine = TestHelp.engine(at: .greenhousePond, stage: .greenhouse)
        let events = engine.moveRight()
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertEqual(engine.state.room, .greenhousePond)
    }

    func testLanternOpensDarkGlassRoom() {
        let engine = TestHelp.engine(
            at: .greenhousePond,
            stage: .greenhouse,
            inventory: [.lantern]
        )
        _ = engine.moveRight()
        XCTAssertEqual(engine.state.room, .greenhouseGlass)
    }

    func testStageSelectRefusesUnopenedStage() {
        let engine = GameEngine(world: .paperMoon)
        let events = engine.start(stage: .clocktower)
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertEqual(engine.state.stage, .attic)
    }

    func testStageSelectAllowsClearedPath() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            cleared: [.attic]
        )
        _ = engine.start(stage: .greenhouse)
        XCTAssertEqual(engine.state.stage, .greenhouse)
        XCTAssertEqual(engine.state.room, .greenhouseVines)
    }
}

final class HotspotTests: XCTestCase {
    func testRockingHorseGivesKeyShardAndFlag() {
        let engine = GameEngine(world: .paperMoon)
        let events = engine.tap(.rockingHorse)
        XCTAssertTrue(TestHelp.hasItemAdded(events, .keyShardOval))
        XCTAssertEqual(engine.state.inventory, [.keyShardOval])
        XCTAssertTrue(engine.state.flags.contains(Flags.horseRocked))
    }

    func testRepeatTapGivesRepeatTextAndNoDuplicateItem() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.tap(.rockingHorse)
        let again = engine.tap(.rockingHorse)
        XCTAssertTrue(TestHelp.hasLine(again, containing: "목마"))
        XCTAssertEqual(engine.state.inventory.filter { $0 == .keyShardOval }.count, 1)
    }

    func testOwlIsBlockedUntilHorseRocked() {
        let engine = GameEngine(world: .paperMoon)
        let blocked = engine.tap(.owlClock)
        XCTAssertTrue(TestHelp.hasLine(blocked, containing: "새근새근"))
        XCTAssertFalse(engine.state.inventory.contains(.glueBottle))

        _ = engine.tap(.rockingHorse)
        let awake = engine.tap(.owlClock)
        XCTAssertTrue(TestHelp.hasItemAdded(awake, .glueBottle))
        XCTAssertTrue(engine.state.flags.contains(Flags.owlAwake))
    }

    func testHotspotInAnotherRoomIsNotReachable() {
        let engine = GameEngine(world: .paperMoon)
        let events = engine.tap(.moonLatch)
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertFalse(engine.state.flags.contains(Flags.moonOpened))
    }

    func testUsingWrongItemOnHotspotDoesNothing() {
        let engine = TestHelp.engine(
            at: .atticMoonWindow,
            stage: .attic,
            inventory: [.glueBottle]
        )
        _ = engine.tapInventoryItem(.glueBottle)
        let events = engine.tap(.moonLatch)
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertNil(engine.selectedItem)
    }

    func testItemReactionConsumesKeyAndClearsStage() {
        let engine = TestHelp.engine(
            at: .atticMoonWindow,
            stage: .attic,
            inventory: [.mendedKey]
        )
        _ = engine.tapInventoryItem(.mendedKey)
        let events = engine.tap(.moonLatch)
        XCTAssertFalse(engine.state.inventory.contains(.mendedKey))
        XCTAssertTrue(engine.state.clearedStages.contains(.attic))
        XCTAssertTrue(events.contains(.stageCleared(.attic)))
        XCTAssertEqual(engine.state.stage, .greenhouse)
    }

    func testPuzzleHotspotClaimsAndRepeats() {
        let engine = TestHelp.engine(at: .atticToyCloset, stage: .attic)
        let first = engine.tap(.toyBox)
        XCTAssertTrue(TestHelp.puzzleOpened(first, .toyBlocks))
        _ = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        let again = engine.tap(.toyBox)
        XCTAssertTrue(TestHelp.hasLine(again, containing: "활짝"))
        XCTAssertFalse(TestHelp.puzzleOpened(again, .toyBlocks))
    }
}
