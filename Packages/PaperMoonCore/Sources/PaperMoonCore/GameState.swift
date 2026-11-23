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

    // 스테이지 2
    public static let readSign = "greenhouse.readSign"
    public static let waterFlowing = "greenhouse.waterFlowing"
    public static let seedPlanted = "greenhouse.seedPlanted"
    public static let vineGrown = "greenhouse.vineGrown"
    public static let shardFound = "greenhouse.shardFound"
    public static let readMoss = "greenhouse.readMoss"

    // 스테이지 3
    public static let gearsSolved = "tower.gearsSolved"
    public static let gearTaken = "tower.gearTaken"
    public static let clockWound = "tower.clockWound"
    public static let moonRestored = "tower.moonRestored"
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
        clearedStages: Set<StageID> = []
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
    }

    public static func newGame(at date: Date) -> GameState {
        GameState(startedAt: date)
    }

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
}

/// 엔딩 화면에 보여 줄 플레이 요약.
public struct GameSummary: Equatable, Sendable {
    public let seconds: Double
    public let hintsUsed: Int
    public let clearedStages: Int
    public let craftedCount: Int
    public let itemCount: Int

    public init(
        seconds: Double,
        hintsUsed: Int,
        clearedStages: Int,
        craftedCount: Int,
        itemCount: Int
    ) {
        self.seconds = seconds
        self.hintsUsed = hintsUsed
        self.clearedStages = clearedStages
        self.craftedCount = craftedCount
        self.itemCount = itemCount
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
}
