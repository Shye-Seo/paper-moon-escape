import Foundation
import PaperMoonCore

/// 실제 플레이 순서 그대로 게임을 끝까지 미는 시나리오.
/// 여러 테스트가 이걸로 "풀 수 있는 게임인지"를 확인한다.
enum Playthrough {
    static func run(
        world: World = .paperMoon,
        store: SaveStore? = nil,
        entitlements: Entitlements = .full,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 1_700_000_000) }
    ) -> GameEngine {
        let engine = GameEngine(
            world: world,
            store: store,
            entitlements: entitlements,
            clock: now
        )

        // ── 1. 삐걱이는 장난감 다락방
        _ = engine.tap(.rockingHorse)          // 달걀 모양 열쇠 조각
        _ = engine.tap(.owlClock)              // 접착제 통
        _ = engine.tap(.highShelf)             // 모모만 닿는 높은 선반 → 종이 도면
        _ = engine.moveRight()
        _ = engine.tap(.foldingDesk)           // 종이접기 퍼즐 열기
        _ = engine.solvePuzzle(.paperMoonOrigami, answer: [0, 2, 1, 3])  // 종이달 등불
        _ = engine.setCharacter(.pico)
        _ = engine.tap(.mouseHole)             // 피코만 들어가는 쥐구멍 → 짧은 초
        _ = engine.setCharacter(.momo)
        _ = engine.combine(.paperMoonLamp, .candleStub)                  // 켜진 종이달 등불
        _ = engine.tap(.toyBox)                // 블록 퍼즐 열기
        _ = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])         // 톱니 열쇠 조각
        _ = engine.combine(.keyShardOval, .keyShardTooth)                // 부러진 열쇠
        _ = engine.combine(.brokenKey, .glueBottle)                      // 이어 붙인 열쇠
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.mendedKey)
        _ = engine.tap(.moonLatch)             // 스테이지 클리어

        // ── 2. 거꾸로 자라는 온실
        _ = engine.tap(.seedPouch)             // 씨앗
        _ = engine.tap(.wateringCanCorner)     // 물뿌리개
        _ = engine.moveRight()
        _ = engine.tap(.pondShelf)             // 유리병
        _ = engine.setCharacter(.pico)
        _ = engine.tap(.fireflies)             // 피코만 잡는 반딧불이
        _ = engine.combine(.emptyJar, .firefly)                          // 랜턴
        _ = engine.tap(.frogChorus)            // 피코만 부르는 개구리 노래
        _ = engine.solvePuzzle(.frogSong, answer: [3, 1, 4, 2])          // 물이 흐른다
        _ = engine.moveRight()                 // 랜턴을 들고 유리방으로
        _ = engine.tap(.tornPaperWindow)       // 찢어진 종이 → 빛 투과 퍼즐
        _ = engine.solvePuzzle(.tornPaperCode, answer: [2, 0, 3, 1])     // 숨은 암호
        _ = engine.tap(.moonShardBranch)       // 종이달 조각
        _ = engine.moveRight()                 // 유리방 → 덩굴 문(한 바퀴)
        _ = engine.setCharacter(.momo)
        _ = engine.tapInventoryItem(.seed)
        _ = engine.tap(.flowerPot)             // 씨앗 심기
        _ = engine.tapInventoryItem(.wateringCan)
        _ = engine.tap(.flowerPot)             // 덩굴이 자란다
        _ = engine.tap(.vineGate)              // 스테이지 클리어

        // ── 3. 태엽 시계탑 꼭대기
        _ = engine.tap(.woodBox)               // 태엽 열쇠
        _ = engine.moveRight()
        _ = engine.tap(.dialPanel)
        _ = engine.solvePuzzle(.gearDials, answer: [0, 1, 3])
        _ = engine.tap(.gearPile)              // 톱니바퀴
        _ = engine.combine(.windKey, .gear)                              // 시계 부품
        _ = engine.tapInventoryItem(.clockPart)
        _ = engine.tap(.windSocket)            // 태엽 감기 → 종탑 열림
        _ = engine.tap(.dustyMirror)           // 먼지 닦기 판 열기
        _ = engine.completeDustPanel("tower.mirror")                     // 유리에 새겨진 글씨
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.paperMoonShard)
        _ = engine.tap(.paperBell)             // 엔딩

        return engine
    }

    /// 본편을 이미 끝낸 상태에서 보너스 지하실만 처음부터 끝까지.
    static func runCellar(
        world: World = .paperMoon,
        entitlements: Entitlements = .full,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 1_700_000_000) }
    ) -> GameEngine {
        let state = GameState(
            stage: .cellar,
            room: .cellarSteps,
            startedAt: now(),
            finished: true,
            clearedStages: [.attic, .greenhouse, .clocktower]
        )
        let engine = GameEngine(
            world: world,
            state: state,
            entitlements: entitlements,
            clock: now
        )

        _ = engine.start(stage: .cellar)

        // 지하실 계단
        _ = engine.tap(.oilLampHook)           // 모모 → 기름등잔
        _ = engine.setCharacter(.pico)
        _ = engine.tap(.brickNook)             // 피코 → 녹슨 손잡이
        _ = engine.setCharacter(.momo)
        _ = engine.tapInventoryItem(.rustyHandle)
        _ = engine.tap(.ironGateLatch)         // 철문 열림
        _ = engine.moveRight()

        // 포도주 창고
        _ = engine.tap(.paperCrate)            // 양피지
        _ = engine.tap(.foldingStool)          // 종이배 접기 퍼즐
        _ = engine.solvePuzzle(.cellarBoat, answer: [1, 3, 0, 2])        // 접은 종이배
        _ = engine.setCharacter(.pico)
        _ = engine.tap(.tornLabel)             // 빛 투과 퍼즐
        _ = engine.solvePuzzle(.cellarVaultCode, answer: [3, 1, 0, 2])   // 금고 암호
        _ = engine.tapInventoryItem(.paperBoat)
        _ = engine.tap(.floodedDrain)          // 금고 열쇠
        _ = engine.setCharacter(.momo)
        _ = engine.moveRight()

        // 종이달 금고
        _ = engine.tap(.vaultLedger)           // 먼지 닦기 판 열기
        _ = engine.completeDustPanel("cellar.ledger")
        _ = engine.tapInventoryItem(.vaultKey)
        _ = engine.tap(.moonVault)             // 보너스 엔딩

        return engine
    }

    /// 본편 9개 방을 돌며 숨은 종이학 12마리를 모두 줍는다.
    @discardableResult
    static func collectAllCranes(
        world: World = .paperMoon,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 1_700_000_000) }
    ) -> GameEngine {
        // 유리방(랜턴)과 종탑(태엽)까지 걸어 들어갈 수 있게 문을 열어 둔 상태에서 돈다.
        let state = GameState(
            stage: .attic,
            room: .atticLanding,
            inventory: [.lantern],
            flags: [Flags.clockWound],
            startedAt: now(),
            clearedStages: [.attic, .greenhouse, .clocktower]
        )
        let engine = GameEngine(
            world: world,
            state: state,
            entitlements: .full,
            clock: now
        )
        for stageID in StageID.mainline {
            _ = engine.start(stage: stageID)
            for _ in 0..<3 {
                for collectible in engine.visibleCollectibles where collectible.kind == .crane {
                    _ = engine.collect(collectible.id)
                }
                _ = engine.moveRight()
            }
        }
        return engine
    }
}
