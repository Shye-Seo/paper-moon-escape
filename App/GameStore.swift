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
        case bonusEnding
        /// 엔딩 뒤에 열리는 다락방 놀이방.
        case playroom
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

    /// 먼지를 닦는 중인 판. 화면이 이 값을 그대로 그린다.
    struct DustSession: Identifiable {
        let id: String
        let panel: DustPanel
        var puzzle: DustWipePuzzle
        var isRevealed: Bool
    }

    /// 스크랩북 한 칸.
    struct ScrapbookEntry: Identifiable {
        let id: String
        let collectible: Collectible
        let collected: Bool
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
    @Published private(set) var bonusEndingSummary: GameSummary?
    @Published private(set) var clearedStages: Set<StageID>
    @Published private(set) var hasSave: Bool
    @Published private(set) var puzzleMisses: Int = 0
    @Published private(set) var stageFlash: StageID?

    /// 지금 조종 중인 캐릭터.
    @Published private(set) var character: PlayableCharacter = .momo
    /// 이 방에서 아직 찾지 못한 탐색 지점.
    @Published private(set) var searches: [SearchSpot] = []
    /// 탐색 지점별로 지금까지 빗나간 횟수.
    @Published private(set) var searchProgress: [String: Int] = [:]
    /// 종이접기 퍼즐에서 지금까지 접은 순서.
    @Published private(set) var foldSteps: [Int] = []
    /// 닿는 탐색 지점이 바뀌었을 때 화면에 띄우는 한 줄.
    @Published private(set) var searchFlash: String?

    /// 이 방에서 아직 줍지 않은 종이학·우표.
    @Published private(set) var collectibles: [Collectible] = []
    @Published private(set) var craneCount: Int = 0
    @Published private(set) var stampCount: Int = 0
    let craneGoal: Int = GameState.craneGoal
    /// 닦는 중인 먼지 판.
    @Published private(set) var dust: DustSession?
    /// 먼지를 다 닦았을 때 잠깐 보여 줄 문구.
    @Published private(set) var dustFlash: String?

    // MARK: 상점과 스크랩북

    @Published private(set) var entitlements: Entitlements = .full
    @Published private(set) var showingShop = false
    @Published private(set) var shopReason: String?
    @Published private(set) var promptedProduct: StoreProduct?
    @Published private(set) var showingScrapbook = false
    @Published private(set) var secretGift: SecretGift?
    @Published private(set) var bonusEndingStage: Stage?

    // MARK: 놀이방

    /// 본편을 깬 뒤에만 열린다.
    @Published private(set) var playroomUnlocked = false
    @Published private(set) var miniGameRecords = MiniGameRecords()

    let world: World

    // MARK: 내부

    private var engine: GameEngine
    private let saveStore: SaveStore
    private var bubbleWork: DispatchWorkItem?
    private var reactionWork: DispatchWorkItem?
    private var flashWork: DispatchWorkItem?
    private var dustFlashWork: DispatchWorkItem?
    private var searchFlashWork: DispatchWorkItem?

    init(
        world: World = .paperMoon,
        engine: GameEngine? = nil,
        saveStore: SaveStore? = nil
    ) {
        let resolvedStore = saveStore ?? UserDefaultsSaveStore()
        self.world = world
        self.saveStore = resolvedStore
        // 앱은 무료 체험(1장면)으로 시작하고, StoreKit이 확인되면 잠금이 열린다.
        self.engine = engine ?? GameEngine(world: world, store: resolvedStore, entitlements: .trial)
        self.room = self.engine.currentRoom
        self.stage = self.engine.currentStage
        self.inventory = self.engine.inventory
        self.selected = self.engine.selectedItem
        self.hotspots = self.engine.visibleHotspots()
        self.clearedStages = self.engine.state.clearedStages
        self.hasSave = resolvedStore.load() != nil
        self.character = self.engine.activeCharacter
        self.collectibles = self.engine.visibleCollectibles
        self.searches = self.engine.visibleSearches()
        self.searchProgress = self.engine.state.searchTries
        self.craneCount = self.engine.state.collectedCranes
        self.stampCount = self.engine.state.collectedStamps
        self.playroomUnlocked = self.engine.playroomUnlocked
        self.miniGameRecords = self.engine.miniGameRecords
        self.entitlements = self.engine.entitlements
    }

    // MARK: 구매 상태

    /// StoreKit(또는 개발용 토글)에서 바뀐 잠금을 엔진에 옮긴다.
    func applyEntitlements(_ value: Entitlements) {
        guard value != entitlements else { return }
        entitlements = value
        engine.setEntitlements(value)
        refresh()
    }

    func openShop(reason: String? = nil) {
        shopReason = reason
        showingShop = true
    }

    func closeShop() {
        showingShop = false
        shopReason = nil
        promptedProduct = nil
    }

    func dismissPurchasePrompt() {
        promptedProduct = nil
    }

    // MARK: 화면 이동

    func startNewGame() {
        _ = engine.restartGame()
        ending = nil
        bonusEndingSummary = nil
        puzzle = nil
        hint = nil
        dust = nil
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
        dust = nil
        refresh()
    }

    func enter(_ stageID: StageID) {
        handle(engine.start(stage: stageID))
        if phase != .playing {
            phase = .playing
        }
    }

    /// 보너스 지하실로 들어간다. 본편 기록은 그대로 두고 지하실만 새로 시작한다.
    func enterBonusChapter() {
        handle(engine.start(stage: .cellar))
        if phase != .playing {
            phase = .playing
        }
    }

    func isStageUnlocked(_ stageID: StageID) -> Bool {
        engine.canEnter(stage: stageID)
    }

    func stageLockText(_ stageID: StageID) -> String? {
        engine.lockReason(for: stageID)
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

    func toggleCharacter() {
        handle(engine.toggleCharacter())
    }

    func collect(_ collectible: Collectible) {
        handle(engine.collect(collectible.id))
    }

    // MARK: 탐색과 접기

    /// 꼼꼼히 더듬어 본다. 빗나가면 관찰 문장이, 찾으면 아이템이 온다.
    func search(_ spot: SearchSpot) {
        handle(engine.search(spot.id))
    }

    /// 이 자리를 몇 번이나 빗나갔는지.
    func searchTries(_ spot: SearchSpot) -> Int {
        searchProgress[spot.id] ?? 0
    }

    /// 종이를 한 번 접는다. 틀리면 접힘이 풀린다.
    func fold(step: Int) {
        guard let puzzle else { return }
        handle(engine.foldStep(puzzle.id, step: step))
    }

    /// 손으로 펼쳐 처음부터.
    func resetFolds() {
        guard let puzzle else { return }
        handle(engine.clearFolds(puzzle.id))
    }

    // MARK: 놀이방

    func openPlayroom() {
        guard playroomUnlocked else { return }
        phase = .playroom
    }

    func closePlayroom() {
        phase = .title
    }

    func recordMemoryResult(difficulty: MiniGameDifficulty, moves: Int, seconds: Double, stars: Int) {
        _ = engine.recordMemoryResult(difficulty: difficulty, moves: moves, seconds: seconds, stars: stars)
        miniGameRecords = engine.miniGameRecords
    }

    func recordChallengeResult(difficulty: MiniGameDifficulty, completed: Int, seconds: Double, stars: Int) {
        _ = engine.recordChallengeResult(difficulty: difficulty, completed: completed, seconds: seconds, stars: stars)
        miniGameRecords = engine.miniGameRecords
    }

    func miniGameRecord(for id: MiniGameID, difficulty: MiniGameDifficulty) -> MiniGameRecord? {
        miniGameRecords.record(for: id, difficulty: difficulty)
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
        foldSteps = []
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
        bonusEndingSummary = nil
        _ = engine.restartGame()
        phase = .playing
        showBubble(Bubble(line: .narration("비 오는 다락방으로 다시 돌아왔다.")))
        refresh()
    }

    // MARK: 스크랩북과 비밀 서랍

    func openScrapbook() {
        showingScrapbook = true
    }

    func closeScrapbook() {
        showingScrapbook = false
    }

    var scrapbookEntries: [ScrapbookEntry] {
        world.collectiblesInOrder.map { collectible in
            ScrapbookEntry(
                id: collectible.id.rawValue,
                collectible: collectible,
                collected: engine.state.hasCollected(collectible.id)
            )
        }
    }

    var canOpenSecretDrawer: Bool {
        engine.state.hasAllCranes
    }

    var hasOpenedSecretDrawer: Bool {
        engine.state.secretDrawerOpened
    }

    func openSecretDrawer() {
        handle(engine.openSecretDrawer())
    }

    func closeSecretGift() {
        secretGift = nil
    }

    // MARK: 먼지 닦기

    /// 화면의 드래그·탭을 판 위 좌표로 옮긴다. 다 닦이면 바로 엔진에 알린다.
    func wipeDust(at point: ScenePoint) {
        guard var session = dust else { return }
        let cleared = session.puzzle.wipe(at: point)
        session.isRevealed = cleared
        if cleared {
            dust = session
            finishDust(session)
        } else {
            dust = session
        }
    }

    /// 흔들기 한 번. 문지르기보다 약하지만 여러 번이면 닦인다.
    func shakeDust() {
        guard var session = dust else { return }
        let cleared = session.puzzle.shake()
        session.isRevealed = cleared
        if cleared {
            dust = session
            finishDust(session)
        } else {
            dust = session
        }
    }

    /// 손을 쓰기 어려운 환경의 대안. 한 번에 다 닦는다.
    func sweepDustByHand() {
        guard var session = dust else { return }
        _ = session.puzzle.wipeAll()
        session.isRevealed = true
        dust = session
        finishDust(session)
    }

    func closeDust() {
        dust = nil
    }

    private func finishDust(_ session: DustSession) {
        let events = engine.completeDustPanel(session.panel.id)
        dust = nil
        handle(events)
        showDustFlash("\(session.panel.title)을(를) 다 닦았다.")
    }

    // MARK: 읽기 도우미

    func itemName(_ id: ItemID) -> String {
        world.itemName(id)
    }

    func stageInfo(for id: StageID) -> Stage? {
        world.stage(id)
    }

    var stageList: [Stage] {
        world.mainStages
    }

    var bonusStage: Stage? {
        world.bonusStages.first
    }

    var hasFinishedMainStory: Bool {
        engine.state.clearedStages.contains(.clocktower)
    }

    var elapsedText: String {
        let seconds = Int(engine.state.elapsedSeconds(now: Date()))
        let minutes = seconds / 60
        let rest = seconds % 60
        return "\(minutes)분 \(rest)초"
    }

    var hintsRemaining: Int? {
        engine.hintsRemaining
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
                    foldSteps = engine.foldProgress(puzzleID)
                }
            case .puzzleSolved:
                puzzle = nil
                puzzleMisses = 0
                foldSteps = []
            case .hint(let id, let level, let text, let hasMore):
                hint = HintCard(id: id, level: level, text: text, hasMore: hasMore)
            case .stageCleared(let stageID):
                flashStage(stageID)
            case .finished(let summary):
                ending = summary
                phase = .ending
            case .bonusEnding(let stageID, let summary):
                bonusEndingSummary = summary
                bonusEndingStage = world.stage(stageID)
                phase = .bonusEnding
            case .characterChanged(let newCharacter):
                character = newCharacter
            case .collectibleFound:
                break
            case .secretDrawerUnlocked:
                break
            case .secretDrawerOpened(let gift):
                secretGift = gift
            case .dustPanelOpened(let panelID):
                if let panel = world.dustPanel(panelID) {
                    dust = DustSession(
                        id: panel.id,
                        panel: panel,
                        puzzle: DustWipePuzzle(panel: panel),
                        isRevealed: false
                    )
                }
            case .dustCleared:
                dust = nil
            case .purchaseRequired(let product, let reason):
                promptedProduct = product
                shopReason = reason
                showingShop = true
            case .blocked(let text):
                showBubble(Bubble(line: .narration(text)))
            case .searchMissed(let id, let attempt, let ceiling):
                if let spot = world.searchSpot(id) {
                    showSearchFlash("\(spot.label) · \(attempt)/\(ceiling)번째 더듬기")
                }
                searchProgress = engine.state.searchTries
            case .searchFound(let id):
                if let spot = world.searchSpot(id) {
                    showSearchFlash("\(spot.label)에서 무언가 찾았다")
                }
                searchProgress = engine.state.searchTries
            case .foldAccepted(let puzzleID, let position):
                foldSteps = engine.foldProgress(puzzleID)
                if position > 0, let opened = world.puzzle(puzzleID) {
                    showSearchFlash("\(position)/\(opened.solution.count) 접기 · \(opened.title)")
                }
            case .foldUnfolded(let puzzleID, _):
                foldSteps = engine.foldProgress(puzzleID)
                showSearchFlash("접힘이 풀렸다. 처음부터 다시")
            case .foldCleared(let puzzleID):
                foldSteps = engine.foldProgress(puzzleID)
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
        character = engine.activeCharacter
        collectibles = engine.visibleCollectibles
        searches = engine.visibleSearches()
        searchProgress = engine.state.searchTries
        craneCount = engine.state.collectedCranes
        stampCount = engine.state.collectedStamps
        playroomUnlocked = engine.playroomUnlocked
        miniGameRecords = engine.miniGameRecords
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

    private func showDustFlash(_ text: String) {
        dustFlash = text
        dustFlashWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.dustFlash == text {
                self.dustFlash = nil
            }
        }
        dustFlashWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4, execute: work)
    }

    /// 탐색·접기 진행을 잠깐 띄우는 한 줄.
    private func showSearchFlash(_ text: String) {
        searchFlash = text
        searchFlashWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.searchFlash == text {
                self.searchFlash = nil
            }
        }
        searchFlashWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }
}
