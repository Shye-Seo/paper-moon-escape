import Foundation
import PaperMoonCore

/// 실제 플레이 순서 그대로 게임을 끝까지 미는 시나리오.
/// 여러 테스트가 이걸로 "풀 수 있는 게임인지"를 확인한다.
enum Playthrough {
    static func run(
        world: World = .paperMoon,
        store: SaveStore? = nil,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 1_700_000_000) }
    ) -> GameEngine {
        let engine = GameEngine(world: world, store: store, clock: now)

        // ── 1. 삐걱이는 장난감 다락방
        _ = engine.tap(.rockingHorse)          // 달걀 모양 열쇠 조각
        _ = engine.tap(.owlClock)              // 접착제 통
        _ = engine.moveRight()
        _ = engine.tap(.toyBox)                // 블록 퍼즐 열기
        _ = engine.solvePuzzle(.toyBlocks, answer: [0, 3, 2, 1])  // 톱니 열쇠 조각
        _ = engine.combine(.keyShardOval, .keyShardTooth)         // 부러진 열쇠
        _ = engine.combine(.brokenKey, .glueBottle)               // 이어 붙인 열쇠
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.mendedKey)
        _ = engine.tap(.moonLatch)             // 스테이지 클리어

        // ── 2. 거꾸로 자라는 온실
        _ = engine.tap(.seedPouch)             // 씨앗
        _ = engine.tap(.wateringCanCorner)     // 물뿌리개
        _ = engine.moveRight()
        _ = engine.tap(.pondShelf)             // 유리병
        _ = engine.tap(.fireflies)             // 반딧불이
        _ = engine.combine(.emptyJar, .firefly)                    // 랜턴
        _ = engine.tap(.frogChorus)
        _ = engine.solvePuzzle(.frogSong, answer: [3, 1, 4, 2])    // 물이 흐른다
        _ = engine.moveRight()                 // 랜턴을 들고 유리방으로
        _ = engine.tap(.moonShardBranch)       // 종이달 조각
        _ = engine.moveRight()                 // 유리방 → 덩굴 문(한 바퀴)
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
        _ = engine.combine(.windKey, .gear)                        // 시계 부품
        _ = engine.tapInventoryItem(.clockPart)
        _ = engine.tap(.windSocket)            // 태엽 감기 → 종탑 열림
        _ = engine.moveRight()
        _ = engine.tapInventoryItem(.paperMoonShard)
        _ = engine.tap(.paperBell)             // 엔딩

        return engine
    }
}
