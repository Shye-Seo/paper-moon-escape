import Foundation

/// 스크랩북에 붙는 수집품의 종류. 종이학은 12마리를 다 모으면 비밀 서랍이 열리고,
/// 옛날 우표는 모으지 않아도 손해가 없는 곁다리 기록이다.
public enum CollectibleKind: String, Codable, CaseIterable, Hashable, Sendable {
    case crane
    case stamp

    public var displayName: String {
        switch self {
        case .crane: return "접힌 종이학"
        case .stamp: return "옛날 우표"
        }
    }
}

/// 본편 9개 방 곳곳에 숨겨 둔 수집품. 저장 데이터에는 원시값(String)으로 남는다.
public enum CollectibleID: String, Codable, CaseIterable, Hashable, Sendable {
    case craneAtticLanding
    case craneAtticLadder
    case craneToyCloset
    case craneToyShelf
    case craneMoonWindow

    case craneVines
    case cranePond
    case craneGlass
    case craneFirefly

    case craneStairs
    case craneGears
    case craneBelfry

    case stampAttic
    case stampGreenhouse
    case stampTower

    public var kind: CollectibleKind {
        switch self {
        case .stampAttic, .stampGreenhouse, .stampTower:
            return .stamp
        case .craneAtticLanding, .craneAtticLadder, .craneToyCloset, .craneToyShelf,
             .craneMoonWindow, .craneVines, .cranePond, .craneGlass, .craneFirefly,
             .craneStairs, .craneGears, .craneBelfry:
            return .crane
        }
    }

    /// 스크랩북에서 순서를 잡을 때 쓰는 값. 종이학이 먼저 온다.
    public var sortKey: Int {
        switch self {
        case .craneAtticLanding: return 1
        case .craneAtticLadder: return 2
        case .craneToyCloset: return 3
        case .craneToyShelf: return 4
        case .craneMoonWindow: return 5
        case .craneVines: return 6
        case .cranePond: return 7
        case .craneGlass: return 8
        case .craneFirefly: return 9
        case .craneStairs: return 10
        case .craneGears: return 11
        case .craneBelfry: return 12
        case .stampAttic: return 21
        case .stampGreenhouse: return 22
        case .stampTower: return 23
        }
    }
}

/// 수집품 하나. 방 안의 좌표와, 모았을 때 스크랩북에 적히는 기억 한 줄을 갖는다.
public struct Collectible: Identifiable, Equatable, Sendable {
    public let id: CollectibleID
    public let room: RoomID
    public let label: String
    public let glyph: String
    public let position: ScenePoint
    /// 접힌 자국에서 떠오르는 짧은 기억. 스크랩북과 획득 대사에 함께 쓴다.
    public let memory: String

    public init(
        id: CollectibleID,
        room: RoomID,
        label: String,
        glyph: String,
        position: ScenePoint,
        memory: String
    ) {
        self.id = id
        self.room = room
        self.label = label
        self.glyph = glyph
        self.position = position
        self.memory = memory
    }

    public var kind: CollectibleKind { id.kind }
}

/// 종이학 열두 마리를 다 모았을 때 열리는 다락방 비밀 서랍의 내용물.
public struct SecretGift: Equatable, Sendable {
    public let title: String
    public let glyph: String
    public let lines: [String]
    /// 서랍에서 나오는 작은 기념품의 이름.
    public let keepsake: String

    public init(title: String, glyph: String, lines: [String], keepsake: String) {
        self.title = title
        self.glyph = glyph
        self.lines = lines
        self.keepsake = keepsake
    }

    public static let paperMoon = SecretGift(
        title: "다락방 비밀 서랍",
        glyph: "🗄",
        lines: [
            "열두 마리 종이학을 모으자 창가 벽판이 작게 울리며 서랍이 하나 튀어나왔다.",
            "서랍 안에는 접힌 편지와, 종이학 열두 마리를 실에 꿴 작은 모빌이 들어 있었다.",
            "편지에는 이렇게 적혀 있다. \"접는 사람이 있어야 달이 뜬다. 다음 비 오는 토요일에 또 보자.\"",
            "모빌을 창에 걸자 종이달이 조금 더 밝아졌다. 다락방은 이제 모모와 피코의 방이다."
        ],
        keepsake: "종이학 열두 마리 모빌"
    )
}
