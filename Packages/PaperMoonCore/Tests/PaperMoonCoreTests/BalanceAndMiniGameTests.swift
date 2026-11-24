import XCTest
@testable import PaperMoonCore

/// 탐색 확률·천장, 종이접기 실수 페널티, 빛 투과 정렬, 놀이방 두 놀이.
final class SearchTests: XCTestCase {
    private var world: World { .paperMoon }

    func testEverySearchSpotHasAGuaranteedCeiling() {
        XCTAssertGreaterThanOrEqual(world.searchSpots.count, 8, "탐색 지점이 너무 적다")
        for spot in world.searchSpots {
            XCTAssertEqual(spot.odds.last, 1.0, "\(spot.id)의 마지막 확률이 1.0이 아니다")
            XCTAssertGreaterThanOrEqual(spot.maxAttempts, 2)
            XCTAssertLessThanOrEqual(spot.maxAttempts, 6)
            XCTAssertFalse(spot.observations.isEmpty, "\(spot.id)에 관찰 문장이 없다")
            XCTAssertEqual(spot.chance(afterFailures: spot.maxAttempts), 1.0)
            XCTAssertEqual(spot.chance(afterFailures: spot.maxAttempts + 3), 1.0)
        }
    }

    func testOddsClimbTowardTheCeiling() {
        for spot in world.searchSpots {
            for (index, odd) in spot.odds.enumerated() where index > 0 {
                XCTAssertGreaterThanOrEqual(odd, spot.odds[index - 1], "\(spot.id)의 확률이 내려간다")
            }
        }
    }

    func testWorstLuckStillFindsSomethingAtTheCeiling() {
        // 주사위가 항상 빗나가는 최악의 운. 천장 규칙만이 발견을 보장한다.
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            random: { 0.999 }
        )
        let spot = try? XCTUnwrap(world.searchSpot("attic.highShelf"))
        guard let spot else { return XCTFail("탐색 지점이 없다") }

