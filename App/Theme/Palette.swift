import SwiftUI
import PaperMoonCore

/// 비 오는 저녁의 다락방 팔레트.
/// 크림색 종이 바탕 위에 우드·촛불 오렌지·소프트 라벤더·세이지가 낮게 깔리고,
/// 모든 윤곽은 검정이 아닌 다크 코코아(`line`)로 부드럽게 잡는다.
enum Palette {
    // 종이와 바탕
    static let paper = Color(red: 0.984, green: 0.953, blue: 0.902)
    static let cream = Color(red: 0.992, green: 0.969, blue: 0.925)
    static let cloud = Color(red: 0.929, green: 0.898, blue: 0.855)

    // 선화 — 굵은 검정 대신 부드러운 코코아
    static let line = Color(red: 0.290, green: 0.231, blue: 0.196)
    static let lineSoft = Color(red: 0.420, green: 0.345, blue: 0.298)
    /// 카드·버튼이 바닥에서 살짝 떠 보이게 하는 따뜻한 그림자.
    static let shadow = Color(red: 0.420, green: 0.310, blue: 0.240).opacity(0.18)

    // 코지 색
    static let butter = Color(red: 0.941, green: 0.835, blue: 0.604)
    static let butterDeep = Color(red: 0.890, green: 0.720, blue: 0.470)
    static let rose = Color(red: 0.851, green: 0.592, blue: 0.561)
    static let roseDeep = Color(red: 0.769, green: 0.482, blue: 0.455)
    static let dusk = Color(red: 0.486, green: 0.525, blue: 0.659)
    static let duskDeep = Color(red: 0.247, green: 0.271, blue: 0.376)
    static let sage = Color(red: 0.659, green: 0.749, blue: 0.627)
    static let mauve = Color(red: 0.557, green: 0.478, blue: 0.580)
    static let wood = Color(red: 0.663, green: 0.510, blue: 0.361)
    static let candle = Color(red: 0.949, green: 0.702, blue: 0.400)
    /// 촛불·스탠드가 방에 번지는 빛.
    static let candleGlow = Color(red: 0.976, green: 0.780, blue: 0.502)

    /// 방마다 바탕색과 강조색을 다르게 준다. 무대가 바뀌는 게 한눈에 보이도록.
    static func wall(_ art: RoomArt) -> Color {
        switch art {
        case .atticLanding: return Color(red: 0.851, green: 0.780, blue: 0.690)
        case .toyCloset: return Color(red: 0.878, green: 0.804, blue: 0.663)
        case .moonWindow: return duskDeep
        case .vineGate: return Color(red: 0.769, green: 0.827, blue: 0.729)
        case .frogPond: return Color(red: 0.651, green: 0.765, blue: 0.714)
        case .glassHouse: return Color(red: 0.298, green: 0.329, blue: 0.392)
        case .gearStairs: return Color(red: 0.604, green: 0.529, blue: 0.580)
        case .gearRoom: return Color(red: 0.776, green: 0.659, blue: 0.549)
        case .belfry: return Color(red: 0.220, green: 0.251, blue: 0.361)
        case .cellarStairs: return Color(red: 0.435, green: 0.373, blue: 0.318)
        case .cellarPantry: return Color(red: 0.478, green: 0.396, blue: 0.337)
        case .cellarVault: return Color(red: 0.263, green: 0.243, blue: 0.298)
        }
    }

    static func floor(_ art: RoomArt) -> Color {
        switch art {
        case .atticLanding, .toyCloset: return Color(red: 0.663, green: 0.510, blue: 0.361)
        case .moonWindow: return Color(red: 0.353, green: 0.373, blue: 0.478)
        case .vineGate, .frogPond: return Color(red: 0.494, green: 0.580, blue: 0.447)
        case .glassHouse: return Color(red: 0.341, green: 0.369, blue: 0.408)
        case .gearStairs, .gearRoom: return Color(red: 0.478, green: 0.392, blue: 0.333)
        case .belfry: return Color(red: 0.184, green: 0.212, blue: 0.329)
        case .cellarStairs, .cellarPantry: return Color(red: 0.353, green: 0.286, blue: 0.235)
        case .cellarVault: return Color(red: 0.208, green: 0.192, blue: 0.243)
        }
    }

    static func accent(_ art: RoomArt) -> Color {
        switch art {
        case .atticLanding, .toyCloset: return butter
        case .moonWindow: return candle
        case .vineGate, .frogPond: return sage
        case .glassHouse: return butter
        case .gearStairs, .gearRoom: return butter
        case .belfry: return rose
        case .cellarStairs: return butter
        case .cellarPantry: return rose
        case .cellarVault: return candle
        }
    }

    static func stageTint(_ stageID: StageID) -> Color {
        switch stageID {
        case .attic: return butter
        case .greenhouse: return sage
        case .clocktower: return rose
        case .cellar: return mauve
        }
    }

    static func glyphTint(_ character: CharacterID) -> Color {
        switch character {
        case .momo: return rose
        case .pico: return butter
        case .owl: return mauve
        case .frog: return sage
        case .keeper: return candle
        }
    }
}
