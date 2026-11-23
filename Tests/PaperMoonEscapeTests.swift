import XCTest
import PaperMoonCore

/// 앱 타깃 위에서 도는 통합 테스트.
/// 실제 플레이 순서를 그대로 따라가며 "이 게임은 끝까지 갈 수 있는가"를 확인한다.
final class PaperMoonEscapeIntegrationTests: XCTestCase {
    private func runAdventure() -> GameEngine {
        let engine = GameEngine(world: .paperMoon)

        // 1장 · 다락방
        _ = engine.tap(.rockingHorse)
        _ = engine.tap(.owlClock)
        _ = engine.moveRight()
        _ = engine.tap(.toyBox)
        _ = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        _ = engine.combine(.keyShardOval, .keyShardTooth)
        _ = engine.combine(.brokenKey, .glueBottle)
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.mendedKey)
        _ = engine.tap(.moonLatch)

        // 2장 · 온실
        _ = engine.tap(.seedPouch)
        _ = engine.tap(.wateringCanCorner)
        _ = engine.moveRight()
        _ = engine.tap(.pondShelf)
        _ = engine.tap(.fireflies)
        _ = engine.combine(.emptyJar, .firefly)
        _ = engine.tap(.frogChorus)
        _ = engine.solvePuzzle(.frogSong, answer: [3, 1, 4, 2])
        _ = engine.moveRight()
        _ = engine.tap(.moonShardBranch)
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.seed)
        _ = engine.tap(.flowerPot)
        _ = engine.tapInventoryItem(.wateringCan)
        _ = engine.tap(.flowerPot)
        _ = engine.tap(.vineGate)

        // 3장 · 시계탑
        _ = engine.tap(.woodBox)
        _ = engine.moveRight()
        _ = engine.tap(.dialPanel)
        _ = engine.solvePuzzle(.gearDials, answer: [0, 1, 3])
        _ = engine.tap(.gearPile)
        _ = engine.combine(.windKey, .gear)
        _ = engine.tapInventoryItem(.clockPart)
        _ = engine.tap(.windSocket)
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.paperMoonShard)
        _ = engine.tap(.paperBell)

        return engine
    }

    func testAdventureRunsFromAtticToEnding() {
        let engine = runAdventure()
        XCTAssertTrue(engine.state.finished)
        XCTAssertEqual(engine.state.clearedStages, Set(StageID.allCases))
        XCTAssertEqual(engine.state.stage, .clocktower)
        XCTAssertEqual(engine.state.room, .towerBelfry)
        XCTAssertEqual(engine.summary().clearedStages, 3)
    }

    func testEveryHintObjectiveIsSatisfiedByTheWalkthrough() {
        let engine = runAdventure()
        let world = World.paperMoon
        for stage in world.stages {
            for hint in world.hints(in: stage.id) {
                XCTAssertTrue(
                    engine.state.satisfies(hint.doneIf),
                    "힌트 목표가 실제 플레이로 달성되지 않는다: \(hint.id)"
                )
            }
        }
    }

    func testContentHasNoContradictions() {
        XCTAssertTrue(World.paperMoon.validate().isEmpty)
    }

    func testEachStageGuardsTheDoorWithItsOwnItem() {
        let world = World.paperMoon
        // 2장 유리방은 랜턴이 필요하고, 3장 종탑은 시계가 감겨야 열린다.
        let glassLock = world.room(.greenhouseGlass)?.lock
        XCTAssertEqual(glassLock?.requirement, .item(.lantern))

        let belfryLock = world.room(.towerBelfry)?.lock
        XCTAssertEqual(belfryLock?.requirement, .flag(Flags.clockWound))
    }

    func testEndingSummaryMatchesPlayedActions() {
        let engine = runAdventure()
        let summary = engine.summary()
        XCTAssertEqual(summary.craftedCount, 4)
        XCTAssertEqual(summary.hintsUsed, 0)
        XCTAssertEqual(summary.clearedStages, 3)
    }

    func testSaveAndResumeKeepsRoomAndProgress() {
        let store = InMemorySaveStore()
        let first = GameEngine(world: .paperMoon, store: store)
        _ = first.tap(.rockingHorse)
        _ = first.moveRight()
        _ = first.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])

        let resumed = GameEngine(world: .paperMoon, store: store)
        XCTAssertEqual(resumed.state.room, .atticToyCloset)
        XCTAssertTrue(resumed.state.solvedPuzzles.contains(.toyBlocks))
        XCTAssertTrue(resumed.state.inventory.contains(.keyShardTooth))
    }
}