        for attempt in 1..<spot.maxAttempts {
            let events = engine.search(spot.id)
            XCTAssertTrue(events.contains(.searchMissed(spot.id, attempt: attempt, ceiling: spot.maxAttempts)))
            XCTAssertFalse(TestHelp.hasItemAdded(events, .paperSheet))
            XCTAssertEqual(engine.searchTries(spot.id), attempt)
        }
        let last = engine.search(spot.id)
        XCTAssertTrue(TestHelp.hasSearchFound(last, spot.id))
        XCTAssertTrue(engine.state.inventory.contains(.paperSheet))
        XCTAssertEqual(engine.searchTries(spot.id), spot.maxAttempts)
    }

    func testALuckyRollFindsItOnTheFirstTry() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            random: { 0.0 }
        )
        let events = engine.search("attic.highShelf")
        XCTAssertTrue(TestHelp.hasSearchFound(events, "attic.highShelf"))
        XCTAssertEqual(engine.searchTries("attic.highShelf"), 1)
    }

    func testAMissShowsAnObservationSentence() {
        let engine = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            character: .pico,
            random: { 0.99 }
        )
        let events = engine.search("attic.mouseHole")
        XCTAssertTrue(TestHelp.hasSearchMissed(events))
        XCTAssertTrue(TestHelp.hasLine(events, containing: "앞발"))
        XCTAssertFalse(engine.state.inventory.contains(.candleStub))
    }

    func testFoundSpotDoesNotGiveTheItemTwice() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            random: { 0.0 }
        )
        _ = engine.search("attic.highShelf")
        let again = engine.search("attic.highShelf")
        XCTAssertFalse(TestHelp.hasSearchFound(again, "attic.highShelf"))
        XCTAssertEqual(engine.state.inventory.filter { $0 == .paperSheet }.count, 1)
        XCTAssertTrue(TestHelp.hasLine(again, containing: "먼지 자국"))
        XCTAssertFalse(engine.visibleSearches().contains { $0.id == "attic.highShelf" })
    }

    func testWrongCharacterCannotSearch() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            character: .pico
        )
        let events = engine.search("attic.highShelf")
        XCTAssertTrue(TestHelp.hasLine(events, containing: "높다"))
        XCTAssertEqual(engine.searchTries("attic.highShelf"), 0)
        XCTAssertTrue(engine.state.inventory.isEmpty)
    }

    func testToolRequirementGatesTheDeepestFind() {
        let withoutLantern = TestHelp.engine(at: .greenhousePond, stage: .greenhouse)
        let blocked = withoutLantern.search("greenhouse.fireflyCrane")
        XCTAssertTrue(TestHelp.hasLine(blocked, containing: "빛"))
        XCTAssertEqual(withoutLantern.searchTries("greenhouse.fireflyCrane"), 0)

        let withLantern = TestHelp.engine(
            at: .greenhousePond,
            stage: .greenhouse,
            inventory: [.lantern],
            random: { 0.0 }
        )
        let found = withLantern.search("greenhouse.fireflyCrane")
        XCTAssertTrue(TestHelperCollectible.hasCollectible(found, .craneFirefly))
        XCTAssertTrue(withLantern.state.hasCollected(.craneFirefly))
    }

    func testSearchOnlyCollectiblesCannotBeTappedFromTheScene() {
        let engine = TestHelp.engine(at: .atticToyCloset, stage: .attic)
        XCTAssertFalse(engine.visibleCollectibles.contains { $0.id == .craneToyShelf })
        XCTAssertTrue(engine.visibleSearches().contains { $0.id == "attic.toyShelfCrane" })

        let events = engine.collect(.craneToyShelf)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "꼼꼼히"))
        XCTAssertFalse(engine.state.hasCollected(.craneToyShelf))
    }

    func testDeepSearchCranesArePartOfTheTwelve() {
        let searchCranes = world.searchOnlyCollectibles.filter { $0.kind == .crane }
        XCTAssertEqual(searchCranes.count, 3)
        XCTAssertEqual(world.searchOnlyCollectibles.filter { $0.kind == .stamp }.count, 1)
        XCTAssertEqual(world.collectibles.filter { $0.kind == .crane }.count, 12)
    }

    func testCraneHuntStillCollectsAllTwelveWithUnluckyRolls() {
        let engine = Playthrough.collectAllCranes()
        XCTAssertEqual(engine.state.collectedCranes, 12)
    }

    func testSearchNeedsThePuzzleFirst() {
        let engine = TestHelp.engine(at: .towerGears, stage: .clocktower)
        let blocked = engine.search("tower.gearPile")
        XCTAssertTrue(TestHelp.hasLine(blocked, containing: "다이얼"))
        XCTAssertFalse(engine.state.inventory.contains(.gear))

        _ = engine.solvePuzzle(.gearDials, answer: [0, 1, 3])
        let found = TestHelp.searchUntilFound(engine, "tower.gearPile")
        XCTAssertTrue(TestHelp.hasItemAdded(found, .gear))
    }

    func testObservationCanGateADeepSearch() {
        let engine = TestHelp.engine(
            at: .atticMoonWindow,
            stage: .attic,
            random: { 0.0 }
        )
        let blocked = engine.search("attic.curtainCrane")
        XCTAssertTrue(TestHelp.hasLine(blocked, containing: "커튼"))
        XCTAssertEqual(engine.searchTries("attic.curtainCrane"), 0)

        _ = engine.tap(.curtain)   // 커튼을 살펴 단서를 본다
        XCTAssertTrue(engine.state.flags.contains(Flags.readCurtainNote))
        let found = engine.search("attic.curtainCrane")
        XCTAssertTrue(TestHelperCollectible.hasCollectible(found, .craneMoonWindow))
    }

    func testSearchInAnotherRoomIsBlocked() {
        let engine = TestHelp.engine(at: .atticLanding, stage: .attic)
        let events = engine.search("cellar.brickNook")
        XCTAssertTrue(TestHelp.hasBlocked(events))
        XCTAssertEqual(engine.searchTries("cellar.brickNook"), 0)
    }

    func testSearchProgressSurvivesSave() {
        let store = InMemorySaveStore()
        let first = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            store: store,
            random: { 0.99 }
        )
        _ = first.search("attic.highShelf")
        XCTAssertEqual(first.searchTries("attic.highShelf"), 1)

        let restored = GameEngine(world: .paperMoon, state: store.load(), store: store)
        XCTAssertEqual(restored.searchTries("attic.highShelf"), 1)

        _ = TestHelp.searchUntilFound(restored, "attic.highShelf")
        XCTAssertTrue(restored.state.hasFound("attic.highShelf"))
        let saved = GameEngine(world: .paperMoon, state: store.load(), store: store)
        XCTAssertTrue(saved.state.hasFound("attic.highShelf"))
        XCTAssertTrue(saved.state.inventory.contains(.paperSheet))
    }

    func testResetStageClearsSearchProgress() {
        let engine = TestHelp.engine(
            at: .atticLanding,
            stage: .attic,
            random: { 0.0 }
        )
        _ = engine.search("attic.highShelf")
        XCTAssertTrue(engine.state.hasFound("attic.highShelf"))
        _ = engine.resetStage()
        XCTAssertFalse(engine.state.hasFound("attic.highShelf"))
        XCTAssertEqual(engine.searchTries("attic.highShelf"), 0)
        XCTAssertFalse(engine.state.inventory.contains(.paperSheet))
        XCTAssertFalse(engine.state.flags.contains(Flags.paperSheetTaken))
    }

    func testEveryStageHasSearchSpots() {
        for stage in world.stages {
            XCTAssertGreaterThanOrEqual(world.searchSpots(in: stage.id).count, 1, "\(stage.id)에 탐색 지점이 없다")
        }
        XCTAssertEqual(world.searchSpots.count, 10)
    }
}

