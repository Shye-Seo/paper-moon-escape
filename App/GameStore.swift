import SwiftUI
import PaperMoonCore

/// 화면이 읽는 상태를 한 곳에서 관리한다. 게임 규칙은 전부 `PaperMoonCore`가 갖고 있고,
/// 여기서는 그 결과를 SwiftUI가 좋아하는 모양으로 번역만 한다.
final class GameStore: ObservableObject {
    enum Phase: Equatable {
        case title
        case stageSelect
        case playing
        case ending
    }

    struct Bubble: Identifiable {
        let id = UUID()
        let line: Line
    }

    struct Reaction: Identifiable {
        let id = UUID()
        let character: CharacterID
        let emoji: String
    }

    struct HintCard: Identifiable {
        let id: String
        let level: Int
        let text: String
        let hasMore: Bool
    }

    // MARK: 화면 상태

    @Published private(set) var phase: Phase = .title
    @Published private(set) var room: Room
    @Published private(set) var stage: Stage?
    @Published private(set) var inventory: [Item]
    @Published private(set) var selected: ItemID?
    @Published private(set) var hotspots: [Hotspot]
    @Published private(set) var bubble: Bubble?
    @Published private(set) var reaction: Reaction?
    @Published private(set) var puzzle: Puzzle?
    @Published private(set) var hint: HintCard?
    @Published private(set) var ending: GameSummary?
    @Published private(set) var clearedStages: Set<StageID>
    @Published private(set) var hasSave: Bool
    @Published private(set) var puzzleMisses: Int = 0
    @Published private(set) var stageFlash: StageID?

    let world: World

    // MARK: 내부

    private var engine: GameEngine
    private let saveStore: SaveStore
    private var bubbleWork: DispatchWorkItem?
    private var reactionWork: DispatchWorkItem?
    private var flashWork: DispatchWorkItem?

    init(
        world: World = .paperMoon,
        engine: GameEngine? = nil,
        saveStore: SaveStore? = nil
    ) {
        let resolvedStore = saveStore ?? UserDefaultsSaveStore()
        self.world = world
        self.saveStore = resolvedStore
        self.engine = engine ?? GameEngine(world: world, store: resolvedStore)
        self.room = self.engine.currentRoom
        self.stage = self.engine.currentStage
        self.inventory = self.engine.inventory
        self.selected = self.engine.selectedItem
        self.hotspots = self.engine.visibleHotspots()
        self.clearedStages = self.engine.state.clearedStages
        self.hasSave = resolvedStore.load() != nil
    }

    // MARK: 화면 이동

    func startNewGame() {
        _ = engine.restartGame()
        ending = nil
        puzzle = nil
        hint = nil
        showBubble(Bubble(line: .narration(stageInfo(for: .attic)?.opening ?? "다시, 비 오는 다락방.")))
        phase = .playing
        refresh()
    }

    func continueGame() {
        phase = .playing
        refresh()
    }

    func openStageSelect() {
        phase = .stageSelect
        refresh()
    }

    func backToTitle() {
        phase = .title
        puzzle = nil
        hint = nil
        refresh()
    }

    func enter(_ stageID: StageID) {
        handle(engine.start(stage: stageID))
        if phase != .playing {
            phase = .playing
        }
    }

    func isStageUnlocked(_ stageID: StageID) -> Bool {
        engine.canEnter(stage: stageID)
    }

    // MARK: 조작

    func tap(_ hotspot: Hotspot) {
        handle(engine.tap(hotspot.id))
    }

    func moveLeft() {
        handle(engine.moveLeft())
    }

    func moveRight() {
        handle(engine.moveRight())
    }

    func tapItem(_ item: Item) {
        handle(engine.tapInventoryItem(item.id))
    }

    func requestHint() {
        handle(engine.requestHint())
    }

    func closeHint() {
        hint = nil
    }

    func askMoreHint() {
        requestHint()
    }

    func closePuzzle() {
        puzzle = nil
        puzzleMisses = 0
    }

    func submitPuzzle(answer: [Int]) {
        guard let puzzle else { return }
        let events = engine.solvePuzzle(puzzle.id, answer: answer)
        let missed = events.contains { event in
            if case .puzzleMissed = event { return true }
            return false
        }
        if missed {
            puzzleMisses += 1
        }
        handle(events)
    }

    func resetStage() {
        handle(engine.resetStage())
    }

    func playAgain() {
        ending = nil
        _ = engine.restartGame()
        phase = .playing
        showBubble(Bubble(line: .narration("비 오는 다락방으로 다시 돌아왔다.")))
        refresh()
    }

    // MARK: 읽기 도우미

    func itemName(_ id: ItemID) -> String {
        world.itemName(id)
    }

    func stageInfo(for id: StageID) -> Stage? {
        world.stage(id)
    }

    var stageList: [Stage] {
        world.stages
    }

    var elapsedText: String {
        let seconds = Int(engine.state.elapsedSeconds(now: Date()))
        let minutes = seconds / 60
        let rest = seconds % 60
        return "\(minutes)분 \(rest)초"
    }

    // MARK: 이벤트 소화

    private func handle(_ events: [GameEvent]) {
        for event in events {
            switch event {
            case .line(let line):
                showBubble(Bubble(line: line))
            case .reaction(let character, let emoji):
                showReaction(Reaction(character: character, emoji: emoji))
            case .puzzleOpened(let puzzleID):
                if let opened = world.puzzle(puzzleID) {
                    puzzle = opened
                    puzzleMisses = 0
                }
            case .puzzleSolved:
                puzzle = nil
                puzzleMisses = 0
            case .hint(let id, let level, let text, let hasMore):
                hint = HintCard(id: id, level: level, text: text, hasMore: hasMore)
            case .stageCleared(let stageID):
                flashStage(stageID)
            case .finished(let summary):
                ending = summary
                phase = .ending
            case .blocked(let text):
                showBubble(Bubble(line: .narration(text)))
            case .itemAdded, .itemRemoved, .crafted, .selection,
                 .roomChanged, .stageStarted, .puzzleMissed:
                break
            }
        }
        refresh()
    }

    private func refresh() {
        room = engine.currentRoom
        stage = engine.currentStage
        inventory = engine.inventory
        selected = engine.selectedItem
        hotspots = engine.visibleHotspots()
        clearedStages = engine.state.clearedStages
        hasSave = saveStore.load() != nil
    }

    private func showBubble(_ newBubble: Bubble) {
        bubble = newBubble
        bubbleWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.bubble?.id == newBubble.id {
                self.bubble = nil
            }
        }
        bubbleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.6, execute: work)
    }

    private func showReaction(_ newReaction: Reaction) {
        reaction = newReaction
        reactionWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.reaction?.id == newReaction.id {
                self.reaction = nil
            }
        }
        reactionWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4, execute: work)
    }

    private func flashStage(_ stageID: StageID) {
        stageFlash = stageID
        flashWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.stageFlash == stageID {
                self.stageFlash = nil
            }
        }
        flashWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: work)
    }
}
