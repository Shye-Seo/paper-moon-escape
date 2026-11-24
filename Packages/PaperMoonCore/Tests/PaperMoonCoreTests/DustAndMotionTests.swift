import XCTest
import PaperMoonCore

/// 먼지 문지르기 판과, 기기를 흔들거나 기울이는 입력.
final class DustWipeTests: XCTestCase {
    private func panel() -> DustPanel {
        DustPanel(
            id: "test.panel",
            room: .towerGears,
            title: "시험용 유리",
            prompt: "문질러 닦자",
            revealText: "글씨가 보인다",
            columns: 8,
            rows: 6,
            threshold: 0.7,
            effects: [.flag("test.wiped")]
        )
    }

    func testStartsCompletelyDusty() {
        let puzzle = DustWipePuzzle(panel: panel())
        XCTAssertEqual(puzzle.clearedRatio, 0, accuracy: 0.0001)
        XCTAssertEqual(puzzle.percent, 0)
        XCTAssertFalse(puzzle.isCleared)
        XCTAssertEqual(puzzle.dirt.count, 48)
        XCTAssertEqual(puzzle.dust(column: 0, row: 0), 1)
    }

    func testWipingLowersDustOnlyNearTheFinger() {
        var puzzle = DustWipePuzzle(panel: panel())
        puzzle.wipe(at: ScenePoint(0.1, 0.1), radius: 0.1)
        XCTAssertGreaterThan(puzzle.clearedRatio, 0)
        XCTAssertLessThan(puzzle.dust(column: 0, row: 0), 0.7)
        XCTAssertEqual(puzzle.dust(column: 7, row: 5), 1, "손이 닿지 않은 칸은 그대로다")
    }

    func testRepeatedWipingClearsThePanel() {
        var puzzle = DustWipePuzzle(panel: panel())
        var cleared = false
        for row in 0..<6 {
            for column in 0..<8 where !cleared {
                let point = ScenePoint(
                    (Double(column) + 0.5) / 8,
                    (Double(row) + 0.5) / 6
                )
                cleared = puzzle.wipe(at: point, radius: 0.22)
            }
        }
        XCTAssertTrue(cleared)
        XCTAssertTrue(puzzle.isCleared)
        XCTAssertGreaterThanOrEqual(puzzle.clearedRatio, 0.7)
        XCTAssertGreaterThanOrEqual(puzzle.percent, 70)
    }

    func testOneSwipeIsNotEnough() {
        var puzzle = DustWipePuzzle(panel: panel())
        let cleared = puzzle.wipe(at: ScenePoint(0.5, 0.5), radius: 0.2)
        XCTAssertFalse(cleared)
        XCTAssertLessThan(puzzle.clearedRatio, 0.3)
    }

    func testShakeClearsLessThanASwipeButStillHelps() {
        var puzzle = DustWipePuzzle(panel: panel())
        _ = puzzle.shake()
        let afterOne = puzzle.clearedRatio
        XCTAssertGreaterThan(afterOne, 0)
        XCTAssertLessThan(afterOne, 0.15)

        for _ in 0..<20 {
            _ = puzzle.shake()
        }
        XCTAssertTrue(puzzle.isCleared, "흔들기만으로도 충분히 오래 하면 닦인다")
    }

    func testWipeAllIsTheAccessibilityAlternative() {
        var puzzle = DustWipePuzzle(panel: panel())
        XCTAssertTrue(puzzle.wipeAll())
        XCTAssertTrue(puzzle.isCleared)
        XCTAssertEqual(puzzle.clearedRatio, 1, accuracy: 0.0001)
    }
}

final class DustPanelRuleTests: XCTestCase {
    func testDustyMirrorOpensItsPanel() {
        let engine = TestHelp.engine(at: .towerGears, stage: .clocktower)
        let events = engine.tap(.dustyMirror)
        XCTAssertTrue(events.contains(.dustPanelOpened("tower.mirror")))
        XCTAssertFalse(engine.state.flags.contains(Flags.mirrorWiped))
    }

    func testFinishingPanelRevealsTheClue() {
        let engine = TestHelp.engine(at: .towerGears, stage: .clocktower)
        let events = engine.completeDustPanel("tower.mirror")
        XCTAssertTrue(events.contains(.dustCleared("tower.mirror")))
        XCTAssertTrue(engine.state.flags.contains(Flags.mirrorWiped))
        XCTAssertTrue(TestHelp.hasLine(events, containing: "종 아래 홈"))
    }

    func testWipedMirrorLeavesTheScene() {
        let engine = TestHelp.engine(at: .towerGears, stage: .clocktower)
        _ = engine.completeDustPanel("tower.mirror")
        XCTAssertFalse(engine.visibleHotspots().contains { $0.id == .dustyMirror })
    }