enum TestHelperCollectible {
    static func hasCollectible(_ events: [GameEvent], _ id: CollectibleID) -> Bool {
        events.contains { event in
            if case .collectibleFound(let found) = event { return found == id }
            return false
        }
    }
}

final class FoldPenaltyTests: XCTestCase {
    private func engine() -> GameEngine {
        TestHelp.engine(at: .atticToyCloset, stage: .attic, inventory: [.paperSheet])
    }

    func testCorrectFoldsInOrderCompleteTheDesign() {
        let engine = engine()
        let steps = World.paperMoon.puzzle(.paperMoonOrigami)?.solution ?? []
        for (index, step) in steps.enumerated() {
            let events = engine.foldStep(.paperMoonOrigami, step: step)
            if index == steps.count - 1 {
                XCTAssertTrue(events.contains(.puzzleSolved(.paperMoonOrigami)))
            } else {
                XCTAssertTrue(events.contains(.foldAccepted(.paperMoonOrigami, position: index + 1)))
            }
        }
        XCTAssertTrue(engine.state.solvedPuzzles.contains(.paperMoonOrigami))
        XCTAssertTrue(engine.state.inventory.contains(.paperMoonLamp))
        XCTAssertTrue(engine.foldProgress(.paperMoonOrigami).isEmpty)
    }

    func testWrongFoldUnfoldsEverythingBackToTheStart() {
        let engine = engine()
        _ = engine.foldStep(.paperMoonOrigami, step: 0)          // 첫 접기는 맞다
        XCTAssertEqual(engine.foldProgress(.paperMoonOrigami), [0])

        let events = engine.foldStep(.paperMoonOrigami, step: 1) // 두 번째는 틀렸다(정답은 2)
        XCTAssertTrue(events.contains(.foldUnfolded(.paperMoonOrigami, attempts: 1)))
        XCTAssertTrue(engine.foldProgress(.paperMoonOrigami).isEmpty, "접힘이 전부 풀려야 한다")
        XCTAssertEqual(engine.state.attempts(for: .paperMoonOrigami), 1)
        XCTAssertFalse(engine.state.solvedPuzzles.contains(.paperMoonOrigami))
    }

