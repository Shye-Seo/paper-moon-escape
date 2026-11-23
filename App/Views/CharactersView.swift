import SwiftUI
import PaperMoonCore

/// 종이 인형처럼 생긴 주인공. 모모는 코랄 드레스, 피코는 코발트 멜빵.
struct PaperKid: View {
    let kind: CharacterID
    var isWalking: Bool = false

    private var dress: Color {
        kind == .momo ? Palette.coral : Palette.cobalt
    }

    private var hair: Color {
        kind == .momo ? Color(red: 0.28, green: 0.19, blue: 0.16) : Color(red: 0.24, green: 0.18, blue: 0.14)
    }

    var body: some View {
        ZStack {
            // 다리
            HStack(spacing: 7) {
                Capsule().fill(Palette.inkSoft).frame(width: 7, height: 18)
                Capsule().fill(Palette.inkSoft).frame(width: 7, height: 18)
            }
            .offset(y: 30)

            // 팔
            HStack(spacing: 40) {
                Capsule()
                    .fill(Palette.cream)
                    .frame(width: 8, height: 22)
                    .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                    .rotationEffect(.degrees(isWalking ? 18 : 6))
                Capsule()
                    .fill(Palette.cream)
                    .frame(width: 8, height: 22)
                    .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                    .rotationEffect(.degrees(isWalking ? -18 : -6))
            }
            .offset(y: 12)

            // 몸통
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(dress)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Palette.ink, lineWidth: 2.5)
                )
                .offset(y: 9)

            // 머리카락 뒤
            Circle()
                .fill(hair)
                .frame(width: 40, height: 40)
                .offset(y: -24)

            // 얼굴
            ZStack {
                Circle()
                    .fill(Palette.cream)
                    .frame(width: 34, height: 34)
                HStack(spacing: 9) {
                    Circle().fill(Palette.ink).frame(width: 4.5, height: 4.5)
                    Circle().fill(Palette.ink).frame(width: 4.5, height: 4.5)
                }
                .offset(y: -2)
                Capsule()
                    .fill(Palette.ink)
                    .frame(width: 9, height: 2.5)
                    .offset(y: 8)
            }
            .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
            .offset(y: -22)

            // 모모는 리본, 피코는 모자
            if kind == .momo {
                HStack(spacing: 0) {
                    Triangle()
                        .fill(Palette.mustard)
                        .frame(width: 12, height: 10)
                        .rotationEffect(.degrees(-90))
                    Triangle()
                        .fill(Palette.mustard)
                        .frame(width: 12, height: 10)
                        .rotationEffect(.degrees(90))
                }
                .overlay(Circle().fill(Palette.coral).frame(width: 6, height: 6))
                .offset(x: 15, y: -38)
            } else {
                ZStack {
                    Capsule()
                        .fill(Palette.mustard)
                        .frame(width: 40, height: 12)
                    Capsule()
                        .fill(Palette.coral)
                        .frame(width: 42, height: 5)
                        .offset(y: 8)
                }
                .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                .offset(y: -38)
            }
        }
        .frame(width: 78, height: 96)
    }
}

/// 위를 향한 삼각형. 리본과 지붕에 쓴다.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 대사 화자 표시용 작은 얼굴.
struct CharacterAvatar: View {
    let character: CharacterID

    private var emoji: String {
        switch character {
        case .momo: return "👧"
        case .pico: return "👦"
        case .owl: return "🦉"
        case .frog: return "🐸"
        case .keeper: return "🕯"
        }
    }

    var body: some View {
        Text(verbatim: emoji)
            .font(.system(size: 20))
            .frame(width: 34, height: 34)
            .background(Circle().fill(Palette.glyphTint(character).opacity(0.35)))
            .overlay(Circle().stroke(Palette.ink, lineWidth: 2))
    }
}

/// 캐릭터 머리 위에 잠깐 떠오르는 리액션 말풍선.
struct ReactionBubble: View {
    let reaction: GameStore.Reaction

    var body: some View {
        VStack(spacing: -6) {
            Text(verbatim: reaction.emoji)
                .font(.system(size: 26))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
            Triangle()
                .fill(Palette.cream)
                .frame(width: 12, height: 9)
                .rotationEffect(.degrees(180))
                .overlay(
                    Triangle()
                        .stroke(Palette.ink, lineWidth: 2)
                        .frame(width: 12, height: 9)
                        .rotationEffect(.degrees(180))
                )
        }
        .transition(.scale(scale: 0.4).combined(with: .opacity))
    }
}
