import Foundation

// MARK: - 식별자

/// 세 개의 스테이지. 저장 데이터에는 원시값(String)으로 기록된다.
public enum StageID: String, Codable, CaseIterable, Hashable, Sendable {
    case attic
    case greenhouse
    case clocktower
}

/// 스테이지마다 세 개의 방. 좌우 화살표로 오간다.
public enum RoomID: String, Codable, CaseIterable, Hashable, Sendable {
    case atticLanding
    case atticToyCloset
    case atticMoonWindow

    case greenhouseVines
    case greenhousePond
    case greenhouseGlass

    case towerStairs
    case towerGears
    case towerBelfry
}

/// 인벤토리에 담기는 모든 물건.
public enum ItemID: String, Codable, CaseIterable, Hashable, Sendable {
    case keyShardOval
    case keyShardTooth
    case brokenKey
    case glueBottle
    case mendedKey

    case seed
    case wateringCan
    case emptyJar
    case firefly
    case lantern
    case paperMoonShard

    case windKey
    case gear
    case clockPart
}

/// 화면에서 만질 수 있는 모든 지점.
public enum HotspotID: String, Codable, CaseIterable, Hashable, Sendable {
    case rockingHorse
    case owlClock
    case atticLadder
    case paperCrane

    case toyBox
    case blockPoster
    case blockPile
    case toyShelf

    case moonLatch
    case paperMoonMobile
    case rainyWindow
    case curtain

    case flowerPot
    case seedPouch
    case wateringCanCorner
    case vineGate
    case signpost

    case frogChorus
    case pondShelf
    case fireflies
    case stoneSteps
    case lilyPad

    case moonShardBranch
    case upsideTree
    case glassWindow
    case mossNote

    case pendulum
    case woodBox
    case towerWindow
    case paperBat

    case dialPanel
    case clockFace
    case gearPile
    case windSocket
    case shadowKeeper

    case paperBell
    case starPaper
    case belfryView
}

/// 미니게임 퍼즐 세 가지.
public enum PuzzleID: String, Codable, CaseIterable, Hashable, Sendable {
    case toyBlocks
    case frogSong
    case gearDials
}

/// 말풍선 리액션을 하는 캐릭터.
public enum CharacterID: String, Codable, CaseIterable, Hashable, Sendable {
    case momo
    case pico
    case owl
    case frog
    case keeper
}

/// 방의 그림 종류. App 레이어의 Canvas 일러스트가 이 값을 보고 장면을 고른다.
public enum RoomArt: String, Codable, Hashable, Sendable {
    case atticLanding
    case toyCloset
    case moonWindow
    case vineGate
    case frogPond
    case glassHouse
    case gearStairs
    case gearRoom
    case belfry
}

// MARK: - 대사

/// 화면에 흐르는 한 줄의 대사. 화자에 따라 말풍선 모양과 이름표가 달라진다.
public enum Line: Equatable, Sendable {
    case narration(String)
    case momo(String)
    case pico(String)
    case creature(name: String, text: String)

    public var text: String {
        switch self {
        case .narration(let text): return text
        case .momo(let text): return text
        case .pico(let text): return text
        case .creature(_, let text): return text
        }
    }
}

// MARK: - 조건과 효과

/// 어떤 상호작용이 열리기 위한 조건.
public enum Requirement: Equatable, Sendable {
    case flag(String)
    case notFlag(String)
    case item(ItemID)
    case solved(PuzzleID)
    case cleared(StageID)
}

/// 상호작용이 일으키는 변화. 월드 데이터는 이 값들의 목록일 뿐이고,
/// 해석은 전부 `GameEngine`이 한다.
public enum Effect: Equatable, Sendable {
    case say(Line)
    case react(CharacterID, String)
    case give(ItemID)
    case take(ItemID)
    case flag(String)
    case unflag(String)
    case openPuzzle(PuzzleID)
    case clearStage
}

extension Effect {
    /// 이 효과가 "한 번만" 일어나야 하는 종류인지. 그런 지점은 다시 만지면 반복 대사를 보여 준다.
    public var isClaiming: Bool {
        switch self {
        case .give, .openPuzzle, .clearStage:
            return true
        case .say, .react, .take, .flag, .unflag:
            return false
        }
    }
}

/// 이미 고른 아이템을 지점에 쓸 때의 규칙.
public struct ItemReaction: Equatable, Sendable {
    public let item: ItemID
    public let consume: Bool
    public let requires: [Requirement]
    public let blocked: String?
    public let text: String
    public let effects: [Effect]

    public init(
        item: ItemID,
        consume: Bool,
        requires: [Requirement] = [],
        blocked: String? = nil,
        text: String,
        effects: [Effect] = []
    ) {
        self.item = item
        self.consume = consume
        self.requires = requires
        self.blocked = blocked
        self.text = text
        self.effects = effects
    }
}

// MARK: - 방과 지점

/// 방에 걸린 잠금. 좌우 이동으로 들어갈 때 조건을 확인한다.
public struct Lock: Equatable, Sendable {
    public let requirement: Requirement
    public let message: String

    public init(_ requirement: Requirement, message: String) {
        self.requirement = requirement
        self.message = message
    }
}

public struct Room: Identifiable, Equatable, Sendable {
    public let id: RoomID
    public let stage: StageID
    public let title: String
    public let caption: String
    public let art: RoomArt
    public let lock: Lock?

