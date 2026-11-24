import SwiftUI
import PaperMoonCore

/// 다락방에 사는 동글동글한 친구들.
/// 모모는 꿀빛 단발에 더스티 로즈 니트, 피코는 크림색 털에 낡은 리본을 맨 작은 고양이다.
/// 눈은 작은 점, 볼에는 옅은 홍조, 윤곽은 얇은 코코아 선.
struct PaperKid: View {
    let kind: CharacterID
    var isWalking: Bool = false

    private var fur: Color { Color(red: 0.976, green: 0.941, blue: 0.859) }
    private var skin: Color { Color(red: 0.988, green: 0.898, blue: 0.812) }
    private var hair: Color { Color(red: 0.800, green: 0.612, blue: 0.384) }
    private var hairDeep: Color { Color(red: 0.690, green: 0.502, blue: 0.294) }

    var body: some View {
        ZStack {
            if kind == .pico {
                pico
            } else {
                momo
            }
        }
        .frame(width: 88, height: 108)
        .offset(y: isWalking ? -1 : 0)
    }

    // MARK: 모모

    private var momo: some View {
        ZStack {
            // 그림자
            Ellipse()
                .fill(Palette.lineSoft.opacity(0.13))
                .frame(width: 46, height: 9)
                .offset(y: 47)

            // 다리와 부츠
            HStack(spacing: 8) {
                leg
                leg
            }
            .offset(y: 38)

            // 니트 몸통
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Palette.rose)
                .frame(width: 44, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Palette.lineSoft.opacity(0.5), lineWidth: 1.1)
                )
                .offset(y: 24)

            // 소매
            HStack(spacing: 34) {
                sleeve(angle: isWalking ? 22 : 8)
                sleeve(angle: isWalking ? -22 : -8)
            }
            .offset(y: 22)

            // 목 둘레
            Circle()
                .fill(Palette.cream)
                .frame(width: 12, height: 12)
                .offset(y: 6)

