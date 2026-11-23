import Foundation

/// 게임의 모든 데이터. 순수한 값이라 저장·테스트·미리보기가 모두 쉽다.
public struct World: Sendable {
    public let stages: [Stage]
    public let rooms: [Room]
    public let items: [Item]
    public let hotspots: [Hotspot]
    public let puzzles: [Puzzle]
    public let combos: [Combo]
    public let hints: [Hint]

    public init(
        stages: [Stage],
        rooms: [Room],
        items: [Item],
        hotspots: [Hotspot],
        puzzles: [Puzzle],
        combos: [Combo],
        hints: [Hint]
    ) {
        self.stages = stages
        self.rooms = rooms
        self.items = items
        self.hotspots = hotspots
        self.puzzles = puzzles
        self.combos = combos
        self.hints = hints
    }

    // MARK: 조회

    public func stage(_ id: StageID) -> Stage? {
        stages.first { $0.id == id }
    }

    public func stage(index: Int) -> Stage? {
        guard index >= 0 && index < stages.count else { return nil }
        return stages[index]
    }

    public func room(_ id: RoomID) -> Room? {
        rooms.first { $0.id == id }
    }

    public func item(_ id: ItemID) -> Item? {
        items.first { $0.id == id }
    }

    public func hotspot(_ id: HotspotID) -> Hotspot? {
        hotspots.first { $0.id == id }
    }

    public func hotspots(in room: RoomID) -> [Hotspot] {
        hotspots.filter { $0.room == room }
    }

    public func hotspots(in stage: StageID) -> [Hotspot] {
        let roomIDs = Set(rooms.filter { $0.stage == stage }.map { $0.id })
        return hotspots.filter { roomIDs.contains($0.room) }
    }

    public func puzzle(_ id: PuzzleID) -> Puzzle? {
        puzzles.first { $0.id == id }
    }

    public func combo(_ first: ItemID, _ second: ItemID) -> Combo? {
        combos.first { $0.matches(first, second) }
    }

    public func itemName(_ id: ItemID) -> String {
        item(id)?.name ?? id.rawValue
    }

    public var startRoom: RoomID {
        stages.first?.rooms.first ?? .atticLanding
    }

    /// 지금 시점에서 가장 먼저 달성해야 할 목표 하나. 목록 순서가 곧 우선순위다.
    public func currentHint(for state: GameState) -> Hint? {
        hints.first { $0.stage == state.stage && !state.satisfies($0.doneIf) }
    }

    public func hints(in stage: StageID) -> [Hint] {
        hints.filter { $0.stage == stage }
    }

    public func puzzles(in stage: StageID) -> [Puzzle] {
        let roomIDs = Set(rooms.filter { $0.stage == stage }.map { $0.id })
        let opened = Set(hotspots.filter { roomIDs.contains($0.room) }
            .flatMap { $0.effects }
            .compactMap { effect -> PuzzleID? in
                if case .openPuzzle(let id) = effect { return id }
                return nil
            })
        return puzzles.filter { opened.contains($0.id) }
    }

    /// 그 스테이지 안에서 손에 넣을 수 있는 모든 아이템(조합 결과까지 포함).
    public func stageItemPool(_ stage: StageID) -> Set<ItemID> {
        var pool = Set<ItemID>()
        for hotspot in hotspots(in: stage) {
            for effect in hotspot.effects {
                if case .give(let item) = effect { pool.insert(item) }
            }
            for reaction in hotspot.itemReactions {
                for effect in reaction.effects {
                    if case .give(let item) = effect { pool.insert(item) }
                }
            }
        }
        for puzzle in puzzles(in: stage) {
            for effect in puzzle.rewards {
                if case .give(let item) = effect { pool.insert(item) }
            }
        }
        var grew = true
        while grew {
            grew = false
            for combo in combos {
                let usesOnlyPool = pool.contains(combo.a) && pool.contains(combo.b)
                if usesOnlyPool && !pool.contains(combo.result) {
                    pool.insert(combo.result)
                    grew = true
                }
            }
        }
        return pool
    }

    /// 그 스테이지에서 설정되는 플래그.
    public func stageFlags(_ stage: StageID) -> Set<String> {
        var flags = Set<String>()
        func collect(_ effects: [Effect]) {
            for effect in effects {
                if case .flag(let name) = effect { flags.insert(name) }
            }
        }
        for hotspot in hotspots(in: stage) {
            collect(hotspot.effects)
            for reaction in hotspot.itemReactions { collect(reaction.effects) }
        }
        for puzzle in puzzles(in: stage) { collect(puzzle.rewards) }
        return flags
    }

    // MARK: 검증