    func testUnfoldTextTellsThePlayerToStartOver() {
        let engine = engine()
        _ = engine.foldStep(.paperMoonOrigami, step: 0)
        let events = engine.foldStep(.paperMoonOrigami, step: 3)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "다시"))
    }

    func testFoldingAfterSolvingIsIgnored() {
        let engine = engine()
        for step in World.paperMoon.puzzle(.paperMoonOrigami)?.solution ?? [] {
            _ = engine.foldStep(.paperMoonOrigami, step: step)
        }
        let events = engine.foldStep(.paperMoonOrigami, step: 0)
        XCTAssertTrue(TestHelp.hasLine(events, containing: "이미 다 접어"))
        XCTAssertEqual(engine.state.inventory.filter { $0 == .paperMoonLamp }.count, 1)
    }

    func testFoldsCanBeClearedByHand() {
        let engine = engine()
        _ = engine.foldStep(.paperMoonOrigami, step: 0)
        let events = engine.clearFolds(.paperMoonOrigami)
        XCTAssertTrue(events.contains(.foldCleared(.paperMoonOrigami)))
        XCTAssertTrue(engine.foldProgress(.paperMoonOrigami).isEmpty)
    }

    func testFoldProgressIsSavedWithTheGame() {
        let store = InMemorySaveStore()
        let first = TestHelp.engine(
            at: .atticToyCloset,
            stage: .attic,
            inventory: [.paperSheet],
            store: store
        )
        _ = first.foldStep(.paperMoonOrigami, step: 0)
        let restored = GameEngine(world: .paperMoon, state: store.load())
        XCTAssertEqual(restored.foldProgress(.paperMoonOrigami), [0])
    }

    func testCellarBoatAlsoUnfoldsOnAMistake() {
        let engine = TestHelp.engine(
            at: .cellarPantry,
            stage: .cellar,
            inventory: [.vellumPage],
            flags: [Flags.cellarGateOpen],
            cleared: [.attic, .greenhouse, .clocktower]
        )
        _ = engine.foldStep(.cellarBoat, step: 0)                // 정답은 1부터
        XCTAssertTrue(engine.foldProgress(.cellarBoat).isEmpty)
        XCTAssertEqual(engine.state.attempts(for: .cellarBoat), 1)
    }
}

final class LightReadoutTests: XCTestCase {
    private var puzzle: Puzzle? { World.paperMoon.puzzle(.tornPaperCode) }

    func testFullyAlignedPiecesMakeACrispCode() {
        guard let puzzle else { return XCTFail("퍼즐이 없다") }
        let readout = puzzle.lightReadout(for: puzzle.solution)
        XCTAssertEqual(readout.correct, 4)
        XCTAssertEqual(readout.total, 4)
        XCTAssertEqual(readout.clarity, 1.0)
        XCTAssertTrue(readout.isCrisp)
        XCTAssertEqual(readout.blurRadius, 0)
        XCTAssertEqual(readout.partialCode, puzzle.revealedCode)
    }

    func testOneWrongPieceBlursTheWholeCode() {
        guard let puzzle else { return XCTFail("퍼즐이 없다") }
        let answer = [puzzle.solution[0], puzzle.solution[1], puzzle.solution[2], 9]
        let readout = puzzle.lightReadout(for: answer)
        XCTAssertEqual(readout.correct, 3)
        XCTAssertEqual(readout.wrong, 1)
        XCTAssertFalse(readout.isCrisp)
        XCTAssertEqual(readout.clarity, 0.75, accuracy: 0.0001)
        XCTAssertGreaterThan(readout.blurRadius, 0)
        XCTAssertNotEqual(readout.partialCode, puzzle.revealedCode)
        XCTAssertTrue(readout.partialCode.contains("·"))
    }

    func testCompletelyMisalignedPiecesRevealAlmostNothing() {
        guard let puzzle else { return XCTFail("퍼즐이 없다") }
        let readout = puzzle.lightReadout(for: [0, 1, 2, 3])
        XCTAssertEqual(readout.correct, 0)
        XCTAssertEqual(readout.clarity, 0)
        XCTAssertFalse(readout.isCrisp)
        XCTAssertEqual(readout.blurRadius, 5.5)
        XCTAssertFalse(readout.partialCode.contains("달"))
    }

    func testEmptySlotsAreNotCrisp() {
        guard let puzzle else { return XCTFail("퍼즐이 없다") }
        let readout = puzzle.lightReadout(for: [])
        XCTAssertEqual(readout.filled, 0)
        XCTAssertFalse(readout.isCrisp)
        XCTAssertEqual(readout.correct, 0)
    }

    func testMaskingKeepsSpacesAndLength() {
        let text = "달은 나뭇가지 끝에서 잠깐 쉰다"
        let masked = Puzzle.masked(text, clarity: 0.5)
        XCTAssertEqual(masked.count, text.count)
        XCTAssertEqual(masked.filter { $0 == " " }.count, text.filter { $0 == " " }.count)
    }

