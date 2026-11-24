import XCTest
import PaperMoonCore

/// 종이접기 퍼즐과 빛 투과 퍼즐 — 1장면의 접기, 2장면의 빛, 보너스 장면의 두 퍼즐까지.
final class OrigamiPuzzleTests: XCTestCase {
    func testOrigamiPuzzleIsTactileType() {
        let puzzle = World.paperMoon.puzzle(.paperMoonOrigami)
        XCTAssertEqual(puzzle?.kind, .origami)
        XCTAssertEqual(puzzle?.goal, "종이달 등불")
        XCTAssertEqual(puzzle?.tokens.count, 4)
        XCTAssertEqual(puzzle?.solution.count, puzzle?.tokens.count)
        XCTAssertTrue(puzzle?.kind.isTouchGesture == true)
    }

    func testDeskNeedsPaperSheetFirst() {
        let engine = TestHelp.engine(at: .atticToyCloset, stage: .attic)
        let events = engine.tap(.foldingDesk)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "접을 종이"))
        XCTAssertFalse(TestHelp.puzzleOpened(events, .paperMoonOrigami))
    }

    func testDeskOpensPuzzleWithPaperSheet() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            inventory: [.paperSheet]
        )
        let events = engine.tap(.foldingDesk)
        XCTAssertTrue(TestHelp.puzzleOpened(events, .paperMoonOrigami))
    }

    func testSelectedPaperSheetAlsoOpensPuzzle() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            inventory: [.paperSheet]
        )
        _ = engine.tapInventoryItem(.paperSheet)
        let events = engine.tap(.foldingDesk)
        XCTAssertTrue(TestHelp.puzzleOpened(events, .paperMoonOrigami))
        XCTAssertTrue(engine.state.inventory.contains(.paperSheet), "퍼즐을 여는 것만으로 종이가 사라지면 안 된다")
    }

    func testWrongFoldOrderIsRetried() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            inventory: [.paperSheet]
        )
        let events = engine.solvePuzzle(.paperMoonOrigami, answer: [0, 1, 2, 3])
        XCTAssertTrue(events.contains(.puzzleMissed(.paperMoonOrigami, attempts: 1)))
        XCTAssertFalse(engine.state.solvedPuzzles.contains(.paperMoonOrigami))
        XCTAssertFalse(engine.state.inventory.contains(.paperMoonLamp))
        XCTAssertEqual(engine.state.attempts(for: .paperMoonOrigami), 1)
    }

    func testCorrectFoldOrderMakesMoonLamp() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            inventory: [.paperSheet]
        )
        let events = engine.solvePuzzle(.paperMoonOrigami, answer: [0, 2, 1, 3])
        XCTAssertTrue(events.contains(.puzzleSolved(.paperMoonOrigami)))
        XCTAssertTrue(engine.state.inventory.contains(.paperMoonLamp))
        XCTAssertFalse(engine.state.inventory.contains(.paperSheet), "접은 종이는 등불이 되며 사라진다")
        XCTAssertTrue(engine.state.flags.contains(Flags.origamiMoon))
    }

    func testSolvedDeskDisappearsFromScene() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            inventory: [.paperSheet]
        )
        _ = engine.solvePuzzle(.paperMoonOrigami, answer: [0, 2, 1, 3])
        XCTAssertFalse(engine.visibleHotspots().contains { $0.id == .foldingDesk })
    }

    func testOrigamiDeskIsForMomoOnly() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            inventory: [.paperSheet],
            character: .pico
        )
        let events = engine.tap(.foldingDesk)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "모모의 손"))
        XCTAssertFalse(TestHelp.puzzleOpened(events, .paperMoonOrigami))
    }

    func testCellarBoatPuzzleIsAlsoOrigami() {
        let puzzle = World.paperMoon.puzzle(.cellarBoat)
        XCTAssertEqual(puzzle?.kind, .origami)
        XCTAssertEqual(puzzle?.goal, "종이배")
        XCTAssertNotEqual(puzzle?.solution, [0, 1, 2, 3])
    }

    func testSolvingCellarBoatTurnsVellumIntoBoat() {
        let engine = TestHelp.engine(
            at: .cellarPantry,
            stage: .cellar,
            inventory: [.vellumPage],
            flags: [Flags.cellarGateOpen],
            cleared: [.attic, .greenhouse, .clocktower]
        )
        _ = engine.solvePuzzle(.cellarBoat, answer: [1, 3, 0, 2])
        XCTAssertTrue(engine.state.inventory.contains(.paperBoat))
        XCTAssertFalse(engine.state.inventory.contains(.vellumPage))
        XCTAssertTrue(engine.state.flags.contains(Flags.boatFolded))
    }
}

