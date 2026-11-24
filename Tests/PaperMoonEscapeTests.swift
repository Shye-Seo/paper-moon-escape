import XCTest
import PaperMoonCore

/// 앱 타깃 위에서 도는 통합 테스트.
/// 실제 플레이 순서를 그대로 따라가며 "이 게임은 끝까지 갈 수 있는가"를 확인한다.
final class PaperMoonEscapeIntegrationTests: XCTestCase {
    /// 탐색은 한 번에 안 나올 수 있다. 천장까지 더듬어 반드시 찾는다.
    private func search(_ engine: GameEngine, _ id: String) {
        let ceiling = World.paperMoon.searchSpot(id)?.maxAttempts ?? 1
        for _ in 0..<max(ceiling, 1) {
            let events = engine.search(id)
            let found = events.contains { event in
                if case .searchFound(let spot) = event { return spot == id }
                return false
            }
            if found { return }
        }
    }

    private func runAdventure(hints: Bool = false) -> GameEngine {
        let engine = GameEngine(world: .paperMoon)

        // 1장 · 다락방 — 종이접기, 캐릭터 전환, 초와 등불
        _ = engine.tap(.rockingHorse)
        _ = engine.tap(.owlClock)
        search(engine, "attic.highShelf")       // 모모만 닿는 높은 선반을 더듬는다
        _ = engine.moveRight()
        _ = engine.tap(.foldingDesk)
        _ = engine.solvePuzzle(.paperMoonOrigami, answer: [0, 2, 1, 3])
        _ = engine.setCharacter(.pico)
        search(engine, "attic.mouseHole")       // 피코만 들어가는 쥐구멍을 더듬는다
        _ = engine.setCharacter(.momo)
        _ = engine.combine(.paperMoonLamp, .candleStub)
        _ = engine.tap(.toyBox)
        _ = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        _ = engine.combine(.keyShardOval, .keyShardTooth)
        _ = engine.combine(.brokenKey, .glueBottle)
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.mendedKey)
        _ = engine.tap(.moonLatch)

        // 2장 · 온실 — 반딧불이와 개구리는 피코의 일
        _ = engine.tap(.seedPouch)
        _ = engine.tap(.wateringCanCorner)
        _ = engine.moveRight()
        search(engine, "greenhouse.pondShelf")
        _ = engine.setCharacter(.pico)
        search(engine, "greenhouse.firefly")
        _ = engine.combine(.emptyJar, .firefly)
        _ = engine.tap(.frogChorus)
        _ = engine.solvePuzzle(.frogSong, answer: [3, 1, 4, 2])
        _ = engine.moveRight()
        _ = engine.tap(.tornPaperWindow)        // 빛 투과 퍼즐
        _ = engine.solvePuzzle(.tornPaperCode, answer: [2, 0, 3, 1])
        _ = engine.tap(.moonShardBranch)
        _ = engine.moveRight()
        _ = engine.setCharacter(.momo)
        _ = engine.tapInventoryItem(.seed)
        _ = engine.tap(.flowerPot)
        _ = engine.tapInventoryItem(.wateringCan)
        _ = engine.tap(.flowerPot)
        _ = engine.tap(.vineGate)

