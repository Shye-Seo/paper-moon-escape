import XCTest
import PaperMoonCore

/// 유료결제(IAP) 구조 — 상품, 잠금, 힌트 패스, 그리고 보너스 지하실.
final class StoreProductTests: XCTestCase {
    func testThreeProductsWithWonPrices() {
        XCTAssertEqual(StoreProduct.allCases.count, 3)
        XCTAssertEqual(StoreProduct.fullUnlock.priceWon, 4900)
        XCTAssertEqual(StoreProduct.cellarChapter.priceWon, 2900)
        XCTAssertEqual(StoreProduct.hintPass.priceWon, 1500)
        XCTAssertEqual(StoreProduct.fullUnlock.rawValue, "com.quoguri.papermooneescape.fullunlock")
        XCTAssertEqual(StoreProduct.cellarChapter.rawValue, "com.quoguri.papermooneescape.cellarchapter")
        XCTAssertEqual(StoreProduct.hintPass.rawValue, "com.quoguri.papermooneescape.hintspass")
        for product in StoreProduct.allCases {
            XCTAssertFalse(product.summary.isEmpty)
            XCTAssertFalse(product.title.isEmpty)
            XCTAssertTrue(product.priceText.contains("₩"))
        }
    }

    func testEntitlementsStartEmptyForTrial() {
        let trial = Entitlements.trial
        XCTAssertTrue(trial.isEmpty)
        XCTAssertFalse(trial.has(.fullUnlock))
        XCTAssertFalse(trial.has(.cellarChapter))
        XCTAssertFalse(trial.has(.hintPass))
        XCTAssertEqual(trial.summaryText, "무료 체험 중 · 1장면")
    }

    func testApplyingProductsUnlocksThem() {
        var bought = Entitlements()
        bought.apply(.fullUnlock)
        XCTAssertTrue(bought.has(.fullUnlock))
        XCTAssertFalse(bought.has(.cellarChapter))
        bought.apply(.cellarChapter)
        bought.apply(.hintPass)
        XCTAssertEqual(bought.purchasedProducts, StoreProduct.allCases)
        XCTAssertTrue(bought.has(.cellarChapter))
    }

    func testCellarProductNeedsBaseGame() {
        let cellarOnly = Entitlements(fullUnlock: false, cellarChapter: true, hintPass: false)
        XCTAssertFalse(cellarOnly.has(.cellarChapter), "지하실은 본편 위에서만 열린다")
    }
}

final class StageLockTests: XCTestCase {
    func testTrialOnlyOpensFirstStage() {
        let engine = GameEngine(world: .paperMoon, entitlements: .trial)
        XCTAssertTrue(engine.canEnter(stage: .attic))
        XCTAssertFalse(engine.canEnter(stage: .greenhouse))
        XCTAssertFalse(engine.canEnter(stage: .clocktower))
        XCTAssertFalse(engine.canEnter(stage: .cellar))
        XCTAssertEqual(
            engine.lockReason(for: .greenhouse),
            "본편 전체 잠금해제 · ₩4,900"
        )
    }

    func testTrialAsksForFullUnlockWhenStartingLaterStage() {
        let engine = GameEngine(world: .paperMoon, entitlements: .trial)
        let events = engine.start(stage: .greenhouse)
        XCTAssertTrue(events.contains { event in
            if case .purchaseRequired(.fullUnlock, _) = event { return true }
            return false
        })
        XCTAssertEqual(engine.state.stage, .attic)
    }

    func testTrialClearingAtticShowsPaywallInsteadOfStageTwo() {
        let engine = TestHelp.engine(
            at: .atticMoonWindow,
            stage: .attic,
            inventory: [.mendedKey],
            flags: [Flags.lampLit],
            entitlements: .trial
        )
        _ = engine.tapInventoryItem(.mendedKey)
        let events = engine.tap(.moonLatch)
        XCTAssertTrue(events.contains(.stageCleared(.attic)))
        XCTAssertTrue(events.contains { event in
            if case .purchaseRequired(.fullUnlock, _) = event { return true }
            return false
        })
        XCTAssertEqual(engine.state.stage, .attic, "구매 전에는 2장면으로 넘어가지 않는다")
        XCTAssertFalse(events.contains(.stageStarted(.greenhouse)))
    }

