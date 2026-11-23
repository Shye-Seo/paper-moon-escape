import SwiftUI

/// 굵은 잉크선 카툰 스타일의 도형과 붓 도구.
enum Brush {
    static func ink(_ path: Path, in context: inout GraphicsContext, width: CGFloat = 3) {
        context.stroke(path, with: .color(Palette.ink), lineWidth: width)
    }

    static func paint(
        _ path: Path,
        in context: inout GraphicsContext,
        fill: Color,
        width: CGFloat = 3
    ) {
        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(Palette.ink), lineWidth: width)
    }

    /// 살짝 찌그러진 손그림 느낌의 둥근 덩어리.
    static func blob(center: CGPoint, radius: CGFloat, wobble: CGFloat = 0.10, seed: Int = 1) -> Path {
        var path = Path()
        let points = 14
        for index in 0...points {
            let angle = Double(index) / Double(points) * Double.pi * 2
            let jitter = 1 + Double(wobble) * sin(Double(seed) + Double(index) * 1.7)
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * CGFloat(jitter),
                y: center.y + CGFloat(sin(angle)) * radius * CGFloat(jitter)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    static func rect(_ rect: CGRect, corner: CGFloat = 8) -> Path {
        Path(roundedRect: rect, cornerRadius: corner)
    }

    static func star(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int = 5) -> Path {
        var path = Path()
        for index in 0..<(points * 2) {
            let radius = index % 2 == 0 ? outer : inner
            let angle = -Double.pi / 2 + Double(index) * Double.pi / Double(points)
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    static func moon(center: CGPoint, radius: CGFloat, bite: CGFloat) -> Path {
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(70),
            endAngle: .degrees(290),
            clockwise: false
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x + radius * 0.30, y: center.y - radius * 0.95),
            control: CGPoint(x: center.x + radius * 0.80 + bite, y: center.y)
        )
        path.closeSubpath()
        return path
    }

    static func gear(center: CGPoint, radius: CGFloat, teeth: Int) -> Path {
        var path = Path()
        let step = Double.pi * 2 / Double(teeth * 2)
        for index in 0..<(teeth * 2) {
            let r = index % 2 == 0 ? radius : radius * 0.78
            let angle = Double(index) * step
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    /// 위에서 아래로 흐르는 덩굴. `phase`로 살짝 흔든다.
    static func vine(from: CGPoint, to: CGPoint, sway: CGFloat) -> Path {
        var path = Path()
        path.move(to: from)
        let midY = (from.y + to.y) / 2
        path.addQuadCurve(
            to: to,
            control: CGPoint(x: from.x + sway, y: midY)
        )
        return path
    }

    static func rain(in size: CGSize, count: Int, slant: CGFloat) -> Path {
        var path = Path()
        for index in 0..<count {
            let x = size.width * CGFloat(index) / CGFloat(count) + 6
            let y = size.height * CGFloat((index * 37) % 100) / 100
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + slant, y: y + 26))
        }
        return path
    }
}

/// 종이 카드처럼 보이는 배경. 굵은 외곽선 + 오프셋 그림자.
struct PaperCard: ViewModifier {
    var fill: Color = Palette.cream
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Palette.ink, lineWidth: 3)
            )
            .shadow(color: Palette.ink.opacity(0.20), radius: 0, x: 4, y: 5)
    }
}

extension View {
    func paperCard(fill: Color = Palette.cream, radius: CGFloat = 22) -> some View {
        modifier(PaperCard(fill: fill, radius: radius))
    }
}

/// 카툰 버튼: 두꺼운 캡슐, 눌리면 살짝 줄어든다.
struct CartoonButtonStyle: ButtonStyle {
    var fill: Color = Palette.mustard
    var textColor: Color = Palette.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(Palette.ink, lineWidth: 3))
            .shadow(color: Palette.ink.opacity(0.22), radius: 0, x: 3, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// 동그란 아이콘 버튼(힌트, 방 이동 등).
struct RoundIconButton: View {
    let systemName: String
    var fill: Color = Palette.cream
    var accessibility: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(fill))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 3))
                .shadow(color: Palette.ink.opacity(0.18), radius: 0, x: 2, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: accessibility))
    }
}
