import Foundation

/// 게임 규칙의 심장. 모든 입력은 여기로 들어와 사건 목록으로 나간다.
/// 화면(App)은 상태를 직접 고치지 않고 이 엔진만 호출한다.
public final class GameEngine {
    public private(set) var state: GameState
    public let world: World
    /// 구매한 상품. 저장 파일이 아니라 실행할 때 밖에서 채워 준다.
    public private(set) var entitlements: Entitlements
    private let store: SaveStore?
    private let clock: () -> Date

    public init(
        world: World = .paperMoon,
        state: GameState? = nil,
        store: SaveStore? = nil,
        entitlements: Entitlements = .full,
        clock: @escaping () -> Date = { Date() }
    ) {
        self.world = world
        self.clock = clock
        self.store = store
        self.entitlements = entitlements
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

    public var activeCharacter: PlayableCharacter {
        state.activeCharacter
    }

    public func itemName(_ id: ItemID) -> String {
        world.itemName(id)
    }

    public func visibleHotspots() -> [Hotspot] {
        world.hotspots(in: state.room).filter { hotspot in
            hotspot.hiddenWhen.isEmpty || !state.satisfiesAll(hotspot.hiddenWhen)
        }
    }

    /// 이 방에서 아직 줍지 않은 수집품.
    public var visibleCollectibles: [Collectible] {
        world.collectibles(in: state.room).filter { !state.collected.contains($0.id) }
    }

    public func currentHint() -> Hint? {
        world.currentHint(for: state)
    }

    public func dustPanel(in room: RoomID) -> DustPanel? {
        world.dustPanels(in: room).first
    }

    /// 무료 힌트를 더 볼 수 있는지.
    public var hintsRemaining: Int? {
        guard !entitlements.hintPass else { return nil }
        return max(0, Entitlements.freeHintAllowance - state.hintsUsed)
    }

    /// 2·3장면과 보너스 장면은 상품에 따라 잠긴다. 1장면은 언제나 열려 있다.
    public func canEnter(stage id: StageID) -> Bool {
        guard let stage = world.stage(id) else { return false }
        if stage.isBonus {
            guard state.clearedStages.contains(.clocktower) else { return false }
            return entitlements.fullUnlock && entitlements.cellarChapter
        }
        guard let index = world.stages.firstIndex(where: { $0.id == id }) else { return false }
        if index == 0 { return true }
        guard entitlements.fullUnlock else { return false }
        if state.clearedStages.contains(id) { return true }
        let previous = world.stages[index - 1]
        return state.clearedStages.contains(previous.id)
    }

    /// 잠긴 이유를 화면이 그대로 보여 줄 수 있게 한 줄로.
    public func lockReason(for id: StageID) -> String? {
        guard let stage = world.stage(id) else { return nil }
        if stage.isBonus {
            if !state.clearedStages.contains(.clocktower) {
                return "본편을 끝내면 열리는 보너스 장면이다."
            }
            if !entitlements.fullUnlock || !entitlements.cellarChapter {
                return "\(StoreProduct.cellarChapter.title) · \(StoreProduct.cellarChapter.priceText)"
            }
            return nil
        }
        let index = world.stages.firstIndex(where: { $0.id == id }) ?? 0
        if index == 0 || state.clearedStages.contains(id) { return nil }
        if !entitlements.fullUnlock {
            return "\(StoreProduct.fullUnlock.title) · \(StoreProduct.fullUnlock.priceText)"
        }
        let previous = world.stages[index - 1]
        if !state.clearedStages.contains(previous.id) {
            return "앞 장면을 먼저 깨야 한다."
        }
        return nil
    }

    public func summary() -> GameSummary {
        GameSummary(
            seconds: state.elapsedSeconds(now: clock()),
            hintsUsed: state.hintsUsed,
            clearedStages: state.clearedStages.count,
            craftedCount: state.craftedCount,
            itemCount: state.inventory.count,
            collectedCranes: state.collectedCranes,
            collectedStamps: state.collectedStamps
        )
    }

    public func setEntitlements(_ value: Entitlements) {
        entitlements = value
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
            if stage.isBonus && !entitlements.cellarChapter, state.clearedStages.contains(.clocktower) {
                return finish([
                    .line(.narration("지하실 문은 두꺼운 종이로 봉해져 있다. 「\(StoreProduct.cellarChapter.title)」을 사면 열린다.")),
                    .purchaseRequired(.cellarChapter, StoreProduct.cellarChapter.summary)
                ])
            }
            if !entitlements.fullUnlock, !stage.isBonus {
                return finish([
                    .line(.narration("2장면부터는 본편 잠금해제가 필요하다. 1장면은 끝까지 무료로 즐길 수 있다.")),
                    .purchaseRequired(.fullUnlock, StoreProduct.fullUnlock.summary)
                ])
            }
            return finish([.blocked(lockReason(for: id) ?? "아직 문이 열리지 않은 스테이지다."), .reaction(.pico, "🔒")])
        }
        state.stage = id
        state.room = stage.rooms.first ?? state.room
        state.selectedItem = nil
        state.finished = false
        state.finishedAt = nil
        state.activeCharacter = .momo
        return finish([
            .stageStarted(id),
            .roomChanged(state.room),
            .characterChanged(.momo),
            .line(.narration(stage.opening))
        ])
    }

