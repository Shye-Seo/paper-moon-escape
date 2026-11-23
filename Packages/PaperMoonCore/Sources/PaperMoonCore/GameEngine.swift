import Foundation

/// 게임 규칙의 심장. 모든 입력은 여기로 들어와 사건 목록으로 나간다.
/// 화면(App)은 상태를 직접 고치지 않고 이 엔진만 호출한다.
public final class GameEngine {
    public private(set) var state: GameState
    public let world: World
    private let store: SaveStore?
    private let clock: () -> Date

    public init(
        world: World = .paperMoon,
        state: GameState? = nil,
        store: SaveStore? = nil,
        clock: @escaping () -> Date = { Date() }
    ) {
        self.world = world
        self.clock = clock
        self.store = store
        if let state {
            self.state = state
        } else if let saved = store?.load() {
            self.state = saved
        } else {
            self.state = GameState.newGame(at: clock())
        }
    }

    // MARK: - 읽기

    public var currentRoom: Room {
        if let room = world.room(state.room) {
            return room
        }
        return world.rooms.first
            ?? Room(
                id: state.room,
                stage: state.stage,
                title: "다락방",
                caption: "",
                art: .atticLanding
            )
    }

    public var currentStage: Stage? {
        world.stage(state.stage)
    }

    public var selectedItem: ItemID? {
        state.selectedItem
    }

    public var inventory: [Item] {
        state.inventory.compactMap { world.item($0) }
    }

    public func itemName(_ id: ItemID) -> String {
        world.itemName(id)
    }

    public func visibleHotspots() -> [Hotspot] {
        world.hotspots(in: state.room).filter { hotspot in
            hotspot.hiddenWhen.isEmpty || !state.satisfiesAll(hotspot.hiddenWhen)
        }
    }

    public func currentHint() -> Hint? {
        world.currentHint(for: state)
    }

    public func canEnter(stage id: StageID) -> Bool {
        guard let index = world.stages.firstIndex(where: { $0.id == id }) else { return false }
        if index == 0 { return true }
        if state.clearedStages.contains(id) { return true }
        let previous = world.stages[index - 1]
        return state.clearedStages.contains(previous.id)
    }

    public func summary() -> GameSummary {
        GameSummary(
            seconds: state.elapsedSeconds(now: clock()),
            hintsUsed: state.hintsUsed,
            clearedStages: state.clearedStages.count,
            craftedCount: state.craftedCount,
            itemCount: state.inventory.count
        )
    }

    // MARK: - 이동

    public func moveLeft() -> [GameEvent] {
        move(step: -1)
    }

    public func moveRight() -> [GameEvent] {
        move(step: 1)
    }

    private func move(step: Int) -> [GameEvent] {
        guard let stage = currentStage, !stage.rooms.isEmpty else { return [] }
        guard let index = stage.rooms.firstIndex(of: state.room) else {
            return enter(stage.rooms[0])
        }
        let count = stage.rooms.count
        let nextIndex = ((index + step) % count + count) % count
        return enter(stage.rooms[nextIndex])
    }

    private func enter(_ roomID: RoomID) -> [GameEvent] {
        guard let room = world.room(roomID) else { return [] }
        if let lock = room.lock, !state.satisfies(lock.requirement) {
            return finish([.blocked(lock.message), .reaction(.pico, "🚪")])
        }
        let changed = state.room != roomID
        state.room = roomID
        state.selectedItem = nil
        var events: [GameEvent] = [.selection(nil)]
        if changed {
            events.append(.roomChanged(roomID))
        }
        return finish(events)
    }

    /// 스테이지 선택 화면에서 스테이지로 들어간다.
    public func start(stage id: StageID) -> [GameEvent] {
        guard let stage = world.stage(id) else { return [] }
        guard canEnter(stage: id) else {
            return finish([.blocked("아직 문이 열리지 않은 스테이지다."), .reaction(.pico, "🔒")])
        }
        state.stage = id
        state.room = stage.rooms.first ?? state.room
        state.selectedItem = nil
        state.finished = false
        state.finishedAt = nil
        return finish([
            .stageStarted(id),
            .roomChanged(state.room),
            .line(.narration(stage.opening))
        ])
    }

    // MARK: - 탐색