    func testNonLightPuzzleReportsNoReadout() {
        guard let puzzle = World.paperMoon.puzzle(.toyBlocks) else { return XCTFail("퍼즐이 없다") }
        let readout = puzzle.lightReadout(for: puzzle.solution)
        XCTAssertFalse(readout.isCrisp)
        XCTAssertEqual(readout.clarity, 0)
    }
}

final class MemoryDrawerTests: XCTestCase {
    private func orderedDeck(_ count: Int) -> [MemoryFace] {
        Array(MemoryFace.deck.prefix(count))
    }

    func testCardCountFollowsDifficulty() {
        XCTAssertEqual(MiniGameDifficulty.easy.cardCount, 8)
        XCTAssertEqual(MiniGameDifficulty.normal.cardCount, 12)
        XCTAssertEqual(MiniGameDifficulty.hard.cardCount, 16)
        for difficulty in MiniGameDifficulty.allCases {
            let game = MemoryDrawerGame(difficulty: difficulty)
            XCTAssertEqual(game.cardCount, difficulty.cardCount)
            XCTAssertEqual(game.pairCount, difficulty.memoryPairs)
            XCTAssertEqual(game.perfectMoves, difficulty.memoryPairs)
        }
    }

    func testDeckUsesOnlyAtticItems() {
        XCTAssertEqual(MemoryFace.deck.count, 8)
        XCTAssertEqual(Set(MemoryFace.deck.map { $0.id }).count, 8)
        for face in MemoryFace.deck {
            XCTAssertFalse(face.name.isEmpty)
            XCTAssertFalse(face.glyph.isEmpty)
        }
    }

    func testMatchingCardsCloseTheDrawerInOneMove() {
        let deck = orderedDeck(4)
        let faces = [deck[0], deck[0], deck[1], deck[1]]
        var game = MemoryDrawerGame(difficulty: .easy, ordered: faces)
        XCTAssertEqual(game.flip(0), .revealed(index: 0))
        guard case .matched(let face, let moves) = game.flip(1) else {
            return XCTFail("짝이 맞아야 한다")
        }
        XCTAssertEqual(face.id, deck[0].id)
        XCTAssertEqual(moves, 1)
        XCTAssertEqual(game.matched, [0, 1])
        XCTAssertTrue(game.faceUp.isEmpty)
    }

    func testMismatchWaitsForResolve() {
        let deck = orderedDeck(4)
        let faces = [deck[0], deck[1], deck[0], deck[1]]
        var game = MemoryDrawerGame(difficulty: .easy, ordered: faces)
        _ = game.flip(0)
        guard case .mismatched(let first, let second, let moves) = game.flip(1) else {
            return XCTFail("어긋나야 한다")
        }
        XCTAssertEqual([first, second], [0, 1])
        XCTAssertEqual(moves, 1)
        XCTAssertEqual(game.faceUp, [0, 1])
        XCTAssertTrue(game.needsResolve)
        XCTAssertEqual(game.flip(2), .ignored)
        XCTAssertTrue(game.resolveMismatch())
        XCTAssertTrue(game.faceUp.isEmpty)
    }

