import SwiftUI
import PaperMoonCore

/// 『Lost in Play』 같은 토요일 아침 카툰 팔레트.
/// 크림 종이 바탕에 코발트·머스타드·코랄이 굵은 잉크선과 함께 놓인다.
enum Palette {
    static let paper = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.91)
    static let cobalt = Color(red: 0.17, green: 0.30, blue: 0.62)
    static let cobaltDeep = Color(red: 0.09, green: 0.16, blue: 0.38)
    static let mustard = Color(red: 0.96, green: 0.73, blue: 0.27)
    static let coral = Color(red: 0.94, green: 0.42, blue: 0.35)
    static let mint = Color(red: 0.45, green: 0.77, blue: 0.63)
    static let plum = Color(red: 0.36, green: 0.26, blue: 0.48)
    static let ink = Color(red: 0.12, green: 0.13, blue: 0.19)
    static let inkSoft = Color(red: 0.30, green: 0.31, blue: 0.38)
    static let cloud = Color(red: 0.95, green: 0.94, blue: 0.92)

    /// 방마다 바탕색과 강조색을 다르게 준다. 무대가 바뀌는 게 한눈에 보이도록.
    static func wall(_ art: RoomArt) -> Color {
        switch art {
        case .atticLanding: return Color(red: 0.80, green: 0.75, blue: 0.66)
        case .toyCloset: return Color(red: 0.88, green: 0.80, blue: 0.62)
        case .moonWindow: return cobaltDeep
        case .vineGate: return Color(red: 0.62, green: 0.80, blue: 0.70)
        case .frogPond: return Color(red: 0.47, green: 0.72, blue: 0.68)
        case .glassHouse: return Color(red: 0.22, green: 0.27, blue: 0.36)
        case .gearStairs: return Color(red: 0.55, green: 0.46, blue: 0.55)
        case .gearRoom: return Color(red: 0.74, green: 0.60, blue: 0.45)
        case .belfry: return Color(red: 0.16, green: 0.22, blue: 0.44)
        }
    }

    static func floor(_ art: RoomArt) -> Color {
        switch art {
        case .atticLanding, .toyCloset: return Color(red: 0.68, green: 0.50, blue: 0.34)
        case .moonWindow: return Color(red: 0.20, green: 0.26, blue: 0.44)
        case .vineGate, .frogPond: return Color(red: 0.33, green: 0.50, blue: 0.40)
        case .glassHouse: return Color(red: 0.26, green: 0.30, blue: 0.34)
        case .gearStairs, .gearRoom: return Color(red: 0.42, green: 0.34, blue: 0.32)
        case .belfry: return Color(red: 0.12, green: 0.16, blue: 0.32)
        }
    }

    static func accent(_ art: RoomArt) -> Color {
        switch art {
        case .atticLanding: return mustard
        case .toyCloset: return coral
        case .moonWindow: return mustard
        case .vineGate, .frogPond: return mustard
        case .glassHouse: return mint
        case .gearStairs, .gearRoom: return mustard
        case .belfry: return mustard
        }
    }

    static func stageTint(_ stageID: StageID) -> Color {
        switch stageID {
        case .attic: return mustard
        case .greenhouse: return mint
        case .clocktower: return coral
        }
    }

    static func glyphTint(_ character: CharacterID) -> Color {
        switch character {
        case .momo: return coral
        case .pico: return cobalt
        case .owl: return mustard
        case .frog: return mint
        case .keeper: return plum
        }
    }
}