    /// 콘텐츠가 스스로 모순되지 않는지 점검한다. 테스트가 이 목록이 비어 있음을 확인한다.
    public func validate() -> [String] {
        var problems: [String] = []

        if stages.isEmpty { problems.append("스테이지가 없다") }
        if rooms.isEmpty { problems.append("방이 없다") }
        if items.isEmpty { problems.append("아이템이 없다") }

        var seenRooms = Set<RoomID>()
        for room in rooms {
            if !seenRooms.insert(room.id).inserted {
                problems.append("방 id 중복: \(room.id.rawValue)")
            }
            if stage(room.stage) == nil {
                problems.append("방 \(room.id.rawValue)의 스테이지가 없다")
            }
            if hotspots(in: room.id).isEmpty {
                problems.append("방 \(room.id.rawValue)에 지점이 없다")
            }
        }

        var seenHotspots = Set<HotspotID>()
        for hotspot in hotspots {
            if !seenHotspots.insert(hotspot.id).inserted {
                problems.append("지점 id 중복: \(hotspot.id.rawValue)")
            }
            if room(hotspot.room) == nil {
                problems.append("지점 \(hotspot.id.rawValue)의 방이 없다")
            }
            if hotspot.position.x < 0 || hotspot.position.x > 1
                || hotspot.position.y < 0 || hotspot.position.y > 1 {
                problems.append("지점 \(hotspot.id.rawValue) 좌표가 화면 밖이다")
            }
            for effect in hotspot.effects {
                check(effect: effect, owner: hotspot.id.rawValue, problems: &problems)
            }
            for reaction in hotspot.itemReactions {
                if item(reaction.item) == nil {
                    problems.append("지점 \(hotspot.id.rawValue) 반응의 아이템이 없다")
                }
                for effect in reaction.effects {
                    check(effect: effect, owner: hotspot.id.rawValue, problems: &problems)
                }
            }
            if hotspot.effects.isEmpty && hotspot.itemReactions.isEmpty {
                problems.append("지점 \(hotspot.id.rawValue)에 아무 효과가 없다")
            }
        }

        var seenItems = Set<ItemID>()
        for item in items {
            if !seenItems.insert(item.id).inserted {
                problems.append("아이템 id 중복: \(item.id.rawValue)")
            }
        }

        for combo in combos {
            if item(combo.a) == nil || item(combo.b) == nil || item(combo.result) == nil {
                problems.append("조합의 아이템이 정의되지 않았다: \(combo.a.rawValue)+\(combo.b.rawValue)")
            }
            if combo.a == combo.b {
                problems.append("같은 아이템끼리 조합 규칙이 있다: \(combo.a.rawValue)")
            }
        }

        for puzzle in puzzles {
            if puzzle.solution.isEmpty {
                problems.append("퍼즐 \(puzzle.id.rawValue)에 정답이 없다")
            }
            let values = Set(puzzle.tokens.map { $0.value })
            for value in puzzle.solution where !values.contains(value) {
                problems.append("퍼즐 \(puzzle.id.rawValue) 정답 값이 토큰에 없다")
            }
            if puzzle.slotLabels.count != puzzle.solution.count && puzzle.kind == .dials {
                problems.append("퍼즐 \(puzzle.id.rawValue) 다이얼 이름 개수가 맞지 않는다")
            }
            for effect in puzzle.rewards {
                check(effect: effect, owner: puzzle.id.rawValue, problems: &problems)
            }
        }

        for stage in stages {
            if stage.rooms.count < 2 {
                problems.append("스테이지 \(stage.id.rawValue)의 방이 너무 적다")
            }
            for roomID in stage.rooms where room(roomID) == nil {
                problems.append("스테이지 \(stage.id.rawValue)가 없는 방을 가리킨다")
            }
            if let next = stage.next, stages.first(where: { $0.id == next }) == nil {
                problems.append("스테이지 \(stage.id.rawValue)의 다음 스테이지가 없다")
            }
        }

        var seenHints = Set<String>()
        for hint in hints {
            if !seenHints.insert(hint.id).inserted {
                problems.append("힌트 id 중복: \(hint.id)")
            }
            if stage(hint.stage) == nil {
                problems.append("힌트 \(hint.id)의 스테이지가 없다")
            }
            if hint.levelOne == hint.levelTwo {
                problems.append("힌트 \(hint.id)의 두 단계가 같다")
            }
        }

        return problems
    }

    private func check(effect: Effect, owner: String, problems: inout [String]) {
        switch effect {
        case .give(let item):
            if self.item(item) == nil { problems.append("\(owner): 없는 아이템을 준다") }
        case .take(let item):
            if self.item(item) == nil { problems.append("\(owner): 없는 아이템을 가져간다") }
        case .openPuzzle(let puzzle):
            if self.puzzle(puzzle) == nil { problems.append("\(owner): 없는 퍼즐을 연다") }
        case .say, .react, .flag, .unflag, .clearStage:
            break
        }
    }
}

extension World {
    /// 게임에 들어 있는 유일한 세계. App은 이것 하나만 쓴다.
    public static let paperMoon: World = PaperMoonWorld.build()
}
