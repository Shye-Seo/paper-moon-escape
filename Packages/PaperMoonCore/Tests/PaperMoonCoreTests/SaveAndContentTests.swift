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

    func testThreeMainStagesPlusBonusCellar() {
        let world = World.paperMoon
        XCTAssertEqual(world.mainStages.count, 3, "본편은 세 장면")
        XCTAssertEqual(world.bonusStages.count, 1, "보너스 장면은 지하실 하나")
        XCTAssertEqual(world.stages.count, 4)
        for stage in world.stages {
            XCTAssertEqual(stage.rooms.count, 3, "\(stage.id) 방 개수")
            XCTAssertEqual(stage.isBonus, stage.id.isBonus, "\(stage.id) 보너스 표시")
            for roomID in stage.rooms {
                XCTAssertNotNil(world.room(roomID))
                XCTAssertGreaterThanOrEqual(world.hotspots(in: roomID).count, 3, "\(roomID) 지점 개수")
            }
        }
    }

    func testEveryStageHasItsPuzzles() {
        let world = World.paperMoon
        for stage in world.stages {
            XCTAssertGreaterThanOrEqual(world.puzzles(in: stage.id).count, 1, "\(stage.id) 퍼즐이 없다")
        }
        XCTAssertTrue(world.puzzles(in: .attic).contains { $0.id == .toyBlocks })
        XCTAssertTrue(world.puzzles(in: .attic).contains { $0.id == .paperMoonOrigami })
        XCTAssertTrue(world.puzzles(in: .greenhouse).contains { $0.id == .frogSong })
        XCTAssertTrue(world.puzzles(in: .greenhouse).contains { $0.id == .tornPaperCode })
        XCTAssertTrue(world.puzzles(in: .clocktower).contains { $0.id == .gearDials })
        XCTAssertTrue(world.puzzles(in: .cellar).contains { $0.id == .cellarBoat })
        XCTAssertTrue(world.puzzles(in: .cellar).contains { $0.id == .cellarVaultCode })
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

    func testAllFiveCombosExist() {
        let world = World.paperMoon
        XCTAssertEqual(world.combos.count, 5)
        XCTAssertNotNil(world.combo(.keyShardOval, .keyShardTooth))
        XCTAssertNotNil(world.combo(.brokenKey, .glueBottle))
        XCTAssertNotNil(world.combo(.emptyJar, .firefly))
        XCTAssertNotNil(world.combo(.windKey, .gear))
        XCTAssertNotNil(world.combo(.paperMoonLamp, .candleStub))
    }

    func testScrapbookHasTwelveCranesAcrossNineRooms() {
        let world = World.paperMoon
        let cranes = world.collectibles.filter { $0.kind == .crane }
        XCTAssertEqual(cranes.count, 12)
        XCTAssertEqual(Set(cranes.map { $0.room }).count, 9, "본편 9개 방 모두에 종이학이 있다")
        XCTAssertEqual(world.collectibles.filter { $0.kind == .stamp }.count, 3)
        for collectible in world.collectibles {
            XCTAssertFalse(collectible.memory.isEmpty, "\(collectible.id) 기억이 비었다")
            XCTAssertNotNil(world.room(collectible.room))
        }
    }

    func testDustPanelsAreWiredToTheirRooms() {
        let world = World.paperMoon
        XCTAssertEqual(world.dustPanels.count, 2)
        for panel in world.dustPanels {
            XCTAssertNotNil(world.room(panel.room))
            XCTAssertFalse(panel.effects.isEmpty)
            XCTAssertFalse(panel.doneIf.isEmpty)
        }
        XCTAssertNotNil(world.dustPanel("tower.mirror"))
        XCTAssertNotNil(world.dustPanel("cellar.ledger"))
    }

    func testEveryHotspotWithCharacterGateNamesItsCharacter() {
        let world = World.paperMoon
        let gated = world.hotspots.filter { $0.requiredCharacter != nil }
        XCTAssertGreaterThanOrEqual(gated.count, 8, "캐릭터 협동 지점이 너무 적다")
        for hotspot in gated {
            XCTAssertNotNil(hotspot.characterNote, "\(hotspot.id)에 안내 대사가 없다")
        }
        XCTAssertTrue(gated.contains { $0.requiredCharacter == .momo })
        XCTAssertTrue(gated.contains { $0.requiredCharacter == .pico })
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