        // 3장 · 시계탑 — 먼지 닦기
        _ = engine.tap(.woodBox)
        _ = engine.moveRight()
        _ = engine.tap(.dialPanel)
        _ = engine.solvePuzzle(.gearDials, answer: [0, 1, 3])
        search(engine, "tower.gearPile")
        _ = engine.combine(.windKey, .gear)
        _ = engine.tapInventoryItem(.clockPart)
        _ = engine.tap(.windSocket)
        _ = engine.tap(.dustyMirror)
        _ = engine.completeDustPanel("tower.mirror")
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.paperMoonShard)
        _ = engine.tap(.paperBell)

        if hints {
            _ = engine.requestHint()
        }

        return engine
    }

    func testAdventureRunsFromAtticToEnding() {
        let engine = runAdventure()
        XCTAssertTrue(engine.state.finished)
        XCTAssertEqual(engine.state.clearedStages, Set(StageID.mainline))
        XCTAssertEqual(engine.state.stage, .clocktower)
        XCTAssertEqual(engine.state.room, .towerBelfry)
        XCTAssertEqual(engine.summary().clearedStages, 3)
    }

    func testEveryMainHintObjectiveIsSatisfiedByTheWalkthrough() {
        let engine = runAdventure()
        let world = World.paperMoon
        for stage in world.mainStages {
            for hint in world.hints(in: stage.id) {
                XCTAssertTrue(
                    engine.state.satisfies(hint.doneIf),
                    "힌트 목표가 실제 플레이로 달성되지 않는다: \(hint.id)"
                )
            }
        }
    }

    func testEveryCellarHintObjectiveIsSatisfiedByTheCellarWalkthrough() {
        let engine = mainClearedEngineForCellar()
        _ = engine.start(stage: .cellar)
        _ = engine.tap(.oilLampHook)
        _ = engine.setCharacter(.pico)
        search(engine, "cellar.brickNook")
        _ = engine.setCharacter(.momo)
        _ = engine.tapInventoryItem(.rustyHandle)
        _ = engine.tap(.ironGateLatch)
        _ = engine.moveRight()
        _ = engine.tap(.paperCrate)
        _ = engine.tap(.foldingStool)
        _ = engine.solvePuzzle(.cellarBoat, answer: [1, 3, 0, 2])
        _ = engine.setCharacter(.pico)
        _ = engine.tap(.tornLabel)
        _ = engine.solvePuzzle(.cellarVaultCode, answer: [3, 1, 0, 2])
        _ = engine.tapInventoryItem(.paperBoat)
        _ = engine.tap(.floodedDrain)
        _ = engine.setCharacter(.momo)
        _ = engine.moveRight()
        _ = engine.tap(.vaultLedger)
        _ = engine.completeDustPanel("cellar.ledger")
        _ = engine.tapInventoryItem(.vaultKey)
        _ = engine.tap(.moonVault)

        let world = World.paperMoon
        for hint in world.hints(in: .cellar) {
            XCTAssertTrue(
                engine.state.satisfies(hint.doneIf),
                "지하실 힌트 목표가 달성되지 않는다: \(hint.id)"
            )
        }
        XCTAssertTrue(engine.state.clearedStages.contains(.cellar))
    }

    private func mainClearedEngineForCellar() -> GameEngine {
        let state = GameState(
            stage: .cellar,
            room: .cellarSteps,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            clearedStages: Set(StageID.mainline)
        )
        return GameEngine(world: .paperMoon, state: state, entitlements: .full)
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

        // 보너스 지하실은 손잡이 → 암호 순서로 문이 열린다.
        XCTAssertEqual(world.room(.cellarPantry)?.lock?.requirement, .flag(Flags.cellarGateOpen))
        XCTAssertEqual(world.room(.cellarVault)?.lock?.requirement, .flag(Flags.vaultCodeSeen))
    }

    func testEndingSummaryMatchesPlayedActions() {
        let engine = runAdventure()
        let summary = engine.summary()
        XCTAssertEqual(summary.craftedCount, 5)
        XCTAssertEqual(summary.hintsUsed, 0)
        XCTAssertEqual(summary.clearedStages, 3)
    }

    func testSaveAndResumeKeepsRoomAndProgress() {
        let store = InMemorySaveStore()
        let first = GameEngine(world: .paperMoon, store: store)
        _ = first.tap(.rockingHorse)
        _ = first.moveRight()
        _ = first.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])
        _ = first.toggleCharacter()

        let resumed = GameEngine(world: .paperMoon, store: store)
        XCTAssertEqual(resumed.state.room, .atticToyCloset)
        XCTAssertTrue(resumed.state.solvedPuzzles.contains(.toyBlocks))
        XCTAssertTrue(resumed.state.inventory.contains(.keyShardTooth))
        XCTAssertEqual(resumed.state.activeCharacter, .pico)
    }

    // MARK: 유료 구조

    func testTrialBuildStopsAtTheSecondStageDoor() {
        let engine = TestEngine.trial(at: .atticMoonWindow, inventory: [.mendedKey], flags: [Flags.lampLit])
        _ = engine.tapInventoryItem(.mendedKey)
        let events = engine.tap(.moonLatch)
        XCTAssertTrue(events.contains(.stageCleared(.attic)))
        XCTAssertEqual(engine.state.stage, .attic)
        XCTAssertFalse(engine.canEnter(stage: .greenhouse))
        XCTAssertFalse(engine.canEnter(stage: .cellar))
    }

    func testStoreProductsMatchTheStoreKitConfiguration() {
        // Products.storekit의 상품 식별자와 Core의 상품 식별자가 어긋나면 결제가 실패한다.
        for product in StoreProduct.allCases {
            XCTAssertTrue(product.rawValue.hasPrefix("com.quoguri.papermooneescape."))
        }
        XCTAssertEqual(StoreProduct.fullUnlock.priceWon + StoreProduct.cellarChapter.priceWon + StoreProduct.hintPass.priceWon, 9300)
    }

    func testCraneHuntEndsWithTheSecretDrawer() {
        var collected = Set<CollectibleID>()
        let state = GameState(
            stage: .attic,
            room: .atticLanding,
            inventory: [.lantern],
            flags: [Flags.clockWound],
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            clearedStages: Set(StageID.mainline)
        )
        let engine = GameEngine(world: .paperMoon, state: state)
        for stageID in StageID.mainline {
            _ = engine.start(stage: stageID)
            for _ in 0..<3 {
                for collectible in engine.visibleCollectibles where collectible.kind == .crane {
                    _ = engine.collect(collectible.id)
                    collected.insert(collectible.id)
                }
                // 탐색으로만 나오는 종이학은 방을 더듬어 찾는다. 커튼은 먼저 살펴야 한다.
                _ = engine.tap(.curtain)
                for spot in engine.visibleSearches() {
                    search(engine, spot.id)
                    if let collectible = spot.rewardCollectible {
                        collected.insert(collectible)
                    }
                }
                _ = engine.moveRight()
            }
        }
        XCTAssertEqual(collected.count, 12)
        XCTAssertTrue(engine.state.hasAllCranes)
        let events = engine.openSecretDrawer()
        XCTAssertTrue(events.contains(.secretDrawerOpened(World.paperMoon.secretGift)))
    }
}

/// 앱 테스트에서 쓰는 작은 엔진 도우미.
enum TestEngine {
    static func trial(
        at room: RoomID,
        inventory: [ItemID] = [],
        flags: Set<String> = []
    ) -> GameEngine {
        let state = GameState(
            stage: .attic,
            room: room,
            inventory: inventory,
            flags: flags,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        return GameEngine(world: .paperMoon, state: state, entitlements: .trial)
    }
}
