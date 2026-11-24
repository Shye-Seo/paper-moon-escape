import Foundation

/// 진행 상황을 표시하는 플래그 이름 모음. 저장 데이터에는 문자열로 남는다.
public enum Flags {
    // 스테이지 1
    public static let horseRocked = "attic.horseRocked"
    public static let owlAwake = "attic.owlAwake"
    public static let sawPoster = "attic.sawPoster"
    public static let toyBoxOpen = "attic.toyBoxOpen"
    public static let keyMended = "attic.keyMended"
    public static let moonOpened = "attic.moonOpened"
    public static let sawMoonGap = "attic.sawMoonGap"
    public static let readCurtainNote = "attic.readCurtainNote"

    // 스테이지 1 · 종이접기와 종이달 등불
    public static let paperSheetTaken = "attic.paperSheetTaken"
    public static let origamiMoon = "attic.origamiMoon"
    public static let candleStubTaken = "attic.candleStubTaken"
    public static let lampLit = "attic.lampLit"

    // 스테이지 2
    public static let readSign = "greenhouse.readSign"
    public static let waterFlowing = "greenhouse.waterFlowing"
    public static let seedPlanted = "greenhouse.seedPlanted"
    public static let vineGrown = "greenhouse.vineGrown"
    public static let shardFound = "greenhouse.shardFound"
    public static let readMoss = "greenhouse.readMoss"

    // 스테이지 2 · 빛 투과
    public static let sawHangingPot = "greenhouse.sawHangingPot"
    public static let lightCodeSeen = "greenhouse.lightCodeSeen"

    // 스테이지 3
    public static let gearsSolved = "tower.gearsSolved"
    public static let gearTaken = "tower.gearTaken"
    public static let clockWound = "tower.clockWound"
    public static let moonRestored = "tower.moonRestored"

    // 스테이지 3 · 먼지 닦기
    public static let mirrorWiped = "tower.mirrorWiped"
    public static let sawGearLoft = "tower.sawGearLoft"

    // 보너스 장면 · 비밀 다락방 지하실
    public static let cellarGateOpen = "cellar.gateOpen"
    public static let vellumTaken = "cellar.vellumTaken"
    public static let boatFolded = "cellar.boatFolded"
    public static let vaultCodeSeen = "cellar.vaultCodeSeen"
    public static let vaultKeyTaken = "cellar.vaultKeyTaken"
    public static let cellarLedgerRead = "cellar.ledgerRead"

    // 수집과 비밀 서랍
    public static let cranesComplete = "collection.cranesComplete"
    public static let secretDrawer = "collection.secretDrawer"
}

/// 한 판의 진행 상태. 통째로 저장되고 통째로 복원된다.
public struct GameState: Codable, Equatable, Sendable {
    public var stage: StageID
    public var room: RoomID
    public var inventory: [ItemID]
    public var flags: Set<String>
    public var solvedPuzzles: Set<PuzzleID>
    public var claimedHotspots: Set<HotspotID>
    public var hintLevels: [String: Int]
    public var puzzleAttempts: [String: Int]
    public var hintsUsed: Int
    public var craftedCount: Int
    public var selectedItem: ItemID?
    public var startedAt: Date
    public var finishedAt: Date?
    public var finished: Bool
    public var clearedStages: Set<StageID>

    /// 지금 조종 중인 캐릭터. 모모 ↔ 피코.
    public var activeCharacter: PlayableCharacter
    /// 스크랩북에 붙인 수집품(종이학·우표).
    public var collected: Set<CollectibleID>
    /// 종이학 열두 마리를 모아 연 비밀 서랍을 이미 열었는지.
    public var secretDrawerOpened: Bool