final class LightRevealPuzzleTests: XCTestCase {
    func testLightPuzzleDeclaresItsLightSource() {
        let puzzle = World.paperMoon.puzzle(.tornPaperCode)
        XCTAssertEqual(puzzle?.kind, .lightReveal)
        XCTAssertEqual(puzzle?.lightSource, .lantern)
        XCTAssertEqual(puzzle?.revealedCode, "달은 나뭇가지 끝에서 잠깐 쉰다")
        XCTAssertEqual(puzzle?.solution.count, 4)
    }

    func testWindowNeedsLanternToFocus() {
        let engine = TestHelp.engine(
            at: .greenhouseGlass,
            stage: .greenhouse,
            character: .pico
        )
        let events = engine.tap(.tornPaperWindow)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "비출 빛"))
        XCTAssertFalse(TestHelp.puzzleOpened(events, .tornPaperCode))
    }

    func testWindowIsForPicoOnly() {
        let engine = TestHelp.engine(
            at: .greenhouseGlass,
            stage: .greenhouse,
            inventory: [.lantern]
        )
        let events = engine.tap(.tornPaperWindow)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "피코"))
        XCTAssertFalse(TestHelp.puzzleOpened(events, .tornPaperCode))
    }

    func testLanternInHandOpensLightPuzzle() {
        let engine = TestHelp.engine(
            at: .greenhouseGlass,
            stage: .greenhouse,
            inventory: [.lantern],
            character: .pico
        )
        let events = engine.tap(.tornPaperWindow)
        XCTAssertTrue(TestHelp.puzzleOpened(events, .tornPaperCode))
    }

    func testSelectedLanternAlsoOpensLightPuzzle() {
        let engine = TestHelp.engine(
            at: .greenhouseGlass,
            stage: .greenhouse,
            inventory: [.lantern],
            character: .pico
        )
        _ = engine.tapInventoryItem(.lantern)
        let events = engine.tap(.tornPaperWindow)
        XCTAssertTrue(TestHelp.puzzleOpened(events, .tornPaperCode))
    }

    func testMisalignedPiecesRevealNothing() {
        let engine = TestHelp.engine(
            at: .greenhouseGlass,
            stage: .greenhouse,
            inventory: [.lantern],
            character: .pico
        )
        let events = engine.solvePuzzle(.tornPaperCode, answer: [0, 1, 2, 3])
        XCTAssertTrue(events.contains(.puzzleMissed(.tornPaperCode, attempts: 1)))
        XCTAssertFalse(engine.state.flags.contains(Flags.lightCodeSeen))
    }

    func testAlignedPiecesRevealHiddenCode() {
        let engine = TestHelp.engine(
            at: .greenhouseGlass,
            stage: .greenhouse,
            inventory: [.lantern],
            character: .pico
        )
        let events = engine.solvePuzzle(.tornPaperCode, answer: [2, 0, 3, 1])
        XCTAssertTrue(TestHelp.hasLine(events, containing: "숨은 글씨"))
        XCTAssertTrue(engine.state.flags.contains(Flags.lightCodeSeen))
    }

    func testShardIsHiddenUntilCodeIsRead() {
        let engine = TestHelp.engine(
            at: .greenhouseGlass,
            stage: .greenhouse,
            inventory: [.lantern],
            character: .pico
        )
        let blocked = engine.tap(.moonShardBranch)
        XCTAssertTrue(TestHelp.hasLine(blocked, containing: "흐릿"))
        XCTAssertFalse(engine.state.inventory.contains(.paperMoonShard))

        _ = engine.solvePuzzle(.tornPaperCode, answer: [2, 0, 3, 1])
        let found = engine.tap(.moonShardBranch)
        XCTAssertTrue(TestHelp.hasItemAdded(found, .paperMoonShard))
        XCTAssertTrue(engine.state.flags.contains(Flags.shardFound))
    }

    func testCellarVaultPuzzleUsesOilLamp() {
        let puzzle = World.paperMoon.puzzle(.cellarVaultCode)
        XCTAssertEqual(puzzle?.kind, .lightReveal)
        XCTAssertEqual(puzzle?.lightSource, .oilLamp)
        XCTAssertEqual(puzzle?.revealedCode, "세 번 돌리고, 두 번 멈춘다")
    }
}
