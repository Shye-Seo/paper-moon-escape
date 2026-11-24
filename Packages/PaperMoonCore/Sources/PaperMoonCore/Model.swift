import Foundation

// MARK: - 식별자

/// 본편 세 장면과, 본편을 깬 뒤에 열리는 보너스 장면 하나.
/// 저장 데이터에는 원시값(String)으로 기록된다.
public enum StageID: String, Codable, CaseIterable, Hashable, Sendable {
    case attic
    case greenhouse
    case clocktower
    /// 「비밀 다락방 지하실」 보너스 4장면.
    case cellar

    /// 본편을 처음부터 끝까지 잇는 순서. 보너스 장면은 여기 들어가지 않는다.
    public static let mainline: [StageID] = [.attic, .greenhouse, .clocktower]

    public var isBonus: Bool { self == .cellar }
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

    case cellarSteps
    case cellarPantry
    case cellarVault
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

    // 1장면 · 종이접기와 등불
    case paperSheet
    case paperMoonLamp
    case candleStub
    case moonLamp

    // 보너스 장면 · 지하실
    case vellumPage
    case oilLamp
    case rustyHandle
    case paperBoat
    case vaultKey
}

/// 화면에서 만질 수 있는 모든 지점.
/// `highShelf`·`mouseHole`·`pondShelf`·`fireflies`·`gearPile`·`brickNook`은
/// 한 번 누르면 바로 나오던 예전 지점으로, 지금은 `SearchSpot`(여러 번 더듬는 자리)으로 옮겼다.
/// 값은 예전 저장 파일의 `claimedHotspots`를 읽을 수 있게 그대로 둔다.
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

    // 1장면 · 캐릭터 협동
    case highShelf
    case foldingDesk
    case mouseHole

    // 2장면 · 캐릭터 협동과 빛 투과
    case hangingPot
    case tornPaperWindow

    // 3장면 · 먼지 닦기
    case dustyMirror
    case gearLoft

    // 보너스 장면 · 지하실
    case ironGateLatch
    case brickNook
    case oilLampHook
    case paperCrate
    case foldingStool
    case tornLabel
    case floodedDrain
    case moonVault
    case oldAlbum
    case vaultLedger
    case cellarSign
    case wineRack
}

/// 미니게임 퍼즐. 본편 세 가지에 종이접기·빛 투과 퍼즐과 보너스 장면 퍼즐이 더해진다.
public enum PuzzleID: String, Codable, CaseIterable, Hashable, Sendable {
    case toyBlocks
    case frogSong
    case gearDials

    /// 1장면 · 종이 도면을 접어 종이달 등불을 만든다.
    case paperMoonOrigami
    /// 2장면 · 찢어진 종이를 맞추고 랜턴 빛으로 숨은 글자를 읽는다.
    case tornPaperCode
    /// 보너스 장면 · 양피지를 접어 종이배를 만든다.
    case cellarBoat
    /// 보너스 장면 · 포도주 라벨의 찢긴 종이를 맞추고 기름등잔 빛으로 암호를 읽는다.
    case cellarVaultCode

    public var isOrigami: Bool {
        self == .paperMoonOrigami || self == .cellarBoat
    }
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
    case cellarStairs
    case cellarPantry
    case cellarVault
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
    /// 먼지를 닦는 판을 연다. 판 id는 `DustPanel.id`와 같다.
    case openDust(String)
    case clearStage
}

extension Effect {
    /// 이 효과가 "한 번만" 일어나야 하는 종류인지. 그런 지점은 다시 만지면 반복 대사를 보여 준다.
    public var isClaiming: Bool {
        switch self {
        case .give, .openPuzzle, .clearStage:
            return true
        case .say, .react, .take, .flag, .unflag, .openDust:
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
    /// 이 지점에 손이 닿는 캐릭터. nil이면 둘 다 된다.
    public let requiredCharacter: PlayableCharacter?
    /// 다른 캐릭터로 눌렀을 때의 코지한 안내. 없으면 기본 안내를 쓴다.
    public let characterNote: String?

    public init(
        id: HotspotID,
        room: RoomID,
        label: String,
        glyph: String,
        position: ScenePoint,
        requires: [Requirement] = [],
        blocked: String? = nil,
        requiredCharacter: PlayableCharacter? = nil,
        characterNote: String? = nil,
        effects: [Effect] = [],
        itemReactions: [ItemReaction] = [],
        mismatchText: String? = nil,
        hiddenWhen: [Requirement] = [],
        repeatText: String? = nil
    ) {
        self.id = id
        self.room = room
        self.label = label
        self.glyph = glyph
        self.position = position
        self.requires = requires
        self.blocked = blocked
        self.requiredCharacter = requiredCharacter
        self.characterNote = characterNote
        self.effects = effects
        self.itemReactions = itemReactions
        self.mismatchText = mismatchText
        self.hiddenWhen = hiddenWhen
        self.repeatText = repeatText
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
    /// 화면의 종이를 순서대로 접어 모양을 만드는 퍼즐. 스와이프·탭 둘 다 된다.
    case origami
    /// 찢어진 종잇조각을 제자리에 맞춘 뒤 빛을 비춰 숨은 글자를 읽는 퍼즐.
    case lightReveal

    public var isTouchGesture: Bool {
        self == .origami || self == .lightReveal
    }
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
    /// 완성하면 만들어지는 것의 이름. 종이접기·빛 투과 퍼즐의 목표 표시에 쓴다.
    public let goal: String?
    /// 빛 투과 퍼즐에서 빛을 비추면 드러나는 문장(숨은 암호).
    public let revealedCode: String?
    /// 빛 투과 퍼즐에 필요한 빛 도구.
    public let lightSource: ItemID?
    /// 잘못 접었을 때의 문장. 없으면 `retryText`를 쓴다.
    public let resetText: String?

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
        rewards: [Effect],
        goal: String? = nil,
        revealedCode: String? = nil,
        lightSource: ItemID? = nil,
        resetText: String? = nil
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
        self.goal = goal
        self.revealedCode = revealedCode
        self.lightSource = lightSource
        self.resetText = resetText
    }

    /// 종잇조각이 몇 개인지. 빛 투과 퍼즐 화면이 조각 배치를 그릴 때 쓴다.
    public var pieceCount: Int { tokens.count }
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
    /// 본편이 아니라 유료로 여는 보너스 장면인지. 보너스는 엔딩 요약 대신 자기 엔딩을 연다.
    public let isBonus: Bool

    public init(
        id: StageID,
        number: Int,
        title: String,
        subtitle: String,
        rooms: [RoomID],
        opening: String,
        closing: String,
        next: StageID?,
        isBonus: Bool = false
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.subtitle = subtitle
        self.rooms = rooms
        self.opening = opening
        self.closing = closing
        self.next = next
        self.isBonus = isBonus
    }
}
