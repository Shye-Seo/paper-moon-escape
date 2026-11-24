import Foundation

/// 탐색으로 얻는 것. 본편 아이템이거나 스크랩북 수집품이다.
public enum SearchReward: Equatable, Sendable {
    case item(ItemID)
    case collectible(CollectibleID)
}

/// 꼼꼼히 더듬어야 나오는 자리.
///
/// 본편의 지점(`Hotspot`)은 한 번 누르면 결과가 나오지만, 탐색 지점은
/// **여러 번 살펴야 하고 매번 반드시 나오지는 않는다.** 대신 마지막 시도의
/// 확률은 1.0이라, 아무리 운이 나빠도 `maxAttempts`번 안에는 반드시 발견된다.
/// 그래서 "무한 노가다로 막히는" 일은 생기지 않는다.
///
/// - `odds`: 시도 횟수별 발견 확률(0~1). 마지막 값은 반드시 1.0(천장).
/// - `observations`: 실패할 때마다 흘려 주는 관찰 문장. 마지막 문장은
///   발견 직전의 단서라, 플레이어가 "거의 찾았다"는 것을 느낄 수 있다.
public struct SearchSpot: Identifiable, Equatable, Sendable {
    public let id: String
    public let room: RoomID
    public let label: String
    public let glyph: String
    public let position: ScenePoint
    /// 이 자리를 더듬을 수 있는 캐릭터. nil이면 둘 다 된다.
    public let requiredCharacter: PlayableCharacter?
    /// 다른 캐릭터로 더듬었을 때의 코지한 안내.
    public let characterNote: String?
    public let requires: [Requirement]
    public let blocked: String?
    public let odds: [Double]
    public let observations: [String]
    public let foundText: String
    public let reward: SearchReward
    /// 발견과 함께 서는 플래그.
    public let flags: [String]
    public let repeatText: String

    public init(
        id: String,
        room: RoomID,
        label: String,
        glyph: String,
        position: ScenePoint,
        requiredCharacter: PlayableCharacter? = nil,
        characterNote: String? = nil,
        requires: [Requirement] = [],
        blocked: String? = nil,
        odds: [Double],
        observations: [String],
        foundText: String,
        reward: SearchReward,
        flags: [String] = [],
        repeatText: String
    ) {
        self.id = id
        self.room = room
        self.label = label
        self.glyph = glyph
        self.position = position
        self.requiredCharacter = requiredCharacter
        self.characterNote = characterNote
        self.requires = requires
        self.blocked = blocked
        self.odds = odds
        self.observations = observations
        self.foundText = foundText
        self.reward = reward
        self.flags = flags
        self.repeatText = repeatText
    }

    /// 천장. 이 횟수 안에는 반드시 발견된다.
    public var maxAttempts: Int { odds.count }

    /// 이미 `tries`번 실패한 상태에서의 발견 확률.
    /// 천장을 넘겨 부르면 1.0을 돌려준다(방어).
    public func chance(afterFailures tries: Int) -> Double {
        guard tries >= 0 else { return odds.first ?? 1 }
        guard tries < odds.count else { return 1 }
        return odds[tries]
    }

    /// `attempt`번째 시도(1부터)가 실패했을 때 보여 줄 관찰 문장.
    public func observation(onFailed attempt: Int) -> String {
        guard !observations.isEmpty else { return "손끝에 먼지만 묻는다." }
        let index = min(max(attempt - 1, 0), observations.count - 1)
        return observations[index]
    }

    /// 실패 문장이 단서처럼 들리는 마지막 구간인지. 화면이 강조에 쓴다.
    public func isClosingIn(afterFailures tries: Int) -> Bool {
        tries >= maxAttempts - 2
    }

    public var rewardItem: ItemID? {
        if case .item(let item) = reward { return item }
        return nil
    }

    public var rewardCollectible: CollectibleID? {
        if case .collectible(let collectible) = reward { return collectible }
        return nil
    }
}