    // MARK: - 캐릭터

    /// 모모와 고양이 피코를 바꾼다. 지점마다 손이 닿는 캐릭터가 다르다.
    @discardableResult
    public func setCharacter(_ character: PlayableCharacter) -> [GameEvent] {
        guard state.activeCharacter != character else { return [] }
        state.activeCharacter = character
        state.selectedItem = nil
        let line: Line
        switch character {
        case .momo:
            line = .momo("내가 손 닿는 데까지 해 볼게. 피코는 옆에서 봐 줘.")
        case .pico:
            line = .pico("좁은 틈은 나한테 맡겨, 냥. 모모는 높은 데 부탁할게.")
        }
        return finish([
            .characterChanged(character),
            .selection(nil),
            .line(line),
            .reaction(character.reactionCharacter, character == .momo ? "🧣" : "🐾")
        ])
    }

    @discardableResult
    public func toggleCharacter() -> [GameEvent] {
        setCharacter(state.activeCharacter.other)
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
        // 지점마다 손이 닿는 캐릭터가 있다. 아니면 코지하게 돌려보낸다.
        if let required = hotspot.requiredCharacter, required != state.activeCharacter {
            let note = hotspot.characterNote
                ?? "\(hotspot.label)은(는) \(required.displayName)의 손이 필요해 보인다. 캐릭터를 바꿔 보자."
            return finish([
                .line(.narration(note)),
                .reaction(required.reactionCharacter, required == .momo ? "🙂" : "🐾")
            ])
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
            // 아직 못 푼 퍼즐은 닫았다가 다시 열 수 있어야 한다.
            if let puzzleID = openedPuzzle(of: hotspot), !state.solvedPuzzles.contains(puzzleID) {
                return finish([.puzzleOpened(puzzleID)])
            }
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

    private func openedPuzzle(of hotspot: Hotspot) -> PuzzleID? {
        for effect in hotspot.effects {
            if case .openPuzzle(let id) = effect { return id }
        }
        return nil
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

    // MARK: - 수집품과 비밀 서랍

    /// 숨은 종이학·우표를 줍는다.
    public func collect(_ id: CollectibleID) -> [GameEvent] {
        guard let collectible = world.collectible(id) else { return [] }
        guard collectible.room == state.room else {
            return finish([.blocked("이 방에서는 \(collectible.label)이(가) 보이지 않는다. 다른 방을 살펴보자.")])
        }
        guard !state.collected.contains(id) else {
            return finish([.line(.narration("\(collectible.label)은(는) 이미 스크랩북에 붙어 있다."))])
        }
        state.collected.insert(id)
        var events: [GameEvent] = [.collectibleFound(id)]
        switch collectible.kind {
        case .crane:
            events.append(.line(.narration("\(collectible.label)을(를) 조심히 폈다. \(collectible.memory)")))
            events.append(.reaction(.pico, "🕊"))
        case .stamp:
            events.append(.line(.narration("\(collectible.label)을(를) 스크랩북 귀퉁이에 붙였다. \(collectible.memory)")))
            events.append(.reaction(.momo, "✉️"))
        }
        if state.hasAllCranes && !state.flags.contains(Flags.cranesComplete) {
            state.flags.insert(Flags.cranesComplete)
            events.append(.secretDrawerUnlocked)
            events.append(.line(.narration("열두 번째 종이학이 날개를 접었다. 벽판 안쪽에서 작은 서랍이 열리는 소리가 났다. 엔딩 뒤에 다락방으로 돌아오면 열어 볼 수 있다.")))
        }
        return finish(events)
    }

    public func openSecretDrawer() -> [GameEvent] {
        guard state.hasAllCranes else {
            return finish([
                .blocked("서랍은 아직 꿈쩍도 하지 않는다. 종이학이 \(state.collectedCranes)마리뿐이다."),
                .reaction(.pico, "🐾")
            ])
        }
        guard !state.secretDrawerOpened else {
            return finish([.line(.narration("서랍은 열린 채다. 종이학 모빌이 창가에서 천천히 돈다."))])
        }
        state.secretDrawerOpened = true
        state.flags.insert(Flags.secretDrawer)
        let gift = world.secretGift
        var events: [GameEvent] = [.secretDrawerOpened(gift)]
        for line in gift.lines {
            events.append(.line(.narration(line)))
        }
        events.append(.reaction(.momo, "🎁"))
        return finish(events)
    }

    // MARK: - 먼지 닦기

    /// 지금 방의 먼지 판. 없으면 nil.
    public var currentDustPanel: DustPanel? {
        dustPanel(in: state.room)
    }

    /// 문질러 다 닦은 뒤 화면이 부른다.
    public func completeDustPanel(_ id: String) -> [GameEvent] {
        guard let panel = world.dustPanel(id) else { return [] }
        guard panel.room == state.room else {
            return finish([.blocked("지금 방의 먼지가 아니다.")])
        }
        if !panel.doneIf.isEmpty && state.satisfiesAll(panel.doneIf) {
            return finish([.line(.narration("이미 다 닦아 낸 자리다."))])
        }
        var events: [GameEvent] = [.dustCleared(id), .line(.narration(panel.revealText))]
        apply(panel.effects, into: &events)
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
        if !entitlements.hintPass && state.hintsUsed >= Entitlements.freeHintAllowance {
            return finish([
                .purchaseRequired(.hintPass, StoreProduct.hintPass.summary),
                .line(.narration("무료 힌트 \(Entitlements.freeHintAllowance)회를 다 썼다. 힌트 무제한 패스를 사면 막힐 때마다 바로 물어볼 수 있다.")),
                .reaction(.momo, "💡")
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
            .characterChanged(state.activeCharacter),
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
            case .openDust(let panelID):
                if let panel = world.dustPanel(panelID), state.satisfiesAll(panel.doneIf) {
                    events.append(.line(.narration("이미 다 닦아 낸 자리다.")))
                } else {
                    events.append(.dustPanelOpened(panelID))
                }
            case .clearStage:
                completeCurrentStage(&events)
            }
        }
    }

    private func completeCurrentStage(_ events: inout [GameEvent]) {
        guard let stage = currentStage else { return }
        let isNew = !state.clearedStages.contains(stage.id)
        if isNew {
            state.clearedStages.insert(stage.id)
            events.append(.stageCleared(stage.id))
            events.append(.line(.narration(stage.closing)))
        }
        if stage.isBonus {
            if isNew {
                events.append(.bonusEnding(stage.id, summary()))
            }
            return
        }
        guard let nextID = stage.next, let nextStage = world.stage(nextID) else {
            finishGame(&events)
            return
        }
        // 본편 전체 잠금해제 전에는 2장면 문이 종이로 붙어 있다.
        if !entitlements.fullUnlock {
            events.append(.line(.narration("다음 장면으로 가는 문이 종이로 겹겹이 붙어 있다. 1장면은 여기까지 무료다.")))
            events.append(.purchaseRequired(.fullUnlock, StoreProduct.fullUnlock.summary))
            return
        }
        state.stage = nextStage.id
        state.room = nextStage.rooms.first ?? state.room
        state.selectedItem = nil
        state.finished = false
        state.finishedAt = nil
        state.activeCharacter = .momo
        events.append(.stageStarted(nextStage.id))
        events.append(.roomChanged(state.room))
        events.append(.characterChanged(.momo))
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