    func testFullUnlockOpensStageTwoAfterAttic() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            cleared: [.attic],
            entitlements: .full
        )
        XCTAssertTrue(engine.canEnter(stage: .greenhouse))
        XCTAssertEqual(engine.lockReason(for: .greenhouse), nil)
        _ = engine.start(stage: .greenhouse)
        XCTAssertEqual(engine.state.stage, .greenhouse)
    }

    func testFullUnlockStillNeedsPreviousStageCleared() {
        let engine = GameEngine(world: .paperMoon, entitlements: Entitlements(fullUnlock: true))
        XCTAssertFalse(engine.canEnter(stage: .clocktower))
        XCTAssertEqual(engine.lockReason(for: .clocktower), "앞 장면을 먼저 깨야 한다.")
    }

    func testBuyingMidSessionUnlocksTheNextStage() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            cleared: [.attic],
            entitlements: .trial
        )
        XCTAssertFalse(engine.canEnter(stage: .greenhouse))
        engine.setEntitlements(Entitlements(fullUnlock: true))
        XCTAssertTrue(engine.canEnter(stage: .greenhouse))
    }
}

final class HintPassTests: XCTestCase {
    private func spendThreeFreeHints(_ engine: GameEngine) {
        _ = engine.tap(.rockingHorse)
        _ = engine.requestHint()
        _ = engine.tap(.owlClock)
        _ = engine.requestHint()
        TestHelp.searchUntilFound(engine, "attic.highShelf")
        _ = engine.requestHint()
    }

    private func hasPurchaseRequest(_ events: [GameEvent], _ product: StoreProduct) -> Bool {
        events.contains { event in
            if case .purchaseRequired(let requested, _) = event { return requested == product }
            return false
        }
    }

    func testFreeHintsRunOutWithoutPass() {
        let engine = GameEngine(world: .paperMoon, entitlements: .trial)
        spendThreeFreeHints(engine)
        XCTAssertEqual(engine.state.hintsUsed, Entitlements.freeHintAllowance)
        XCTAssertEqual(engine.hintsRemaining, 0)

        let events = engine.requestHint()
        XCTAssertTrue(hasPurchaseRequest(events, .hintPass))
        XCTAssertEqual(engine.state.hintsUsed, Entitlements.freeHintAllowance)
        XCTAssertFalse(events.contains { event in
            if case .hint = event { return true }
            return false
        })
    }

    func testHintPassKeepsHintsComing() {
        let engine = GameEngine(world: .paperMoon, entitlements: .full)
        spendThreeFreeHints(engine)
        XCTAssertNil(engine.hintsRemaining)
        let events = engine.requestHint()
        XCTAssertTrue(events.contains { event in
            if case .hint = event { return true }
            return false
        })
        XCTAssertEqual(engine.state.hintsUsed, Entitlements.freeHintAllowance + 1)
    }
}

final class CellarChapterTests: XCTestCase {
    func testCellarNeedsMainStoryCleared() {
        let engine = GameEngine(world: .paperMoon, entitlements: .full)
        XCTAssertFalse(engine.canEnter(stage: .cellar))
        XCTAssertEqual(engine.lockReason(for: .cellar), "본편을 끝내면 열리는 보너스 장면이다.")
    }

    func testCellarNeedsItsProduct() {
        let engine = TestHelp.engine(
            at: .towerBelfry,
            stage: .clocktower,
            cleared: [.attic, .greenhouse, .clocktower],
            entitlements: Entitlements(fullUnlock: true)
        )
        XCTAssertFalse(engine.canEnter(stage: .cellar))
        let events = engine.start(stage: .cellar)
        XCTAssertTrue(events.contains { event in
            if case .purchaseRequired(.cellarChapter, _) = event { return true }
            return false
        })
        XCTAssertEqual(engine.state.stage, .clocktower)
    }