            // 얼굴
            ZStack {
                // 뒤 머릿결
                Circle()
                    .fill(hairDeep)
                    .frame(width: 62, height: 62)

                // 얼굴
                Circle()
                    .fill(skin)
                    .frame(width: 50, height: 50)
                    .offset(y: 4)

                // 앞머리
                Capsule()
                    .fill(hair)
                    .frame(width: 52, height: 26)
                    .offset(y: -14)

                // 옆머리
                Capsule()
                    .fill(hairDeep)
                    .frame(width: 11, height: 26)
                    .rotationEffect(.degrees(7))
                    .offset(x: -23, y: 2)
                Capsule()
                    .fill(hairDeep)
                    .frame(width: 11, height: 26)
                    .rotationEffect(.degrees(-7))
                    .offset(x: 23, y: 2)

                // 눈 · 홍조 · 입
                HStack(spacing: 14) {
                    Circle().fill(Palette.line).frame(width: 4.4, height: 4.4)
                    Circle().fill(Palette.line).frame(width: 4.4, height: 4.4)
                }
                .offset(y: 3)

                HStack(spacing: 24) {
                    blush
                    blush
                }
                .offset(y: 10)

                Circle()
                    .trim(from: 0.52, to: 0.98)
                    .stroke(Palette.lineSoft, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                    .frame(width: 8, height: 8)
                    .offset(y: 10)

                // 리본
                ZStack {
                    Triangle().fill(Palette.butterDeep).frame(width: 11, height: 10).rotationEffect(.degrees(-90))
                    Triangle().fill(Palette.butterDeep).frame(width: 11, height: 10).rotationEffect(.degrees(90))
                    Circle().fill(Palette.roseDeep).frame(width: 5, height: 5)
                }
                .offset(x: 19, y: -22)
            }
            .offset(y: -16)
        }
    }

    // MARK: 피코 (고양이)

    private var pico: some View {
        ZStack {
            Ellipse()
                .fill(Palette.lineSoft.opacity(0.13))
                .frame(width: 46, height: 9)
                .offset(y: 47)

            // 꼬리
            Capsule()
                .fill(fur)
                .frame(width: 9, height: 30)
                .rotationEffect(.degrees(isWalking ? 46 : 34), anchor: .bottom)
                .overlay(
                    Capsule()
                        .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1)
                        .frame(width: 9, height: 30)
                        .rotationEffect(.degrees(isWalking ? 46 : 34), anchor: .bottom)
                )
                .offset(x: 26, y: 30)

            // 몸통
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fur)
                .frame(width: 42, height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1)
                )
                .offset(y: 26)

            // 앞발
            HStack(spacing: 12) {
                paw
                paw
            }
            .offset(y: 42)

            // 목 리본
            ZStack {
                Triangle().fill(Palette.rose).frame(width: 12, height: 10).rotationEffect(.degrees(-90))
                Triangle().fill(Palette.rose).frame(width: 12, height: 10).rotationEffect(.degrees(90))
                Circle().fill(Palette.roseDeep).frame(width: 6, height: 6)
            }
            .offset(y: 11)

            // 얼굴
            ZStack {
                // 귀
                Triangle()
                    .fill(fur)
                    .frame(width: 15, height: 13)
                    .overlay(Triangle().stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1))
                    .rotationEffect(.degrees(-14))
                    .offset(x: -17, y: -26)
                Triangle()
                    .fill(fur)
                    .frame(width: 15, height: 13)
                    .overlay(Triangle().stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1))
                    .rotationEffect(.degrees(14))
                    .offset(x: 17, y: -26)

                Circle()
                    .fill(fur)
                    .frame(width: 52, height: 50)
                    .overlay(Circle().stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1))

                // 눈
                HStack(spacing: 15) {
                    Circle().fill(Palette.line).frame(width: 4.4, height: 4.4)
                    Circle().fill(Palette.line).frame(width: 4.4, height: 4.4)
                }
                .offset(y: -2)

                // 코와 입
                Triangle()
                    .fill(Palette.roseDeep)
                    .frame(width: 5, height: 4)
                    .rotationEffect(.degrees(180))
                    .offset(y: 7)
                Circle()
                    .trim(from: 0.52, to: 0.98)
                    .stroke(Palette.lineSoft, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: 7, height: 7)
                    .offset(y: 11)

                // 홍조
                HStack(spacing: 26) {
                    blush
                    blush
                }
                .offset(y: 6)

                // 수염
                HStack(spacing: 34) {
                    whiskers
                    whiskers
                }
                .offset(y: 6)
            }
            .offset(y: -13)
        }
    }

    // MARK: 조각

    private var leg: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(skin)
                .frame(width: 7, height: 12)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Palette.wood)
                .frame(width: 13, height: 9)
        }
    }

    private func sleeve(angle: Double) -> some View {
        Capsule()
            .fill(Palette.roseDeep)
            .frame(width: 8, height: 22)
            .rotationEffect(.degrees(angle))
    }

    private var paw: some View {
        Ellipse()
            .fill(fur)
            .frame(width: 12, height: 8)
            .overlay(Ellipse().stroke(Palette.lineSoft.opacity(0.4), lineWidth: 1))
    }

    private var blush: some View {
        Ellipse()
            .fill(Palette.roseDeep.opacity(0.40))
            .frame(width: 8, height: 4.5)
    }

    private var whiskers: some View {
        VStack(spacing: 3) {
            Capsule().fill(Palette.lineSoft.opacity(0.45)).frame(width: 11, height: 1)
            Capsule().fill(Palette.lineSoft.opacity(0.45)).frame(width: 9, height: 1)
        }
    }
}

/// 위를 향한 삼각형. 리본과 귀에 쓴다.
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

