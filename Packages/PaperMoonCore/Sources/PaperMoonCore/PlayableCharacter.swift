import Foundation

/// 플레이어가 직접 조종하는 두 캐릭터.
///
/// 모모는 손이 크고 힘이 있어 높은 선반에 닿고, 종이를 접고 도구를 맞춘다.
/// 고양이 피코는 몸이 작고 발끝이 가벼워 쥐구멍과 선반 틈새에 들어가고,
/// 부엉이·개구리 같은 동물과 마음을 나눈다.
/// 지점(`Hotspot`)이 `requiredCharacter`를 갖고 있으면 그 캐릭터일 때만 손이 닿는다.
public enum PlayableCharacter: String, Codable, CaseIterable, Hashable, Sendable {
    case momo
    case pico

    public var displayName: String {
        switch self {
        case .momo: return "모모"
        case .pico: return "고양이 피코"
        }
    }

    public var shortName: String {
        switch self {
        case .momo: return "모모"
        case .pico: return "피코"
        }
    }

    public var glyph: String {
        switch self {
        case .momo: return "🧣"
        case .pico: return "🐈"
        }
    }

    /// 스위치 아래에 한 줄로 붙는 설명.
    public var trait: String {
        switch self {
        case .momo: return "높은 선반 · 종이접기 · 도구"
        case .pico: return "쥐구멍 · 틈새 · 동물 친구"
        }
    }

    /// 말풍선·리액션에 쓸 캐릭터 id.
    public var reactionCharacter: CharacterID {
        switch self {
        case .momo: return .momo
        case .pico: return .pico
        }
    }

    public var other: PlayableCharacter {
        switch self {
        case .momo: return .pico
        case .pico: return .momo
        }
    }
}
