import XCTest
import PaperMoonCore

final class SaveTests: XCTestCase {
    func testStateRoundTripThroughCodec() {
        let state = GameState(
            stage: .greenhouse,
            room: .greenhousePond,
            inventory: [.seed],
            flags: [Flags.waterFlowing],
            solvedPuzzles: [.frogSong],
            claimedHotspots: [.frogChorus],
            hintLevels: ["greenhouse.progress.1": 2],
            puzzleAttempts: [PuzzleID.frogSong.rawValue: 1],
            hintsUsed: 3,
            craftedCount: 2,
            selectedItem: .seed,
            startedAt: Date(timeIntervalSince1970: 1_700_000_123.456),
            finishedAt: nil,
            finished: false,
            clearedStages: [.attic]
        )
        guard let data = GameStateCodec.encode(state) else {
            return XCTFail("인코딩 실패")
        }
        guard let decoded = GameStateCodec.decode(data) else {
            return XCTFail("디코딩 실패")
        }
        XCTAssertEqual(decoded, state)
    }

    func testEngineAutosavesAfterAction() {
        let store = InMemorySaveStore()
        let engine = GameEngine(world: .paperMoon, store: store)
        XCTAssertEqual(store.saveCount, 0)
        _ = engine.tap(.rockingHorse)
        XCTAssertGreaterThan(store.saveCount, 0)
        XCTAssertEqual(store.stored?.inventory, [.keyShardOval])
    }

    func testEngineRestoresSavedGame() {
        let store = InMemorySaveStore()
        let first = GameEngine(world: .paperMoon, store: store)
        _ = first.tap(.rockingHorse)
        _ = first.moveRight()

        let restored = GameEngine(world: .paperMoon, store: store)
        XCTAssertEqual(restored.state.room, .atticToyCloset)
        XCTAssertEqual(restored.state.inventory, [.keyShardOval])
    }

    func testEmptyStoreStartsNewGame() {
        let store = InMemorySaveStore()
        let engine = GameEngine(world: .paperMoon, store: store)
        XCTAssertEqual(engine.state.room, .atticLanding)
        XCTAssertTrue(engine.state.inventory.isEmpty)
    }

    func testClearWipesSave() {
        let store = InMemorySaveStore()
        let engine = GameEngine(world: .paperMoon, store: store)
        _ = engine.tap(.rockingHorse)
        XCTAssertNotNil(store.stored)
        store.clear()
        XCTAssertNil(store.load())
    }
}

final class ContentTests: XCTestCase {
    func testWorldValidationIsClean() {
        let problems = World.paperMoon.validate()
        XCTAssertTrue(problems.isEmpty, "콘텐츠 문제: \(problems.joined(separator: ", "))")
    }

    func testThreeStagesWithThreeRoomsEach() {
        let world = World.paperMoon
        XCTAssertEqual(world.stages.count, 3)
        for stage in world.stages {
            XCTAssertEqual(stage.rooms.count, 3, "\(stage.id) 방 개수")
            for roomID in stage.rooms {
                XCTAssertNotNil(world.room(roomID))
                XCTAssertGreaterThanOrEqual(world.hotspots(in: roomID).count, 3)
            }
        }
    }

    func testEveryStageHasOnePuzzle() {
        let world = World.paperMoon
        for stage in world.stages {
            XCTAssertEqual(world.puzzles(in: stage.id).count, 1, "\(stage.id) 퍼즐 개수")
        }
    }

    func testEveryItemIsObtainable() {
        let world = World.paperMoon
        var reachable = Set<ItemID>()
        for stage in world.stages {
            reachable.formUnion(world.stageItemPool(stage.id))
        }
        for item in ItemID.allCases {
            XCTAssertTrue(reachable.contains(item), "얻을 수 없는 아이템: \(item.rawValue)")
        }
    }

    func testAllFourCombosExist() {
        let world = World.paperMoon
        XCTAssertEqual(world.combos.count, 4)
        XCTAssertNotNil(world.combo(.keyShardOval, .keyShardTooth))
        XCTAssertNotNil(world.combo(.brokenKey, .glueBottle))
        XCTAssertNotNil(world.combo(.emptyJar, .firefly))
        XCTAssertNotNil(world.combo(.windKey, .gear))
    }

    func testPuzzleSolutionsDifferFromTokenOrder() {
        let world = World.paperMoon
        for puzzle in world.puzzles {
            let ordered = puzzle.tokens.map { $0.value }
            XCTAssertNotEqual(puzzle.solution, Array(ordered.prefix(puzzle.solution.count)), "\(puzzle.id) 정답이 그냥 순서다")
        }
    }

    func testIllegalRequirementReferenceIsDetected() {
        let broken = World(
            stages: [
                Stage(id: .attic, number: 1, title: "t", subtitle: "s", rooms: [.atticLanding],
                      opening: "", closing: "", next: nil)
            ],
            rooms: [Room(id: .atticLanding, stage: .attic, title: "t", caption: "", art: .atticLanding)],
            items: [],
            hotspots: [],
            puzzles: [],
            combos: [],
            hints: []
        )
        let problems = broken.validate()
        XCTAssertFalse(problems.isEmpty)
        XCTAssertTrue(problems.contains { $0.contains("방이 너무 적다") })
    }
}