    public func tap(_ hotspotID: HotspotID) -> [GameEvent] {
        guard let hotspot = world.hotspot(hotspotID) else { return [] }
        guard hotspot.room == state.room else {
            return finish([.blocked("지금 방에 있는 것만 만질 수 있다.")])
        }
        if !hotspot.hiddenWhen.isEmpty && state.satisfiesAll(hotspot.hiddenWhen) {
            return finish([])
        }
        if let selected = state.selectedItem {
            return use(selected, on: hotspot)
        }
        if !state.satisfiesAll(hotspot.requires) {
            var events: [GameEvent] = []
            events.append(.line(.narration(hotspot.blocked ?? "아직은 손이 닿지 않는다.")))
            events.append(.reaction(.pico, "🤔"))
            return finish(events)
        }
        if state.claimedHotspots.contains(hotspotID) {
            if let repeatText = hotspot.repeatText {
                return finish([.line(.narration(repeatText))])
            }
            return finish([])
        }
        var events: [GameEvent] = []
        apply(hotspot.effects, into: &events)
        if hotspot.effects.contains(where: { $0.isClaiming }) {
            state.claimedHotspots.insert(hotspotID)
        }
        if events.isEmpty {
            events.append(.line(.narration(hotspot.repeatText ?? "아무 일도 일어나지 않았다. 다른 것을 살펴볼까?")))
        }
        return finish(events)
    }

    private func use(_ item: ItemID, on hotspot: Hotspot) -> [GameEvent] {
        guard let reaction = hotspot.itemReactions.first(where: { $0.item == item }) else {
            state.selectedItem = nil
            let text = hotspot.mismatchText
                ?? "\(world.itemName(item))로는 여기서 아무 일도 일어나지 않는다."
            return finish([.selection(nil), .blocked(text), .reaction(.pico, "🤨")])
        }
        state.selectedItem = nil
        guard state.satisfiesAll(reaction.requires) else {
            return finish([
                .selection(nil),
                .line(.narration(reaction.blocked ?? "아직은 쓸 수 없다.")),
                .reaction(.pico, "🤔")
            ])
        }
        var events: [GameEvent] = [.selection(nil), .line(.narration(reaction.text))]
        if reaction.consume {
            removeItem(item, into: &events)
        }
        apply(reaction.effects, into: &events)
        if reaction.effects.contains(where: { $0.isClaiming }) {
            state.claimedHotspots.insert(hotspot.id)
        }
        return finish(events)
    }

    // MARK: - 인벤토리와 조합

    public func tapInventoryItem(_ item: ItemID) -> [GameEvent] {
        guard state.inventory.contains(item) else { return [] }
        if let selected = state.selectedItem, selected != item {
            return combine(selected, item)
        }
        if state.selectedItem == item {
            state.selectedItem = nil
            return finish([.selection(nil)])
        }
        state.selectedItem = item
        return finish([.selection(item)])
    }

    public func clearSelection() -> [GameEvent] {
        guard state.selectedItem != nil else { return [] }
        state.selectedItem = nil
        return finish([.selection(nil)])
    }

    @discardableResult
    public func combine(_ first: ItemID, _ second: ItemID) -> [GameEvent] {
        guard state.inventory.contains(first) else {
            return finish([.blocked("\(world.itemName(first))이(가) 인벤토리에 없다.")])
        }
        guard state.inventory.contains(second) else {
            return finish([.blocked("\(world.itemName(second))이(가) 인벤토리에 없다.")])
        }
        guard first != second else {
            return finish([.blocked("같은 물건끼리는 합칠 수 없다."), .reaction(.momo, "🙃")])
        }
        guard let combo = world.combo(first, second) else {
            state.selectedItem = nil
            return finish([
                .selection(nil),
                .line(.narration("\(world.itemName(first))와(과) \(world.itemName(second))는 서로 어울리지 않는다.")),
                .reaction(.momo, "🙃")
            ])
        }
        var events: [GameEvent] = [.selection(nil), .line(.narration(combo.text))]
        removeItem(first, into: &events)
        removeItem(second, into: &events)
        if !state.inventory.contains(combo.result) {
            state.inventory.append(combo.result)
            events.append(.itemAdded(combo.result))
        }
        state.craftedCount += 1
        if let flag = combo.flag {
            state.flags.insert(flag)
        }
        events.append(.crafted(result: combo.result, ingredients: [first, second]))
        events.append(.reaction(.momo, "✨"))
        return finish(events)
    }

    private func removeItem(_ item: ItemID, into events: inout [GameEvent]) {
        if let index = state.inventory.firstIndex(of: item) {
            state.inventory.remove(at: index)
            events.append(.itemRemoved(item))
        }
        if state.selectedItem == item {
            state.selectedItem = nil
        }
    }

    // MARK: - 퍼즐

    public func solvePuzzle(_ puzzleID: PuzzleID, answer: [Int]) -> [GameEvent] {
        guard let puzzle = world.puzzle(puzzleID) else { return [] }
        guard !state.solvedPuzzles.contains(puzzleID) else {
            return finish([.line(.narration("이미 풀린 퍼즐이다. 다른 곳을 둘러보자."))])
        }
        if answer == puzzle.solution {
            state.solvedPuzzles.insert(puzzleID)
            var events: [GameEvent] = [.puzzleSolved(puzzleID), .reaction(.pico, "🎉")]
            apply(puzzle.rewards, into: &events)
            return finish(events)
        }
        let attempts = (state.puzzleAttempts[puzzleID.rawValue] ?? 0) + 1
        state.puzzleAttempts[puzzleID.rawValue] = attempts
        return finish([
            .puzzleMissed(puzzleID, attempts: attempts),
            .line(.narration(puzzle.retryText)),
            .reaction(.pico, "😵")
        ])
    }