    func testBoughtCellarOpensAfterMainStory() {
        let engine = TestHelp.engine(
            at: .towerBelfry,
            stage: .clocktower,
            cleared: [.attic, .greenhouse, .clocktower],
            entitlements: .full
        )
        XCTAssertTrue(engine.canEnter(stage: .cellar))
        _ = engine.start(stage: .cellar)
        XCTAssertEqual(engine.state.stage, .cellar)
        XCTAssertEqual(engine.state.room, .cellarSteps)
        XCTAssertTrue(engine.state.clearedStages.contains(.clocktower), "본편 기록은 그대로 남는다")
    }

    func testCellarPantryIsLockedUntilGateOpens() {
        let engine = TestHelp.engine(
            at: .cellarSteps,
            stage: .cellar,
            cleared: [.attic, .greenhouse, .clocktower]
        )
        let events = engine.moveRight()
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertEqual(engine.state.room, .cellarSteps)
    }

    func testRustyHandleOpensTheIronGate() {
        let engine = TestHelp.engine(
            at: .cellarSteps,
            stage: .cellar,
            inventory: [.rustyHandle],
            cleared: [.attic, .greenhouse, .clocktower]
        )
        _ = engine.tapInventoryItem(.rustyHandle)
        let events = engine.tap(.ironGateLatch)
        XCTAssertTrue(engine.state.flags.contains(Flags.cellarGateOpen))
        XCTAssertFalse(engine.state.inventory.contains(.rustyHandle), "손잡이는 문에 붙는다")
        XCTAssertTrue(TestHelp.hasLine(events, containing: "철문"))
        XCTAssertEqual(engine.moveRight().contains(.roomChanged(.cellarPantry)), true)
    }

    func testFullCellarPlaythroughReachesItsEnding() {
        let engine = Playthrough.runCellar()
        XCTAssertTrue(engine.state.clearedStages.contains(.cellar))
        XCTAssertEqual(engine.state.stage, .cellar)
        XCTAssertEqual(engine.state.room, .cellarVault)
        XCTAssertEqual(engine.state.clearedStages.count, 4)
        XCTAssertTrue(engine.state.solvedPuzzles.contains(.cellarBoat))
        XCTAssertTrue(engine.state.solvedPuzzles.contains(.cellarVaultCode))
        XCTAssertFalse(engine.state.inventory.contains(.vaultKey))
    }

    func testCellarEndingIsItsOwnEvent() {
        let engine = TestHelp.engine(
            at: .cellarVault,
            stage: .cellar,
            inventory: [.vaultKey],
            flags: [Flags.cellarGateOpen, Flags.vaultCodeSeen],
            cleared: [.attic, .greenhouse, .clocktower]
        )
        _ = engine.tapInventoryItem(.vaultKey)
        let events = engine.tap(.moonVault)
        let hasBonusEnding = events.contains { event in
            if case .bonusEnding(.cellar, _) = event { return true }
            return false
        }
        XCTAssertTrue(hasBonusEnding)
        XCTAssertFalse(events.contains { event in
            if case .finished = event { return true }
            return false
        }, "보너스 엔딩이 본편 엔딩을 덮어쓰면 안 된다")
        XCTAssertTrue(engine.state.clearedStages.contains(.cellar))
    }

    func testCellarVaultIsLockedUntilCodeIsRead() {
        let engine = TestHelp.engine(
            at: .cellarPantry,
            stage: .cellar,
            inventory: [.vaultKey],
            flags: [Flags.cellarGateOpen],
            cleared: [.attic, .greenhouse, .clocktower]
        )
        let events = engine.moveRight()
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertEqual(engine.state.room, .cellarPantry)
    }

    func testCellarHasNoCollectiblesSoPlayersAreNotPenalised() {
        let world = World.paperMoon
        for room in [RoomID.cellarSteps, .cellarPantry, .cellarVault] {
            XCTAssertTrue(world.collectibles(in: room).isEmpty)
        }
    }

    func testBonusStageIsMarkedAndHasNoNextStage() {
        let cellar = World.paperMoon.stage(.cellar)
        XCTAssertEqual(cellar?.isBonus, true)
        XCTAssertNil(cellar?.next)
        XCTAssertEqual(cellar?.rooms.count, 3)
    }
}