/// 대사 화자 표시용 작은 얼굴. 이모지 대신 같은 화풍으로 그린다.
struct CharacterAvatar: View {
    let character: CharacterID

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.glyphTint(character).opacity(0.32))
            face
        }
        .frame(width: 34, height: 34)
        .overlay(Circle().stroke(Palette.lineSoft.opacity(0.4), lineWidth: 1))
    }

    @ViewBuilder
    private var face: some View {
        switch character {
        case .momo:
            ZStack {
                Circle().fill(Palette.cream).frame(width: 24, height: 24)
                Capsule()
                    .fill(Color(red: 0.800, green: 0.612, blue: 0.384))
                    .frame(width: 25, height: 11)
                    .offset(y: -8)
                dots
                Circle()
                    .fill(Palette.roseDeep.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .offset(x: 14, y: -9)
            }
        case .pico:
            ZStack {
                Triangle().fill(Palette.cream).frame(width: 8, height: 7).offset(x: -8, y: -12)
                Triangle().fill(Palette.cream).frame(width: 8, height: 7).offset(x: 8, y: -12)
                Circle().fill(Palette.cream).frame(width: 25, height: 24)
                dots
                Triangle()
                    .fill(Palette.roseDeep)
                    .frame(width: 3.5, height: 3)
                    .rotationEffect(.degrees(180))
                    .offset(y: 5)
            }
        case .owl:
            ZStack {
                Circle().fill(Palette.cream).frame(width: 25, height: 24)
                Triangle().fill(Color(red: 0.680, green: 0.620, blue: 0.720)).frame(width: 8, height: 6).offset(x: -9, y: -12)
                Triangle().fill(Color(red: 0.680, green: 0.620, blue: 0.720)).frame(width: 8, height: 6).offset(x: 9, y: -12)
                HStack(spacing: 2) {
                    Circle().stroke(Palette.lineSoft, lineWidth: 1).frame(width: 9, height: 9)
                    Circle().stroke(Palette.lineSoft, lineWidth: 1).frame(width: 9, height: 9)
                }
                .offset(y: -1)
                Circle().fill(Palette.butterDeep).frame(width: 5, height: 4).offset(y: 6)
            }
        case .frog:
            ZStack {
                Circle().fill(Palette.cream).frame(width: 24, height: 22).offset(y: 3)
                Circle().fill(Palette.cream).frame(width: 9, height: 9).offset(x: -6, y: -8)
                Circle().fill(Palette.cream).frame(width: 9, height: 9).offset(x: 6, y: -8)
                Circle().fill(Palette.line).frame(width: 3, height: 3).offset(x: -6, y: -8)
                Circle().fill(Palette.line).frame(width: 3, height: 3).offset(x: 6, y: -8)
                Circle()
                    .trim(from: 0.52, to: 0.98)
                    .stroke(Palette.lineSoft, style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                    .frame(width: 8, height: 8)
                    .offset(y: 5)
            }
        case .keeper:
            ZStack {
                Circle().fill(Palette.candle.opacity(0.35)).frame(width: 26, height: 26)
                Capsule()
                    .fill(Palette.butterDeep)
                    .frame(width: 9, height: 16)
                    .offset(y: 5)
                Ellipse()
                    .fill(Palette.candle)
                    .frame(width: 8, height: 12)
                    .offset(y: -6)
                Circle().fill(Palette.cream).frame(width: 3, height: 3).offset(y: -3)
            }
        }
    }

    private var dots: some View {
        HStack(spacing: 7) {
            Circle().fill(Palette.line).frame(width: 3.2, height: 3.2)
            Circle().fill(Palette.line).frame(width: 3.2, height: 3.2)
        }
        .offset(y: 1)
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
                .overlay(Circle().stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1))
                .shadow(color: Palette.shadow, radius: 6, y: 2)
            Triangle()
                .fill(Palette.cream)
                .frame(width: 12, height: 9)
                .rotationEffect(.degrees(180))
        }
        .transition(.scale(scale: 0.4).combined(with: .opacity))
    }
}
