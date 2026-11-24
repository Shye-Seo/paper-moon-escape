import XCTest
import PaperMoonCore

final class HintTests: XCTestCase {
    func testFirstHintGivesDirectionOnly() {
        let engine = GameEngine(world: .paperMoon)
        let events = engine.requestHint()
        guard case .hint(let id, let level, let text, let hasMore)? = events.first(where: {
            if case .hint = $0 { return true }
            return false
        }) else {
            return XCTFail("힌트 이벤트가 없다")
        }
        XCTAssertEqual(id, "attic.progress.1")
        XCTAssertEqual(level, 1)
        XCTAssertTrue(hasMore)
        XCTAssertFalse(text.contains("안장"))
        XCTAssertTrue(text.contains("목마"))
    }

    func testSecondRequestGivesConcreteHint() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.requestHint()
        let events = engine.requestHint()
        guard case .hint(_, let level, let text, let hasMore)? = events.first(where: {
            if case .hint = $0 { return true }
            return false
        }) else {
            return XCTFail("힌트 이벤트가 없다")
        }
        XCTAssertEqual(level, 2)
        XCTAssertFalse(hasMore)
        XCTAssertTrue(text.contains("안장"))
    }

    func testHintCountsOnlyOnEscalation() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.requestHint()
        XCTAssertEqual(engine.state.hintsUsed, 1)
        _ = engine.requestHint()
        XCTAssertEqual(engine.state.hintsUsed, 2)
        _ = engine.requestHint()
        XCTAssertEqual(engine.state.hintsUsed, 2, "같은 단계 반복은 사용 횟수를 늘리지 않는다")
    }

    func testHintMovesToNextObjectiveAfterProgress() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.tap(.rockingHorse)
        let events = engine.requestHint()
        guard case .hint(let id, _, _, _)? = events.first(where: {
            if case .hint = $0 { return true }
            return false
        }) else {
            return XCTFail("힌트 이벤트가 없다")
        }
        XCTAssertEqual(id, "attic.progress.2")
    }

    func testHintsAreTwoStepPerObjective() {
        let world = World.paperMoon
        for hint in world.hints {
            XCTAssertNotEqual(hint.levelOne, hint.levelTwo, "힌트 \(hint.id)의 두 단계가 같다")
        }
        XCTAssertEqual(world.hints(in: .attic).count, 9)
        XCTAssertEqual(world.hints(in: .greenhouse).count, 7)
        XCTAssertEqual(world.hints(in: .clocktower).count, 5)
        XCTAssertEqual(world.hints(in: .cellar).count, 6)
    }

    func testHintAtStageEndIsFriendly() {
        let engine = TestHelp.engine(
            at: .atticMoonWindow,
            stage: .attic,
            flags: [
                Flags.horseRocked, Flags.owlAwake, Flags.toyBoxOpen,
                Flags.keyMended, Flags.moonOpened,
                Flags.paperSheetTaken, Flags.origamiMoon, Flags.candleStubTaken, Flags.lampLit
            ],
            cleared: [.attic]
        )
        let events = engine.requestHint()
        XCTAssertTrue(TestHelp.hasLine(events, containing: "물어볼 것이 없어"))
    }
}

final class ProgressTests: XCTestCase {
    func testFullWalkthroughFinishesGame() {
        let engine = Playthrough.run()
        XCTAssertTrue(engine.state.finished)
        XCTAssertEqual(engine.state.clearedStages.count, 3)
        XCTAssertEqual(engine.state.stage, .clocktower)
        XCTAssertEqual(engine.state.room, .towerBelfry)
        XCTAssertFalse(engine.state.inventory.contains(.paperMoonShard))
        XCTAssertNil(engine.selectedItem)
    }

    func testWalkthroughProducesEndingSummary() {
        let engine = Playthrough.run()
        let summary = engine.summary()
        XCTAssertEqual(summary.clearedStages, 3)
        XCTAssertEqual(summary.hintsUsed, 0)
        XCTAssertEqual(summary.craftedCount, 5, "부러진 열쇠 · 이어 붙인 열쇠 · 랜턴 · 시계 부품 · 켜진 종이달 등불")
        XCTAssertEqual(summary.itemCount, 3, "엔딩 시점에는 랜턴 · 물뿌리개 · 켜진 종이달 등불이 남는다")
    }

    func testStageTransitionCarriesOpeningText() {
        let engine = TestHelp.engine(
            at: .atticMoonWindow,
            stage: .attic,
            inventory: [.mendedKey],
            flags: [Flags.lampLit]
        )
        _ = engine.tapInventoryItem(.mendedKey)
        let events = engine.tap(.moonLatch)
        XCTAssertTrue(events.contains(.stageStarted(.greenhouse)))
        XCTAssertTrue(events.contains(.roomChanged(.greenhouseVines)))
        XCTAssertTrue(TestHelp.hasLine(events, containing: "온실"))
    }

    func testClearingFirstStageKeepsInventoryFromThatStage() {
        let engine = TestHelp.engine(
            at: .atticMoonWindow,
            stage: .attic,
            inventory: [.seed, .mendedKey],
            flags: [Flags.lampLit]
        )
        _ = engine.tapInventoryItem(.mendedKey)
        _ = engine.tap(.moonLatch)
        XCTAssertEqual(engine.state.stage, .greenhouse)
        XCTAssertTrue(engine.state.inventory.contains(.seed))
    }

    func testResetStageRemovesStageItemsAndFlags() {
        let engine = GameEngine(world: .paperMoon)
        _ = engine.tap(.rockingHorse)
        _ = engine.moveRight()
        _ = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        XCTAssertFalse(engine.state.inventory.isEmpty)

        _ = engine.resetStage()
        XCTAssertTrue(engine.state.inventory.isEmpty)
        XCTAssertFalse(engine.state.flags.contains(Flags.horseRocked))
        XCTAssertFalse(engine.state.flags.contains(Flags.toyBoxOpen))
        XCTAssertFalse(engine.state.solvedPuzzles.contains(.toyBlocks))
        XCTAssertFalse(engine.state.claimedHotspots.contains(.rockingHorse))
        XCTAssertEqual(engine.state.room, .atticLanding)
        XCTAssertEqual(engine.state.attempts(for: .toyBlocks), 0)
    }

    func testResetStageKeepsEarlierStageProgress() {
        let engine = TestHelp.engine(
            at: .greenhouseVines,
            stage: .greenhouse,
            inventory: [.mendedKey, .seed],
            flags: [Flags.keyMended],
            cleared: [.attic]
        )
        _ = engine.resetStage()
        XCTAssertTrue(engine.state.clearedStages.contains(.attic))
        XCTAssertTrue(engine.state.flags.contains(Flags.keyMended))
        XCTAssertTrue(engine.state.inventory.contains(.mendedKey))
        XCTAssertFalse(engine.state.inventory.contains(.seed))
    }

    func testRestartGameClearsEverything() {
        let engine = Playthrough.run()
        XCTAssertTrue(engine.state.finished)
        _ = engine.restartGame()
        XCTAssertFalse(engine.state.finished)
        XCTAssertTrue(engine.state.inventory.isEmpty)
        XCTAssertTrue(engine.state.flags.isEmpty)
        XCTAssertTrue(engine.state.clearedStages.isEmpty)
        XCTAssertEqual(engine.state.room, .atticLanding)
    }

    func testElapsedTimeIsMeasuredFromStart() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var now = start
        let engine = GameEngine(world: .paperMoon, clock: { now })
        now = start.addingTimeInterval(95)
        XCTAssertEqual(engine.summary().seconds, 95, accuracy: 0.001)
    }
}
