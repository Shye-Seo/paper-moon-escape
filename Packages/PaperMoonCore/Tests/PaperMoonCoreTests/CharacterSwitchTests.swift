import XCTest
import PaperMoonCore

/// 모모 ↔ 고양이 피코 시점 전환과 협동 기믹.
final class CharacterSwitchTests: XCTestCase {
    private func hasCharacterChange(_ events: [GameEvent], _ character: PlayableCharacter) -> Bool {
        events.contains(.characterChanged(character))
    }

    func testGameStartsWithMomo() {
        let engine = GameEngine(world: .paperMoon)
        XCTAssertEqual(engine.activeCharacter, .momo)
        XCTAssertEqual(engine.state.activeCharacter, .momo)
    }

    func testToggleSwitchesToPicoAndBack() {
        let engine = GameEngine(world: .paperMoon)
        let toPico = engine.toggleCharacter()
        XCTAssertTrue(hasCharacterChange(toPico, .pico))
        XCTAssertEqual(engine.activeCharacter, .pico)

        let toMomo = engine.toggleCharacter()
        XCTAssertTrue(hasCharacterChange(toMomo, .momo))
        XCTAssertEqual(engine.activeCharacter, .momo)
    }

    func testSettingSameCharacterDoesNothing() {
        let engine = GameEngine(world: .paperMoon)
        XCTAssertTrue(engine.setCharacter(.momo).isEmpty)
        XCTAssertEqual(engine.activeCharacter, .momo)
    }

    func testSwitchingCharacterClearsSelectedItem() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            inventory: [.keyShardOval]
        )
        _ = engine.tapInventoryItem(.keyShardOval)
        XCTAssertEqual(engine.selectedItem, .keyShardOval)
        let events = engine.toggleCharacter()
        XCTAssertTrue(events.contains(.selection(nil)))
        XCTAssertNil(engine.selectedItem)
    }

    func testPicoCannotReachHighShelf() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            character: .pico
        )
        let events = engine.tap(.highShelf)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "높다"))
        XCTAssertFalse(engine.state.inventory.contains(.paperSheet))
        XCTAssertTrue(engine.state.flags.isEmpty)
    }

    func testMomoReachesHighShelf() {
        let engine = TestHelp.engine(at: .atticLanding, stage: .attic)
        let events = engine.tap(.highShelf)
        XCTAssertTrue(TestHelp.hasItemAdded(events, .paperSheet))
        XCTAssertTrue(engine.state.flags.contains(Flags.paperSheetTaken))
    }

    func testPicoFindsCandleInMouseHole() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            character: .pico
        )
        let events = engine.tap(.mouseHole)
        XCTAssertTrue(TestHelp.hasItemAdded(events, .candleStub))
        XCTAssertTrue(engine.state.flags.contains(Flags.candleStubTaken))
    }

    func testMomoCannotFitIntoMouseHole() {
        let engine = TestHelp.engine(at: .atticToyCloset, stage: .attic)
        let events = engine.tap(.mouseHole)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "좁다"))
        XCTAssertFalse(engine.state.inventory.contains(.candleStub))
    }

    func testPicoSingsWithFrogsAndMomoCannot() {
        let picoEngine = TestHelp.engine(
            at: .greenhousePond,
            stage: .greenhouse,
            character: .pico
        )
        XCTAssertTrue(TestHelp.puzzleOpened(picoEngine.tap(.frogChorus), .frogSong))

        let momoEngine = TestHelp.engine(at: .greenhousePond, stage: .greenhouse)
        let blocked = momoEngine.tap(.frogChorus)
        XCTAssertTrue(TestHelp.hasLine(blocked, containing: "피코"))
        XCTAssertFalse(TestHelp.puzzleOpened(blocked, .frogSong))
    }

    func testPicoCatchesFirefliesAndMomoCannot() {
        let picoEngine = TestHelp.engine(
            at: .greenhousePond,
            stage: .greenhouse,
            character: .pico
        )
        XCTAssertTrue(TestHelp.hasItemAdded(picoEngine.tap(.fireflies), .firefly))

        let momoEngine = TestHelp.engine(at: .greenhousePond, stage: .greenhouse)
        let events = momoEngine.tap(.fireflies)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "피코"))
        XCTAssertFalse(momoEngine.state.inventory.contains(.firefly))
    }

    func testMirrorAndLedgerAreMomoWork() {
        let picoEngine = TestHelp.engine(
            at: .towerGears,
            stage: .clocktower,
            character: .pico
        )
        let events = picoEngine.tap(.dustyMirror)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "모모"))
        XCTAssertFalse(events.contains(.dustPanelOpened("tower.mirror")))

        let momoEngine = TestHelp.engine(at: .towerGears, stage: .clocktower)
        XCTAssertTrue(momoEngine.tap(.dustyMirror).contains(.dustPanelOpened("tower.mirror")))
    }

    func testEnteringStageResetsToMomo() {
        let engine = TestHelp.engine(
            at: .greenhouseVines,
            stage: .greenhouse,
            cleared: [.attic],
            character: .pico
        )
        let events = engine.start(stage: .greenhouse)
        XCTAssertTrue(hasCharacterChange(events, .momo))
        XCTAssertEqual(engine.activeCharacter, .momo)
    }

    func testActiveCharacterSurvivesSaveAndLoad() {
        var state = GameState.newGame(at: Date(timeIntervalSince1970: 1_700_000_000))
        state.activeCharacter = .pico
        guard let data = GameStateCodec.encode(state),
              let decoded = GameStateCodec.decode(data) else {
            return XCTFail("저장 왕복 실패")
        }
        XCTAssertEqual(decoded.activeCharacter, .pico)
        XCTAssertEqual(decoded, state)
    }

    func testOldSaveWithoutCharacterDecodesAsMomo() throws {
        let json = """
        {"stage":"attic","room":"atticLanding","inventory":[],"flags":[],"solvedPuzzles":[],
         "claimedHotspots":[],"hintLevels":{},"puzzleAttempts":{},"hintsUsed":0,"craftedCount":0,
         "startedAt":0,"finished":false,"clearedStages":[]}
        """
        guard let data = json.data(using: .utf8) else { return XCTFail("JSON 실패") }
        let decoded = try XCTUnwrap(GameStateCodec.decode(data))
        XCTAssertEqual(decoded.activeCharacter, .momo)
        XCTAssertTrue(decoded.collected.isEmpty)
        XCTAssertFalse(decoded.secretDrawerOpened)
    }
}