    public init(
        stage: StageID = .attic,
        room: RoomID = .atticLanding,
        inventory: [ItemID] = [],
        flags: Set<String> = [],
        solvedPuzzles: Set<PuzzleID> = [],
        claimedHotspots: Set<HotspotID> = [],
        hintLevels: [String: Int] = [:],
        puzzleAttempts: [String: Int] = [:],
        hintsUsed: Int = 0,
        craftedCount: Int = 0,
        selectedItem: ItemID? = nil,
        startedAt: Date = Date(timeIntervalSince1970: 0),
        finishedAt: Date? = nil,
        finished: Bool = false,
        clearedStages: Set<StageID> = [],
        activeCharacter: PlayableCharacter = .momo,
        collected: Set<CollectibleID> = [],
        secretDrawerOpened: Bool = false
    ) {
        self.stage = stage
        self.room = room
        self.inventory = inventory
        self.flags = flags
        self.solvedPuzzles = solvedPuzzles
        self.claimedHotspots = claimedHotspots
        self.hintLevels = hintLevels
        self.puzzleAttempts = puzzleAttempts
        self.hintsUsed = hintsUsed
        self.craftedCount = craftedCount
        self.selectedItem = selectedItem
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.finished = finished
        self.clearedStages = clearedStages
        self.activeCharacter = activeCharacter
        self.collected = collected
        self.secretDrawerOpened = secretDrawerOpened
    }

    // MARK: 저장 호환

    private enum CodingKeys: String, CodingKey {
        case stage, room, inventory, flags, solvedPuzzles, claimedHotspots
        case hintLevels, puzzleAttempts, hintsUsed, craftedCount, selectedItem
        case startedAt, finishedAt, finished, clearedStages
        case activeCharacter, collected, secretDrawerOpened
    }

    /// 예전 저장 파일에는 없던 칸이 있으므로, 빠진 값은 기본값으로 채운다.
    /// 덕분에 11월 초에 저장한 판도 그대로 이어서 할 수 있다.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stage = try container.decodeIfPresent(StageID.self, forKey: .stage) ?? .attic
        room = try container.decodeIfPresent(RoomID.self, forKey: .room) ?? .atticLanding
        inventory = try container.decodeIfPresent([ItemID].self, forKey: .inventory) ?? []
        flags = try container.decodeIfPresent(Set<String>.self, forKey: .flags) ?? []
        solvedPuzzles = try container.decodeIfPresent(Set<PuzzleID>.self, forKey: .solvedPuzzles) ?? []
        claimedHotspots = try container.decodeIfPresent(Set<HotspotID>.self, forKey: .claimedHotspots) ?? []
        hintLevels = try container.decodeIfPresent([String: Int].self, forKey: .hintLevels) ?? [:]
        puzzleAttempts = try container.decodeIfPresent([String: Int].self, forKey: .puzzleAttempts) ?? [:]
        hintsUsed = try container.decodeIfPresent(Int.self, forKey: .hintsUsed) ?? 0
        craftedCount = try container.decodeIfPresent(Int.self, forKey: .craftedCount) ?? 0
        selectedItem = try container.decodeIfPresent(ItemID.self, forKey: .selectedItem)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
            ?? Date(timeIntervalSince1970: 0)
        finishedAt = try container.decodeIfPresent(Date.self, forKey: .finishedAt)
        finished = try container.decodeIfPresent(Bool.self, forKey: .finished) ?? false
        clearedStages = try container.decodeIfPresent(Set<StageID>.self, forKey: .clearedStages) ?? []
        activeCharacter = try container.decodeIfPresent(PlayableCharacter.self, forKey: .activeCharacter)
            ?? .momo
        collected = try container.decodeIfPresent(Set<CollectibleID>.self, forKey: .collected) ?? []
        secretDrawerOpened = try container.decodeIfPresent(Bool.self, forKey: .secretDrawerOpened) ?? false
    }

    public static func newGame(at date: Date) -> GameState {
        GameState(startedAt: date)
    }

    // MARK: 조회

    public func satisfies(_ requirement: Requirement) -> Bool {
        switch requirement {
        case .flag(let name):
            return flags.contains(name)
        case .notFlag(let name):
            return !flags.contains(name)
        case .item(let item):
            return inventory.contains(item)
        case .solved(let puzzle):
            return solvedPuzzles.contains(puzzle)
        case .cleared(let stage):
            return clearedStages.contains(stage)
        }
    }

    public func satisfiesAll(_ requirements: [Requirement]) -> Bool {
        requirements.allSatisfy { satisfies($0) }
    }

    public func attempts(for puzzle: PuzzleID) -> Int {
        puzzleAttempts[puzzle.rawValue] ?? 0
    }

    public func hintLevel(for id: String) -> Int {
        hintLevels[id] ?? 0
    }

    public func elapsedSeconds(now: Date) -> Double {
        let end = finishedAt ?? now
        let seconds = end.timeIntervalSince(startedAt)
        return seconds < 0 ? 0 : seconds
    }

    // MARK: 수집

    public var collectedCranes: Int {
        collected.filter { $0.kind == .crane }.count
    }

    public var collectedStamps: Int {
        collected.filter { $0.kind == .stamp }.count
    }

    public var hasAllCranes: Bool {
        collectedCranes >= GameState.craneGoal
    }

    public static let craneGoal: Int = 12

    public func hasCollected(_ id: CollectibleID) -> Bool {
        collected.contains(id)
    }
}