    func testFinishingPanelTwiceDoesNotRepeatRewards() {
        let engine = TestHelp.engine(at: .towerGears, stage: .clocktower)
        _ = engine.completeDustPanel("tower.mirror")
        let again = engine.completeDustPanel("tower.mirror")
        XCTAssertFalse(again.contains(.dustCleared("tower.mirror")))
        XCTAssertTrue(TestHelp.hasLine(again, containing: "이미 다 닦아"))
    }

    func testPanelFromAnotherRoomIsRejected() {
        let engine = TestHelp.engine(at: .cellarVault, stage: .cellar, flags: [Flags.vaultCodeSeen])
        let events = engine.completeDustPanel("tower.mirror")
        XCTAssertTrue(TestHelp.hasBlocked(events))
    }

    func testBellStaysBlockedUntilMirrorIsWiped() {
        let dusty = TestHelp.engine(
            at: .towerBelfry,
            stage: .clocktower,
            inventory: [.paperMoonShard],
            flags: [Flags.clockWound]
        )
        _ = dusty.tapInventoryItem(.paperMoonShard)
        let blocked = dusty.tap(.paperBell)
        XCTAssertTrue(TestHelp.hasLine(blocked, containing: "먼지"))
        XCTAssertFalse(dusty.state.clearedStages.contains(.clocktower))
        XCTAssertTrue(dusty.state.inventory.contains(.paperMoonShard))

        let wiped = TestHelp.engine(
            at: .towerBelfry,
            stage: .clocktower,
            inventory: [.paperMoonShard],
            flags: [Flags.clockWound, Flags.mirrorWiped]
        )
        _ = wiped.tapInventoryItem(.paperMoonShard)
        let opened = wiped.tap(.paperBell)
        XCTAssertTrue(opened.contains(.stageCleared(.clocktower)))
    }

    func testCellarLedgerPanelRevealsItsLine() {
        let engine = TestHelp.engine(
            at: .cellarVault,
            stage: .cellar,
            flags: [Flags.vaultCodeSeen],
            cleared: [.attic, .greenhouse, .clocktower]
        )
        let events = engine.completeDustPanel("cellar.ledger")
        XCTAssertTrue(events.contains(.dustCleared("cellar.ledger")))
        XCTAssertTrue(engine.state.flags.contains(Flags.cellarLedgerRead))
    }
}

final class MotionInputTests: XCTestCase {
    func testCalmDeviceProducesNothing() {
        var input = MotionInput()
        XCTAssertEqual(input.feed(accelerationX: 0, y: 0, z: 1, at: 1), .none)
        XCTAssertEqual(input.shakes, 0)
        XCTAssertFalse(input.isTilted)
    }

    func testShakeIsDetectedOnceInsideCooldown() {
        var input = MotionInput()
        XCTAssertEqual(input.feed(accelerationX: 3.2, y: 0.4, z: 0.8, at: 10), .shake)
        XCTAssertEqual(input.shakes, 1)
        XCTAssertEqual(input.feed(accelerationX: 3.2, y: 0.4, z: 0.8, at: 10.2), .none)
        XCTAssertEqual(input.shakes, 1)
        XCTAssertEqual(input.feed(accelerationX: 3.0, y: 0, z: 0, at: 11), .shake)
        XCTAssertEqual(input.shakes, 2)
    }

    func testTiltIsNormalizedToBeamOffset() {
        var input = MotionInput(tiltRange: 0.55)
        XCTAssertEqual(input.feedTilt(roll: 0.275, pitch: 0), .tilt)
        XCTAssertEqual(input.beamOffsetX, 0.5, accuracy: 0.001)
        XCTAssertTrue(input.isTilted)

        input.feedTilt(roll: 5, pitch: -5)
        XCTAssertEqual(input.beamOffsetX, 1, accuracy: 0.001)
        XCTAssertEqual(input.beamOffsetY, -1, accuracy: 0.001)
    }

    func testSameTiltTwiceReportsNoChange() {
        var input = MotionInput()
        _ = input.feedTilt(roll: 0.2, pitch: 0.1)
        XCTAssertEqual(input.feedTilt(roll: 0.2, pitch: 0.1), .none)
    }

    func testResetClearsShakesAndTilt() {
        var input = MotionInput()
        _ = input.feed(accelerationX: 4, y: 4, z: 4, at: 5)
        _ = input.feedTilt(roll: 0.4, pitch: 0.2)
        input.reset()
        XCTAssertEqual(input.shakes, 0)
        XCTAssertEqual(input.beamOffsetX, 0, accuracy: 0.0001)
    }

    func testShakeDrivesDustPanelFaster() {
        var puzzle = DustWipePuzzle(columns: 6, rows: 6, threshold: 0.6)
        var input = MotionInput()
        var shakes = 0
        for step in 0..<200 {
            let time = Double(step) * 0.5
            if input.feed(accelerationX: 3.4, y: 0, z: 0, at: time) == .shake {
                shakes += 1
                if puzzle.shake() {
                    break
                }
            }
        }
        XCTAssertGreaterThan(shakes, 0)
        XCTAssertTrue(puzzle.isCleared)
    }
}