    public init(
        id: RoomID,
        stage: StageID,
        title: String,
        caption: String,
        art: RoomArt,
        lock: Lock? = nil
    ) {
        self.id = id
        self.stage = stage
        self.title = title
        self.caption = caption
        self.art = art
        self.lock = lock
    }
}

/// 씬 위의 좌표. (0,0)은 왼쪽 위, (1,1)은 오른쪽 아래.
public struct ScenePoint: Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

/// 포인트 앤 클릭 지점 하나.
public struct Hotspot: Identifiable, Equatable, Sendable {
    public let id: HotspotID
    public let room: RoomID
    public let label: String
    public let glyph: String
    public let position: ScenePoint
    public let requires: [Requirement]
    public let blocked: String?
    public let effects: [Effect]
    public let itemReactions: [ItemReaction]
    public let mismatchText: String?
    public let repeatText: String?
    public let hiddenWhen: [Requirement]

    public init(
        id: HotspotID,
        room: RoomID,
        label: String,
        glyph: String,
        position: ScenePoint,
        requires: [Requirement] = [],
        blocked: String? = nil,
        effects: [Effect] = [],
        itemReactions: [ItemReaction] = [],
        mismatchText: String? = nil,
        repeatText: String? = nil,
        hiddenWhen: [Requirement] = []
    ) {
        self.id = id
        self.room = room
        self.label = label
        self.glyph = glyph
        self.position = position
        self.requires = requires
        self.blocked = blocked
        self.effects = effects
        self.itemReactions = itemReactions
        self.mismatchText = mismatchText
        self.repeatText = repeatText
        self.hiddenWhen = hiddenWhen
    }
}

// MARK: - 아이템과 조합

public struct Item: Identifiable, Equatable, Sendable {
    public let id: ItemID
    public let name: String
    public let glyph: String
    public let note: String

    public init(id: ItemID, name: String, glyph: String, note: String) {
        self.id = id
        self.name = name
        self.glyph = glyph
        self.note = note
    }
}

/// 아이템 두 개를 합쳐 새 아이템을 만드는 규칙.
public struct Combo: Equatable, Sendable {
    public let a: ItemID
    public let b: ItemID
    public let result: ItemID
    public let text: String
    public let flag: String?

    public init(a: ItemID, b: ItemID, result: ItemID, text: String, flag: String? = nil) {
        self.a = a
        self.b = b
        self.result = result
        self.text = text
        self.flag = flag
    }

    public func matches(_ first: ItemID, _ second: ItemID) -> Bool {
        (a == first && b == second) || (a == second && b == first)
    }
}

// MARK: - 퍼즐

public enum PuzzleKind: String, Codable, Hashable, Sendable {
    /// 색 블록을 순서대로 놓는 퍼즐.
    case blocks
    /// 개구리 음계를 순서대로 따라 부르는 퍼즐.
    case song
    /// 다이얼 세 개의 방향을 맞추는 퍼즐.
    case dials
}

public struct PuzzleToken: Equatable, Sendable {
    public let value: Int
    public let label: String
    public let symbol: String

    public init(value: Int, label: String, symbol: String) {
        self.value = value
        self.label = label
        self.symbol = symbol
    }
}

public struct Puzzle: Identifiable, Equatable, Sendable {
    public let id: PuzzleID
    public let kind: PuzzleKind
    public let title: String
    public let prompt: String
    public let clue: String
    public let tokens: [PuzzleToken]
    public let solution: [Int]
    public let slotLabels: [String]
    public let successText: String
    public let retryText: String
    public let rewards: [Effect]

    public init(
        id: PuzzleID,
        kind: PuzzleKind,
        title: String,
        prompt: String,
        clue: String,
        tokens: [PuzzleToken],
        solution: [Int],
        slotLabels: [String],
        successText: String,
        retryText: String,
        rewards: [Effect]
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.prompt = prompt
        self.clue = clue
        self.tokens = tokens
        self.solution = solution
        self.slotLabels = slotLabels
        self.successText = successText
        self.retryText = retryText
        self.rewards = rewards
    }
}

// MARK: - 힌트

/// 한 스테이지의 목표 하나에 대한 2단계 힌트.
public struct Hint: Identifiable, Equatable, Sendable {
    public let id: String
    public let stage: StageID
    public let doneIf: Requirement
    public let levelOne: String
    public let levelTwo: String

    public init(
        id: String,
        stage: StageID,
        doneIf: Requirement,
        levelOne: String,
        levelTwo: String
    ) {
        self.id = id
        self.stage = stage
        self.doneIf = doneIf
        self.levelOne = levelOne
        self.levelTwo = levelTwo
    }
}

// MARK: - 스테이지

public struct Stage: Identifiable, Equatable, Sendable {
    public let id: StageID
    public let number: Int
    public let title: String
    public let subtitle: String
    public let rooms: [RoomID]
    public let opening: String
    public let closing: String
    public let next: StageID?

    public init(
        id: StageID,
        number: Int,
        title: String,
        subtitle: String,
        rooms: [RoomID],
        opening: String,
        closing: String,
        next: StageID?
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.subtitle = subtitle
        self.rooms = rooms
        self.opening = opening
        self.closing = closing
        self.next = next
    }
}