    func testPerfectRunGetsThreeStars() {
        let deck = orderedDeck(4)
        var faces: [MemoryFace] = []
        for face in deck { faces.append(face); faces.append(face) }
        var game = MemoryDrawerGame(difficulty: .easy, ordered: faces)
        var index = 0
        while index < faces.count {
            _ = game.flip(index)
            _ = game.flip(index + 1)
            index += 2
        }
        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.moves, 4)
        XCTAssertEqual(game.stars, 3)
    }

    func testSloppyRunLosesStars() {
        let deck = orderedDeck(2)
        let faces = [deck[0], deck[0], deck[1], deck[1]]
        var game = MemoryDrawerGame(difficulty: .easy, ordered: faces)
        for _ in 0..<5 {
            _ = game.flip(0)
            _ = game.flip(2)
            _ = game.resolveMismatch()
        }
        _ = game.flip(0)
        _ = game.flip(1)
        _ = game.flip(2)
        _ = game.flip(3)
        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.moves, 7)
        XCTAssertEqual(game.stars, 2)
    }

    func testFinishedGameIgnoresFurtherFlips() {
        let deck = orderedDeck(2)
        let faces = [deck[0], deck[0], deck[1], deck[1]]
        var game = MemoryDrawerGame(difficulty: .easy, ordered: faces)
        _ = game.flip(0); _ = game.flip(1)
        _ = game.flip(2); _ = game.flip(3)
        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.flip(0), .ignored)
        XCTAssertEqual(game.moves, 2)
    }

    func testRecordsKeepTheBestMoves() {
        var records = MiniGameRecords()
        records.submitMemory(difficulty: .easy, moves: 9, seconds: 40, stars: 2, at: Date(timeIntervalSince1970: 10))
        let updated = records.submitMemory(difficulty: .easy, moves: 5, seconds: 55, stars: 3, at: Date(timeIntervalSince1970: 20))
        XCTAssertEqual(updated.plays, 2)
        XCTAssertEqual(updated.bestMoves, 5)
        XCTAssertEqual(updated.bestSeconds, 40)
        XCTAssertEqual(updated.stars, 3)
        XCTAssertEqual(records.record(for: .memoryDrawer, difficulty: .easy)?.bestMoves, 5)
        XCTAssertNil(records.record(for: .memoryDrawer, difficulty: .hard))
    }
}

final class OrigamiChallengeTests: XCTestCase {
    func testChainLengthFollowsDifficulty() {
        XCTAssertEqual(MiniGameDifficulty.easy.chainLength, 3)
        XCTAssertEqual(MiniGameDifficulty.normal.chainLength, 5)
        XCTAssertEqual(MiniGameDifficulty.hard.chainLength, 7)
        for difficulty in MiniGameDifficulty.allCases {
            let challenge = OrigamiChallenge(difficulty: difficulty)
            XCTAssertEqual(challenge.designs.count, difficulty.chainLength)
            XCTAssertEqual(challenge.mistakesLeft, difficulty.mistakeBudget)
            XCTAssertEqual(challenge.completed, 0)
            XCTAssertFalse(challenge.isOver)
        }
    }

    func testDesignsUseTheSameFourFoldsInDifferentOrders() {
        let orders = OrigamiDesign.all.map { $0.steps }
        XCTAssertEqual(orders.count, 4)
        XCTAssertEqual(Set(orders.map { $0.map { $0.rawValue } }).count, 4, "도안마다 순서가 달라야 한다")
        for design in OrigamiDesign.all {
            XCTAssertEqual(Set(design.steps.map { $0.rawValue }).count, 4)
            XCTAssertEqual(design.steps.count, 4)
        }
    }

    func testFoldingTheDesignMovesToTheNextOne() {
        var challenge = OrigamiChallenge(difficulty: .easy)
        guard let design = challenge.currentDesign else { return XCTFail("도안이 없다") }
        for (index, fold) in design.steps.enumerated() {
            let result = challenge.fold(fold)
            if index == design.steps.count - 1 {
                XCTAssertEqual(result, .designCompleted(completed: 1, next: challenge.designs[1]))
            } else {
                XCTAssertEqual(result, .accepted(placed: index + 1, remaining: design.steps.count - index - 1))
            }
        }
        XCTAssertEqual(challenge.completed, 1)
        XCTAssertEqual(challenge.index, 1)
        XCTAssertTrue(challenge.placed.isEmpty)
    }

    func testWrongFoldUnfoldsTheDesignAndSpendsAMistake() {
        var challenge = OrigamiChallenge(difficulty: .easy)
        guard let design = challenge.currentDesign else { return XCTFail("도안이 없다") }
        _ = challenge.fold(design.steps[0])
        let wrong = OrigamiFold.allCases.first { $0 != design.steps[1] } ?? .corners
        let result = challenge.fold(wrong)
        XCTAssertEqual(result, .unfolded(mistakesLeft: MiniGameDifficulty.easy.mistakeBudget - 1))
        XCTAssertTrue(challenge.placed.isEmpty, "잘못 접으면 그 도안은 처음부터")
        XCTAssertEqual(challenge.completed, 0)
        XCTAssertFalse(challenge.isOver)
    }