/// 엔딩 화면에 보여 줄 플레이 요약.
public struct GameSummary: Equatable, Sendable {
    public let seconds: Double
    public let hintsUsed: Int
    public let clearedStages: Int
    public let craftedCount: Int
    public let itemCount: Int
    public let collectedCranes: Int
    public let collectedStamps: Int

    public init(
        seconds: Double,
        hintsUsed: Int,
        clearedStages: Int,
        craftedCount: Int,
        itemCount: Int,
        collectedCranes: Int = 0,
        collectedStamps: Int = 0
    ) {
        self.seconds = seconds
        self.hintsUsed = hintsUsed
        self.clearedStages = clearedStages
        self.craftedCount = craftedCount
        self.itemCount = itemCount
        self.collectedCranes = collectedCranes
        self.collectedStamps = collectedStamps
    }

    public var craneText: String {
        "\(collectedCranes) / \(GameState.craneGoal)"
    }
}

/// 엔진이 돌려주는 사건 목록. 화면은 이 목록을 순서대로 소화한다.
public enum GameEvent: Equatable, Sendable {
    case line(Line)
    case reaction(CharacterID, String)
    case itemAdded(ItemID)
    case itemRemoved(ItemID)
    case crafted(result: ItemID, ingredients: [ItemID])
    case selection(ItemID?)
    case roomChanged(RoomID)
    case stageStarted(StageID)
    case stageCleared(StageID)
    case puzzleOpened(PuzzleID)
    case puzzleSolved(PuzzleID)
    case puzzleMissed(PuzzleID, attempts: Int)
    case hint(id: String, level: Int, text: String, hasMore: Bool)
    case blocked(String)
    case finished(GameSummary)

    /// 모모 ↔ 피코 전환.
    case characterChanged(PlayableCharacter)
    /// 스크랩북에 종이학·우표를 붙였다.
    case collectibleFound(CollectibleID)
    /// 열두 마리를 다 모아 비밀 서랍이 열릴 준비가 됐다.
    case secretDrawerUnlocked
    /// 비밀 서랍을 실제로 열었다.
    case secretDrawerOpened(SecretGift)
    /// 먼지 닦기 판을 연다.
    case dustPanelOpened(String)
    /// 먼지 닦기 판을 다 닦았다.
    case dustCleared(String)
    /// 유료 상품이 필요하다. 화면은 상점을 띄운다.
    case purchaseRequired(StoreProduct, String)
    /// 보너스 장면을 끝냈다.
    case bonusEnding(StageID, GameSummary)
}
