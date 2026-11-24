import XCTest
@testable import PaperMoonCore

/// 테스트에서 공통으로 쓰는 도우미.
enum TestHelp {
    /// 이벤트 목록에 특정 이벤트가 들어 있는지.
    static func has(_ events: [GameEvent], _ expected: GameEvent) -> Bool {
        events.contains(expected)
    }

    /// 이벤트 목록에 특정 대사가 들어 있는지.
    static func hasLine(_ events: [GameEvent], containing needle: String) -> Bool {
        events.contains { event in
            if case .line(let line) = event {
                return line.text.contains(needle)
            }
            return false
        }
    }

    static func hasItemAdded(_ events: [GameEvent], _ item: ItemID) -> Bool {
        events.contains { event in
            if case .itemAdded(let added) = event { return added == item }
            return false
        }
    }

    static func hasBlocked(_ events: [GameEvent]) -> Bool {
        events.contains { event in
            if case .blocked = event { return true }
            return false
        }
    }

    static func puzzleOpened(_ events: [GameEvent], _ puzzle: PuzzleID) -> Bool {
        events.contains { event in
            if case .puzzleOpened(let opened) = event { return opened == puzzle }
            return false
        }
    }

    static func hasSearchFound(_ events: [GameEvent], _ id: String) -> Bool {
        events.contains { event in
            if case .searchFound(let found) = event { return found == id }
            return false
        }
    }

    static func hasSearchMissed(_ events: [GameEvent]) -> Bool {
        events.contains { event in
            if case .searchMissed = event { return true }
            return false
        }
    }

    /// 천장까지 더듬어 반드시 찾아낸다. 마지막 이벤트 묶음을 돌려준다.
    @discardableResult
    static func searchUntilFound(
        _ engine: GameEngine,
        _ id: String,
        limit: Int = 8
    ) -> [GameEvent] {
        var events: [GameEvent] = []
        for _ in 0..<limit {
            events = engine.search(id)
            if hasSearchFound(events, id) { return events }
        }
        return events
    }

    /// 특정 스테이지 중간에서 시작하는 엔진(이미 앞 스테이지는 깬 상태).
    static func engine(
        at room: RoomID,
        stage: StageID,
        inventory: [ItemID] = [],
        flags: Set<String> = [],
        solved: Set<PuzzleID> = [],
        cleared: Set<StageID> = [],
        character: PlayableCharacter = .momo,
        collected: Set<CollectibleID> = [],
        entitlements: Entitlements = .full,
        store: SaveStore? = nil,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 1_700_000_000) },
        random: @escaping () -> Double = { Double.random(in: 0..<1) }
    ) -> GameEngine {
        let state = GameState(
            stage: stage,
            room: room,
            inventory: inventory,
            flags: flags,
            solvedPuzzles: solved,
            startedAt: now(),
            clearedStages: cleared,
            activeCharacter: character,
            collected: collected
        )
        return GameEngine(
            world: .paperMoon,
            state: state,
            store: store,
            entitlements: entitlements,
            clock: now,
            random: random
        )
    }
}
