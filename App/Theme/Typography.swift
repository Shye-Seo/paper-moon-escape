import SwiftUI

extension Font {
    /// 앱 전체가 쓰는 둥근 카툰 글꼴.
    static func cartoon(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// 종이로 오린 듯한 달. 타이틀과 엔딩에 쓴다.
struct MoonView: View {
    var fill: Color = Palette.cream
    var bite: CGFloat = 16

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.42
            let path = Brush.moon(center: center, radius: radius, bite: bite)
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(Palette.ink), lineWidth: 4)

            let crater = Path(ellipseIn: CGRect(
                x: center.x - radius * 0.30,
                y: center.y - radius * 0.30,
                width: radius * 0.26,
                height: radius * 0.26
            ))
            context.fill(crater, with: .color(Palette.mustard.opacity(0.55)))
        }
        .accessibilityHidden(true)
    }
}

/// 화면 전체를 덮는 아주 옅은 종이 결.
struct PaperBackground: View {
    var tint: Color = Palette.paper

    var body: some View {
        ZStack {
            tint
            Canvas { context, size in
                var dots = Path()
                var index = 0
                while index < 140 {
                    let x = size.width * CGFloat((index * 37) % 100) / 100
                    let y = size.height * CGFloat((index * 61) % 100) / 100
                    dots.addEllipse(in: CGRect(x: x, y: y, width: 1.6, height: 1.6))
                    index += 1
                }
                context.fill(dots, with: .color(Palette.ink.opacity(0.05)))
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
