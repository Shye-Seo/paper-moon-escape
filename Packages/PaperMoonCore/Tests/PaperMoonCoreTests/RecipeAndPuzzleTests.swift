import XCTest
import PaperMoonCore

final class RecipeTests: XCTestCase {
    func testTwoKeyShardsMakeBrokenKey() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            inventory: [.keyShardOval, .keyShardTooth]
        )
        let events = engine.combine(.keyShardOval, .keyShardTooth)
        XCTAssertEqual(engine.state.inventory, [.brokenKey])
        XCTAssertTrue(TestHelp.has(events, .crafted(result: .brokenKey, ingredients: [.keyShardOval, .keyShardTooth])))
        XCTAssertEqual(engine.state.craftedCount, 1)
    }

    func testBrokenKeyAndGlueMakeMendedKey() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            inventory: [.brokenKey, .glueBottle]
        )
        _ = engine.combine(.brokenKey, .glueBottle)
        XCTAssertEqual(engine.state.inventory, [.mendedKey])
        XCTAssertTrue(engine.state.flags.contains(Flags.keyMended))
    }

    func testComboOrderDoesNotMatter() {
        let engine = TestHelp.engine(
            at: .greenhouseVines,
            stage: .greenhouse,
            inventory: [.firefly, .emptyJar]
        )
        _ = engine.combine(.firefly, .emptyJar)
        XCTAssertEqual(engine.state.inventory, [.lantern])
    }

    func testClockPartNeedsWindKeyAndGear() {
        let engine = TestHelp.engine(
            at: .towerStairs,
            stage: .clocktower,
            inventory: [.gear, .windKey]
        )
        _ = engine.combine(.gear, .windKey)
        XCTAssertEqual(engine.state.inventory, [.clockPart])
    }

    func testInvalidComboKeepsBothItemsAndClearsSelection() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            inventory: [.seed, .glueBottle]
        )
        _ = engine.tapInventoryItem(.seed)
        XCTAssertEqual(engine.selectedItem, .seed)

        let events = engine.tapInventoryItem(.glueBottle)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "어울리지 않는다"))
        XCTAssertNil(engine.selectedItem)
        XCTAssertEqual(Set(engine.state.inventory), Set([.seed, .glueBottle]))
        XCTAssertEqual(engine.state.craftedCount, 0)
    }

    func testSameItemCannotBeCombined() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            inventory: [.seed]
        )
        let events = engine.combine(.seed, .seed)
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertEqual(engine.state.inventory, [.seed])
    }

    func testCombineRequiresItemsInInventory() {
        let engine = GameEngine(world: .paperMoon)
        let events = engine.combine(.brokenKey, .glueBottle)
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertTrue(engine.state.inventory.isEmpty)
    }

    func testSelectingSameItemTwiceDeselects() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            inventory: [.seed]
        )
        _ = engine.tapInventoryItem(.seed)
        XCTAssertEqual(engine.selectedItem, .seed)
        _ = engine.tapInventoryItem(.seed)
        XCTAssertNil(engine.selectedItem)
    }
}

final class PuzzleTests: XCTestCase {
    func testWrongBlockOrderIsRejected() {
        let engine = TestHelp.engine(at: .atticToyCloset, stage: .attic)
        let events = engine.solvePuzzle(.toyBlocks, answer: [0, 1, 2, 3])
        XCTAssertTrue(events.contains(.puzzleMissed(.toyBlocks, attempts: 1)))
        XCTAssertFalse(engine.state.solvedPuzzles.contains(.toyBlocks))
        XCTAssertEqual(engine.state.attempts(for: .toyBlocks), 1)
        XCTAssertFalse(engine.state.inventory.contains(.keyShardTooth))
    }

    func testCorrectBlockOrderGivesShard() {
        let engine = TestHelp.engine(at: .atticToyCloset, stage: .attic)
        let events = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        XCTAssertTrue(events.contains(.puzzleSolved(.toyBlocks)))
        XCTAssertTrue(engine.state.solvedPuzzles.contains(.toyBlocks))
        XCTAssertTrue(engine.state.flags.contains(Flags.toyBoxOpen))
        XCTAssertTrue(engine.state.inventory.contains(.keyShardTooth))
    }

    func testFrogSongSolutionStartsWater() {
        let engine = TestHelp.engine(at: .greenhousePond, stage: .greenhouse)
        let events = engine.solvePuzzle(.frogSong, answer: [3, 1, 4, 2])
        XCTAssertTrue(events.contains(.puzzleSolved(.frogSong)))
        XCTAssertTrue(engine.state.flags.contains(Flags.waterFlowing))
    }

    func testFrogSongPartialAnswerIsMissed() {
        let engine = TestHelp.engine(at: .greenhousePond, stage: .greenhouse)
        let events = engine.solvePuzzle(.frogSong, answer: [3, 1, 4])
        XCTAssertEqual(engine.state.attempts(for: .frogSong), 1)
        XCTAssertTrue(TestHelp.hasBlocked(events) || events.contains { event in
            if case .puzzleMissed = event { return true }
            return false
        })
    }

    func testGearDialsSolutionSetsFlag() {
        let engine = TestHelp.engine(at: .towerGears, stage: .clocktower)
        _ = engine.solvePuzzle(.gearDials, answer: [0, 1, 3])
        XCTAssertTrue(engine.state.flags.contains(Flags.gearsSolved))
    }

    func testPuzzleCannotBeSolvedTwiceForRewards() {
        let engine = TestHelp.engine(at: .atticToyCloset, stage: .attic)
        _ = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        let second = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        XCTAssertTrue(TestHelp.hasLine(second, containing: "이미 풀린"))
        XCTAssertEqual(engine.state.inventory.filter { $0 == .keyShardTooth }.count, 1)
    }
}