    func testRunningOutOfMistakesEndsTheChallenge() {
        var challenge = OrigamiChallenge(difficulty: .hard)
        guard let design = challenge.currentDesign else { return XCTFail("도안이 없다") }
        let wrong = OrigamiFold.allCases.first { $0 != design.steps[0] } ?? .open
        let result = challenge.fold(wrong)
        XCTAssertEqual(result, .finished(completed: 0, cleared: false))
        XCTAssertTrue(challenge.isOver)
        XCTAssertEqual(challenge.mistakesLeft, 0)
        XCTAssertNil(challenge.currentDesign)
    }

    func testClearingEveryDesignWithoutAMistakeIsThreeStars() {
        var challenge = OrigamiChallenge(difficulty: .easy)
        var last: ChallengeFold = .ignored
        while let design = challenge.currentDesign {
            for fold in design.steps {
                last = challenge.fold(fold)
            }
        }
        XCTAssertEqual(last, .finished(completed: 3, cleared: true))
        XCTAssertTrue(challenge.isOver)
        XCTAssertEqual(challenge.stars, 3)
    }

    func testOneMistakeOnNormalStillClearsWithTwoStars() {
        var challenge = OrigamiChallenge(difficulty: .normal)
        guard let first = challenge.currentDesign else { return XCTFail("도안이 없다") }
        let wrong = OrigamiFold.allCases.first { $0 != first.steps[0] } ?? .open
        _ = challenge.fold(wrong)
        while let design = challenge.currentDesign {
            for fold in design.steps {
                _ = challenge.fold(fold)
            }
        }
        XCTAssertTrue(challenge.isOver)
        XCTAssertEqual(challenge.completed, MiniGameDifficulty.normal.chainLength)
        XCTAssertEqual(challenge.stars, 2)
    }

    func testRecordsKeepTheBestChain() {
        var records = MiniGameRecords()
        records.submitChallenge(difficulty: .normal, completed: 2, seconds: 30, stars: 1)
        let updated = records.submitChallenge(difficulty: .normal, completed: 5, seconds: 44, stars: 3)
        XCTAssertEqual(updated.plays, 2)
        XCTAssertEqual(updated.bestChain, 5)
        XCTAssertEqual(updated.bestSeconds, 30)
        XCTAssertEqual(records.totalStars, 3)
    }
}

final class PlayroomTests: XCTestCase {
    func testPlayroomStaysLockedUntilTheStoryEnds() {
        let engine = GameEngine(world: .paperMoon)
        XCTAssertFalse(engine.playroomUnlocked)
        XCTAssertNil(engine.recordMemoryResult(difficulty: .easy, moves: 4, seconds: 20, stars: 3))
        XCTAssertNil(engine.miniGameRecord(for: .memoryDrawer, difficulty: .easy))
    }

    func testEndingUnlocksThePlayroom() {
        let engine = Playthrough.run()
        XCTAssertTrue(engine.state.finished)
        XCTAssertTrue(engine.playroomUnlocked)
        let record = engine.recordMemoryResult(difficulty: .easy, moves: 6, seconds: 31, stars: 2)
        XCTAssertEqual(record?.bestMoves, 6)
        XCTAssertEqual(engine.miniGameRecord(for: .memoryDrawer, difficulty: .easy)?.plays, 1)
        XCTAssertEqual(engine.state.miniGames.totalStars, 2)
    }

    func testPlayroomRecordsSurviveSaveAndRestore() {
        let store = InMemorySaveStore()
        let engine = Playthrough.run(store: store)
        engine.recordChallengeResult(difficulty: .hard, completed: 4, seconds: 65, stars: 1)
        guard let stored = store.load() else { return XCTFail("저장이 없다") }
        let restored = GameEngine(world: .paperMoon, state: stored)
        XCTAssertEqual(restored.miniGameRecord(for: .origamiChallenge, difficulty: .hard)?.bestChain, 4)
        XCTAssertTrue(restored.playroomUnlocked)
    }

    func testCellarClearAloneDoesNotOpenThePlayroom() {
        let state = GameState(
            stage: .cellar,
            room: .cellarSteps,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            clearedStages: [.cellar]
        )
        let engine = GameEngine(world: .paperMoon, state: state)
        XCTAssertFalse(engine.playroomUnlocked)
    }
}