    // MARK: - 힌트

    public func requestHint() -> [GameEvent] {
        guard let hint = world.currentHint(for: state) else {
            return finish([
                .line(.narration("지금은 물어볼 것이 없어 보인다. 방을 한 바퀴 둘러볼까?")),
                .reaction(.momo, "🙂")
            ])
        }
        let current = state.hintLevel(for: hint.id)
        guard current < 2 else {
            return finish([
                .hint(id: hint.id, level: 2, text: hint.levelTwo, hasMore: false)
            ])
        }
        let level = current + 1
        state.hintLevels[hint.id] = level
        state.hintsUsed += 1
        let text = level == 1 ? hint.levelOne : hint.levelTwo
        return finish([
            .hint(id: hint.id, level: level, text: text, hasMore: level < 2),
            .reaction(.momo, level == 1 ? "💡" : "🔍")
        ])
    }

    // MARK: - 초기화와 저장

    public func resetStage() -> [GameEvent] {
        guard let stage = currentStage else { return [] }
        let pool = world.stageItemPool(stage.id)
        state.inventory.removeAll { pool.contains($0) }
        state.flags.subtract(world.stageFlags(stage.id))
        for puzzle in world.puzzles(in: stage.id) {
            state.solvedPuzzles.remove(puzzle.id)
            state.puzzleAttempts[puzzle.id.rawValue] = nil
        }
        for hotspot in world.hotspots(in: stage.id) {
            state.claimedHotspots.remove(hotspot.id)
        }
        for hint in world.hints(in: stage.id) {
            state.hintLevels[hint.id] = nil
        }
        state.selectedItem = nil
        state.room = stage.rooms.first ?? state.room
        state.finished = false
        state.finishedAt = nil
        if world.stages.first?.id == stage.id {
            state.startedAt = clock()
        }
        return finish([
            .line(.narration("\(stage.title)이(가) 처음 모습으로 돌아갔다. 다시 천천히 둘러보자.")),
            .roomChanged(state.room)
        ])
    }

    public func restartGame() -> [GameEvent] {
        state = GameState.newGame(at: clock())
        let first = world.stages.first
        store?.save(state)
        return [
            .stageStarted(first?.id ?? .attic),
            .roomChanged(state.room),
            .line(.narration(first?.opening ?? "다시, 비 오는 다락방."))
        ]
    }

    // MARK: - 효과 해석

    private func apply(_ effects: [Effect], into events: inout [GameEvent]) {
        for effect in effects {
            switch effect {
            case .say(let line):
                events.append(.line(line))
            case .react(let character, let emoji):
                events.append(.reaction(character, emoji))
            case .give(let item):
                if !state.inventory.contains(item) {
                    state.inventory.append(item)
                    events.append(.itemAdded(item))
                }
            case .take(let item):
                removeItem(item, into: &events)
            case .flag(let name):
                state.flags.insert(name)
            case .unflag(let name):
                state.flags.remove(name)
            case .openPuzzle(let puzzleID):
                if state.solvedPuzzles.contains(puzzleID) {
                    events.append(.line(.narration("이미 풀린 자물쇠다. 더 만질 것은 없다.")))
                } else {
                    events.append(.puzzleOpened(puzzleID))
                }
            case .clearStage:
                completeCurrentStage(&events)
            }
        }
    }

    private func completeCurrentStage(_ events: inout [GameEvent]) {
        guard let stage = currentStage else { return }
        if !state.clearedStages.contains(stage.id) {
            state.clearedStages.insert(stage.id)
            events.append(.stageCleared(stage.id))
            events.append(.line(.narration(stage.closing)))
        }
        guard let nextID = stage.next, let nextStage = world.stage(nextID) else {
            finishGame(&events)
            return
        }
        state.stage = nextStage.id
        state.room = nextStage.rooms.first ?? state.room
        state.selectedItem = nil
        state.finished = false
        state.finishedAt = nil
        events.append(.stageStarted(nextStage.id))
        events.append(.roomChanged(state.room))
        events.append(.line(.narration(nextStage.opening)))
    }

    private func finishGame(_ events: inout [GameEvent]) {
        guard !state.finished else { return }
        state.finished = true
        state.finishedAt = clock()
        if let stage = currentStage {
            state.clearedStages.insert(stage.id)
        }
        events.append(.finished(summary()))
    }

    @discardableResult
    private func finish(_ events: [GameEvent]) -> [GameEvent] {
        store?.save(state)
        return events
    }
}
