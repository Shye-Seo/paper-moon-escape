import SwiftUI
import PaperMoonCore

/// 방 하나를 코지 힐링 동화 그림처럼 그린다.
/// 굵은 검정 외곽선 대신 얇은 코코아 선을 쓰고, 촛불·스탠드 빛은 라디얼 그라디언트로 번지게 한다.
/// 모든 좌표는 캔버스 크기에 대한 비율로 계산해서 어떤 화면비에서도 어색하지 않게 한다.
struct RoomSceneView: View {
    let room: Room
    var time: Double = 0

    var body: some View {
        Canvas { context, size in
            paintFloor(&context, size)
            switch room.art {
            case .atticLanding: paintAtticLanding(&context, size)
            case .toyCloset: paintToyCloset(&context, size)
            case .moonWindow: paintMoonWindow(&context, size)
            case .vineGate: paintVineGate(&context, size)
            case .frogPond: paintFrogPond(&context, size)
            case .glassHouse: paintGlassHouse(&context, size)
            case .gearStairs: paintGearStairs(&context, size)
            case .gearRoom: paintGearRoom(&context, size)
            case .belfry: paintBelfry(&context, size)
            case .cellarStairs: paintCellarStairs(&context, size)
            case .cellarPantry: paintCellarPantry(&context, size)
            case .cellarVault: paintCellarVault(&context, size)
            }
            paintPaperGrain(&context, size)
        }
        .background(Palette.wall(room.art))
        .clipped()
        .accessibilityHidden(true)
    }

    // MARK: 공통

    private func paintFloor(_ context: inout GraphicsContext, _ size: CGSize) {
        let floorRect = CGRect(
            x: 0,
            y: size.height * 0.76,
            width: size.width,
            height: size.height * 0.24
        )
        let floor = Path(floorRect)
        context.fill(floor, with: .color(Palette.floor(room.art)))
        context.stroke(floor, with: .color(Palette.lineSoft.opacity(0.55)), lineWidth: 1.2)

        var boards = Path()
        var x: CGFloat = -20
        while x < size.width + 40 {
            boards.move(to: CGPoint(x: x, y: floorRect.minY))
            boards.addLine(to: CGPoint(x: x - 26, y: size.height))
            x += 56
        }
        context.stroke(boards, with: .color(Palette.lineSoft.opacity(0.16)), lineWidth: 1)
    }

    private func paintPaperGrain(_ context: inout GraphicsContext, _ size: CGSize) {
        var dots = Path()
        var index = 0
        while index < 90 {
            let x = size.width * CGFloat((index * 53) % 100) / 100
            let y = size.height * CGFloat((index * 29) % 100) / 100
            dots.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
            index += 1
        }
        context.fill(dots, with: .color(Palette.lineSoft.opacity(0.05)))
    }

    private func pole(_ context: inout GraphicsContext, _ size: CGSize) {
        // 창문 빛줄기처럼 쓰는 대각선 하이라이트
        var beam = Path()
        beam.move(to: CGPoint(x: size.width * 0.1, y: 0))
        beam.addLine(to: CGPoint(x: size.width * 0.32, y: 0))
        beam.addLine(to: CGPoint(x: size.width * 0.52, y: size.height * 0.76))
        beam.addLine(to: CGPoint(x: size.width * 0.26, y: size.height * 0.76))
        beam.closeSubpath()
        context.fill(beam, with: .color(Palette.candleGlow.opacity(0.08)))
    }

    // MARK: 스테이지 1

    private func paintAtticLanding(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 계단 난간
        var rail = Path()
        rail.move(to: CGPoint(x: 0, y: h * 0.56))
        rail.addLine(to: CGPoint(x: w * 0.16, y: h * 0.42))
        rail.addLine(to: CGPoint(x: w * 0.16, y: h * 0.76))
        context.stroke(rail, with: .color(Palette.lineSoft.opacity(0.6)), lineWidth: 1.4)

        // 창문
        let window = CGRect(x: w * 0.62, y: h * 0.14, width: w * 0.28, height: h * 0.34)
        Brush.paint(Brush.rect(window, corner: 14), in: &context, fill: Palette.duskDeep)
        context.stroke(
            Brush.rain(in: window.size, count: 9, slant: -6)
                .applying(CGAffineTransform(translationX: window.minX, y: window.minY)),
            with: .color(Palette.cream.opacity(0.6)),
            lineWidth: 1
        )

        // 창 너머의 종이달
        let moonCenter = CGPoint(x: window.midX + w * 0.03, y: window.minY + window.height * 0.40)
        Brush.glow(&context, center: moonCenter, radius: w * 0.16, strength: 0.35)
        let atticMoon = Brush.moon(center: moonCenter, radius: w * 0.055, bite: 3)
        context.fill(atticMoon, with: .color(Palette.cream))
        Brush.line(atticMoon, in: &context, width: 1)

        var frame = Path()
        frame.move(to: CGPoint(x: window.midX, y: window.minY))
        frame.addLine(to: CGPoint(x: window.midX, y: window.maxY))
        frame.move(to: CGPoint(x: window.minX, y: window.midY))
        frame.addLine(to: CGPoint(x: window.maxX, y: window.midY))
        context.stroke(frame, with: .color(Palette.cream.opacity(0.75)), lineWidth: 1.4)

        // 상자 두 개
        Brush.paint(
            Brush.rect(CGRect(x: w * 0.06, y: h * 0.62, width: w * 0.16, height: h * 0.14), corner: 8),
            in: &context,
            fill: Color(red: 0.78, green: 0.62, blue: 0.42)
        )
        Brush.paint(
            Brush.rect(CGRect(x: w * 0.14, y: h * 0.50, width: w * 0.12, height: h * 0.12), corner: 8),
            in: &context,
            fill: Color(red: 0.84, green: 0.70, blue: 0.48)
        )

        // 깔개
        var rug = Path()
        rug.addEllipse(in: CGRect(x: w * 0.30, y: h * 0.80, width: w * 0.44, height: h * 0.12))
        context.fill(rug, with: .color(Palette.rose.opacity(0.42)))
        context.stroke(rug, with: .color(Palette.lineSoft.opacity(0.4)), lineWidth: 1.1)

        // 상자 옆 촛불
        Brush.glow(&context, center: CGPoint(x: w * 0.24, y: h * 0.60), radius: w * 0.22, strength: 0.30)

        pole(&context, size)
    }

    private func paintToyCloset(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 선반
        for row in 0..<2 {
            let y = h * (0.34 + CGFloat(row) * 0.22)
            Brush.paint(
                Brush.rect(CGRect(x: w * 0.68, y: y, width: w * 0.28, height: h * 0.035), corner: 4),
                in: &context,
                fill: Color(red: 0.62, green: 0.46, blue: 0.32)
            )
            var tin = Path()
            tin.addEllipse(in: CGRect(x: w * 0.72, y: y - h * 0.06, width: w * 0.05, height: h * 0.06))
            context.fill(tin, with: .color(Palette.sage))
            context.stroke(tin, with: .color(Palette.lineSoft.opacity(0.5)), lineWidth: 1)
        }

        // 벽 그림
        let poster = CGRect(x: w * 0.08, y: h * 0.14, width: w * 0.22, height: h * 0.24)
        Brush.paint(Brush.rect(poster, corner: 6), in: &context, fill: Palette.cream)
        let colors: [Color] = [Palette.rose, Palette.sage, Palette.butter, Palette.dusk]
        for index in 0..<4 {
            let block = CGRect(
                x: poster.minX + poster.width * 0.18,
                y: poster.maxY - poster.height * (0.22 + CGFloat(index) * 0.18),
                width: poster.width * 0.64,
                height: poster.height * 0.11
            )
            context.fill(Path(roundedRect: block, cornerRadius: 3), with: .color(colors[index]))
            context.stroke(Path(roundedRect: block, cornerRadius: 3), with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 1)
        }

        // 바닥 블록
        for index in 0..<6 {
            let x = w * (0.58 + CGFloat(index % 3) * 0.10)
            let y = h * (0.82 + CGFloat(index / 3) * 0.06)
            let block = CGRect(x: x, y: y, width: w * 0.055, height: w * 0.055)
            context.fill(Path(roundedRect: block, cornerRadius: 4), with: .color(colors[index % 4]))
            context.stroke(Path(roundedRect: block, cornerRadius: 4), with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 1)
        }

        // 장난감 상자
        Brush.paint(
            Brush.rect(CGRect(x: w * 0.30, y: h * 0.64, width: w * 0.26, height: h * 0.14), corner: 10),
            in: &context,
            fill: Color(red: 0.72, green: 0.54, blue: 0.36)
        )
        var lid = Path()
        lid.move(to: CGPoint(x: w * 0.30, y: h * 0.66))
        lid.addLine(to: CGPoint(x: w * 0.56, y: h * 0.66))
        context.stroke(lid, with: .color(Palette.lineSoft.opacity(0.6)), lineWidth: 1.1)

        // 선반 위 스탠드 불빛
        Brush.glow(&context, center: CGPoint(x: w * 0.82, y: h * 0.44), radius: w * 0.24, strength: 0.26)

        pole(&context, size)
    }

    private func paintMoonWindow(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 커다란 종이달
        let center = CGPoint(x: w * 0.50, y: h * 0.40)
        let radius = min(w, h) * 0.30
        let moon = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(moon, with: .color(Palette.cream))
        Brush.line(moon, in: &context, width: 1.2)
        Brush.glow(&context, center: center, radius: radius * 1.5, strength: 0.28)

        // 달의 잘린 자리
        let bite = Brush.blob(
            center: CGPoint(x: center.x + radius * 0.72, y: center.y - radius * 0.40),
            radius: radius * 0.34,
            wobble: 0.06,
            seed: 3
        )
        context.fill(bite, with: .color(Palette.duskDeep))
        context.stroke(bite, with: .color(Palette.lineSoft.opacity(0.5)), lineWidth: 1.1)

        // 창틀
        var frame = Path()
        frame.move(to: CGPoint(x: w * 0.20, y: 0))
        frame.addLine(to: CGPoint(x: w * 0.20, y: h * 0.76))
        frame.move(to: CGPoint(x: w * 0.80, y: 0))
        frame.addLine(to: CGPoint(x: w * 0.80, y: h * 0.76))
        frame.move(to: CGPoint(x: 0, y: h * 0.55))
        frame.addLine(to: CGPoint(x: w, y: h * 0.55))
        context.stroke(frame, with: .color(Palette.wood.opacity(0.85)), lineWidth: 2.2)

        // 별
        for index in 0..<7 {
            let star = Brush.star(
                center: CGPoint(
                    x: w * (0.12 + CGFloat(index % 3) * 0.33),
                    y: h * (0.10 + CGFloat(index / 3) * 0.14)
                ),
                outer: 6,
                inner: 2.5,
                points: 4
            )
            context.fill(star, with: .color(Palette.butter.opacity(0.9)))
        }

        // 바닥에 흐르는 달빛
        var light = Path()
        light.move(to: CGPoint(x: w * 0.36, y: h * 0.76))
        light.addLine(to: CGPoint(x: w * 0.64, y: h * 0.76))
        light.addLine(to: CGPoint(x: w * 0.80, y: h))
        light.addLine(to: CGPoint(x: w * 0.20, y: h))
        light.closeSubpath()
        context.fill(light, with: .color(Palette.butter.opacity(0.18)))
    }

    // MARK: 스테이지 2

    private func paintVineGate(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 위에서 자라는 덩굴
        for index in 0..<5 {
            let startX = w * (0.12 + CGFloat(index) * 0.19)
            let path = Brush.vine(
                from: CGPoint(x: startX, y: -10),
                to: CGPoint(x: startX + 18, y: h * 0.62),
                sway: index % 2 == 0 ? 34 : -30
            )
            context.stroke(path, with: .color(Palette.lineSoft.opacity(0.55)), lineWidth: 1.8)
            context.stroke(path, with: .color(Palette.sage.opacity(0.95)), lineWidth: 1.1)

            for leafIndex in 1...3 {
                let leaf = Path(ellipseIn: CGRect(
                    x: startX + CGFloat(leafIndex) * 6 + (index % 2 == 0 ? 20 : -26),
                    y: h * (0.14 + CGFloat(leafIndex) * 0.15),
                    width: 20,
                    height: 12
                ))
                context.fill(leaf, with: .color(Palette.sage))
                context.stroke(leaf, with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 1)
            }
        }

        // 화분
        let pot = Path()
        pot.move(to: CGPoint(x: w * 0.28, y: h * 0.66))
        pot.addLine(to: CGPoint(x: w * 0.44, y: h * 0.66))
        pot.addLine(to: CGPoint(x: w * 0.40, y: h * 0.78))
        pot.addLine(to: CGPoint(x: w * 0.32, y: h * 0.78))
        pot.closeSubpath()
        Brush.paint(pot, in: &context, fill: Palette.rose)

        var soil = Path()
        soil.addEllipse(in: CGRect(x: w * 0.28, y: h * 0.64, width: w * 0.16, height: h * 0.04))
        context.fill(soil, with: .color(Color(red: 0.38, green: 0.28, blue: 0.20)))
        context.stroke(soil, with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 1)

        // 물길
        var stream = Path()
        stream.move(to: CGPoint(x: w * 0.46, y: h * 0.70))
        stream.addQuadCurve(
            to: CGPoint(x: w * 0.60, y: h * 0.76),
            control: CGPoint(x: w * 0.52, y: h * 0.74)
        )
        context.stroke(stream, with: .color(Palette.dusk), lineWidth: 1.8)

        pole(&context, size)
    }

    private func paintFrogPond(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 연못
        let pond = CGRect(x: w * 0.08, y: h * 0.62, width: w * 0.84, height: h * 0.30)
        context.fill(Path(ellipseIn: pond), with: .color(Palette.dusk.opacity(0.42)))
        context.stroke(Path(ellipseIn: pond), with: .color(Palette.lineSoft.opacity(0.4)), lineWidth: 1.1)

        // 물결
        for index in 0..<3 {
            var ripple = Path()
            let y = pond.minY + pond.height * (0.25 + CGFloat(index) * 0.20)
            ripple.move(to: CGPoint(x: pond.minX + 30 + CGFloat(index) * 20, y: y))
            ripple.addQuadCurve(
                to: CGPoint(x: pond.maxX - 30 - CGFloat(index) * 20, y: y),
                control: CGPoint(x: pond.midX, y: y - 12)
            )
            context.stroke(ripple, with: .color(Palette.cream.opacity(0.5)), lineWidth: 1)
        }

        // 수련잎
        for index in 0..<4 {
            let pad = CGRect(
                x: w * (0.16 + CGFloat(index) * 0.20),
                y: h * (0.68 + CGFloat(index % 2) * 0.10),
                width: w * 0.14,
                height: h * 0.05
            )
            context.fill(Path(ellipseIn: pad), with: .color(Palette.sage))
            context.stroke(Path(ellipseIn: pad), with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 1)
        }

        // 갈대
        for index in 0..<4 {
            var reed = Path()
            let x = w * (0.84 + CGFloat(index) * 0.035)
            reed.move(to: CGPoint(x: x, y: h * 0.76))
            reed.addLine(to: CGPoint(x: x - 8, y: h * 0.52))
            context.stroke(reed, with: .color(Palette.lineSoft.opacity(0.55)), lineWidth: 1.2)
            let tip = Path(ellipseIn: CGRect(x: x - 13, y: h * 0.48, width: 10, height: 18))
            context.fill(tip, with: .color(Palette.butter))
        }

        // 반딧불이
        for index in 0..<8 {
            let x = w * (0.30 + CGFloat(index) * 0.07)
            let y = h * (0.26 + CGFloat((index * 17) % 20) / 100)
            Brush.glow(&context, center: CGPoint(x: x + 13, y: y + 13), radius: 22, strength: 0.45)
            var dot = Path()
            dot.addEllipse(in: CGRect(x: x + 9, y: y + 9, width: 8, height: 8))
            context.fill(dot, with: .color(Palette.cream))
        }

        // 연못 위로 내려오는 달빛
        Brush.glow(&context, center: CGPoint(x: w * 0.52, y: h * 0.40), radius: w * 0.55, strength: 0.16)
    }

    private func paintGlassHouse(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 유리 격자
        var panes = Path()
        var x: CGFloat = 0
        while x < w {
            panes.move(to: CGPoint(x: x, y: 0))
            panes.addLine(to: CGPoint(x: x, y: h * 0.76))
            x += w * 0.14
        }
        var y: CGFloat = 0
        while y < h * 0.76 {
            panes.move(to: CGPoint(x: 0, y: y))
            panes.addLine(to: CGPoint(x: w, y: y))
            y += h * 0.16
        }
        context.stroke(panes, with: .color(Palette.sage.opacity(0.35)), lineWidth: 1.1)

        // 거꾸로 자라는 나무
        var trunk = Path()
        trunk.move(to: CGPoint(x: w * 0.28, y: 0))
        trunk.addQuadCurve(
            to: CGPoint(x: w * 0.30, y: h * 0.46),
            control: CGPoint(x: w * 0.24, y: h * 0.24)
        )
        context.stroke(trunk, with: .color(Palette.wood.opacity(0.85)), lineWidth: 2.4)

        for index in 0..<7 {
            let leaf = Brush.blob(
                center: CGPoint(
                    x: w * (0.18 + CGFloat(index % 4) * 0.09),
                    y: h * (0.24 + CGFloat(index / 4) * 0.16)
                ),
                radius: 14,
                wobble: 0.14,
                seed: index + 2
            )
            context.fill(leaf, with: .color(Palette.sage.opacity(0.85)))
            context.stroke(leaf, with: .color(Palette.lineSoft.opacity(0.4)), lineWidth: 1)
        }

        // 달빛 웅덩이
        let pool = CGRect(x: w * 0.56, y: h * 0.30, width: w * 0.32, height: h * 0.22)
        context.fill(Path(ellipseIn: pool), with: .color(Palette.butter.opacity(0.16)))

        // 반딧불 랜턴 빛이 스미는 정도만 남긴다
        Brush.glow(&context, center: CGPoint(x: w * 0.52, y: h * 0.55), radius: w * 0.48, strength: 0.16)
    }

    // MARK: 스테이지 3

    private func paintGearStairs(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 나선 계단
        for index in 0..<5 {
            var step = Path()
            let y = h * (0.26 + CGFloat(index) * 0.11)
            step.move(to: CGPoint(x: w * (0.44 - CGFloat(index) * 0.03), y: y))
            step.addLine(to: CGPoint(x: w * (0.86 - CGFloat(index) * 0.02), y: y - h * 0.02))
            step.addLine(to: CGPoint(x: w * (0.86 - CGFloat(index) * 0.02), y: y + h * 0.05))
            step.addLine(to: CGPoint(x: w * (0.44 - CGFloat(index) * 0.03), y: y + h * 0.05))
            step.closeSubpath()
            Brush.paint(step, in: &context, fill: Palette.wood.opacity(0.75), width: 1.1)
        }

        // 진자
        var rod = Path()
        rod.move(to: CGPoint(x: w * 0.30, y: h * 0.10))
        rod.addLine(to: CGPoint(x: w * 0.36, y: h * 0.48))
        context.stroke(rod, with: .color(Palette.butter), lineWidth: 1.8)
        let bob = Path(ellipseIn: CGRect(x: w * 0.32, y: h * 0.46, width: w * 0.09, height: w * 0.09))
        Brush.paint(bob, in: &context, fill: Palette.butter)

        // 계단 스탠드 불빛
        Brush.glow(&context, center: CGPoint(x: w * 0.36, y: h * 0.52), radius: w * 0.26, strength: 0.24)

        // 창
        let slit = CGRect(x: w * 0.70, y: h * 0.14, width: w * 0.10, height: h * 0.26)
        Brush.paint(Brush.rect(slit, corner: 8), in: &context, fill: Palette.duskDeep)
        context.fill(Path(slit), with: .color(Palette.cream.opacity(0.18)))

        pole(&context, size)
    }

    private func paintGearRoom(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        let gears: [(CGPoint, CGFloat, Int)] = [
            (CGPoint(x: w * 0.30, y: h * 0.36), min(w, h) * 0.14, 12),
            (CGPoint(x: w * 0.58, y: h * 0.52), min(w, h) * 0.10, 10),
            (CGPoint(x: w * 0.78, y: h * 0.32), min(w, h) * 0.07, 9)
        ]
        let fills: [Color] = [Palette.butter, Palette.rose, Palette.sage]
        for (index, gear) in gears.enumerated() {
            let path = Brush.gear(center: gear.0, radius: gear.1, teeth: gear.2)
            Brush.paint(path, in: &context, fill: fills[index], width: 1.4)
            let hub = Path(ellipseIn: CGRect(
                x: gear.0.x - gear.1 * 0.22,
                y: gear.0.y - gear.1 * 0.22,
                width: gear.1 * 0.44,
                height: gear.1 * 0.44
            ))
            context.fill(hub, with: .color(Palette.cream))
            context.stroke(hub, with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 1)
        }

        // 파이프
        var pipes = Path()
        pipes.move(to: CGPoint(x: 0, y: h * 0.66))
        pipes.addLine(to: CGPoint(x: w * 0.24, y: h * 0.66))
        pipes.addLine(to: CGPoint(x: w * 0.24, y: h * 0.76))
        pipes.move(to: CGPoint(x: w * 0.66, y: h * 0.76))
        pipes.addLine(to: CGPoint(x: w * 0.66, y: h * 0.60))
        context.stroke(pipes, with: .color(Palette.dusk.opacity(0.85)), lineWidth: 2.2)

        // 촛농이 굳은 자리의 촛불
        Brush.glow(&context, center: CGPoint(x: w * 0.38, y: h * 0.46), radius: w * 0.30, strength: 0.30)
        let candleBody = Brush.rect(CGRect(x: w * 0.36, y: h * 0.52, width: w * 0.045, height: h * 0.10), corner: 2)
        Brush.paint(candleBody, in: &context, fill: Palette.cream)
        let flame = Path(ellipseIn: CGRect(x: w * 0.373, y: h * 0.46, width: w * 0.014, height: h * 0.05))
        context.fill(flame, with: .color(Palette.candle))

        pole(&context, size)
    }

    private func paintBelfry(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 종이 종
        let bell = Path()
        bell.move(to: CGPoint(x: w * 0.42, y: h * 0.18))
        bell.addQuadCurve(
            to: CGPoint(x: w * 0.30, y: h * 0.50),
            control: CGPoint(x: w * 0.30, y: h * 0.28)
        )
        bell.addLine(to: CGPoint(x: w * 0.70, y: h * 0.50))
        bell.addQuadCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.18),
            control: CGPoint(x: w * 0.70, y: h * 0.28)
        )
        bell.closeSubpath()
        Brush.paint(bell, in: &context, fill: Palette.butter)
        Brush.glow(&context, center: CGPoint(x: w * 0.50, y: h * 0.36), radius: w * 0.45, strength: 0.30)

        var rope = Path()
        rope.move(to: CGPoint(x: w * 0.50, y: 0))
        rope.addLine(to: CGPoint(x: w * 0.50, y: h * 0.18))
        context.stroke(rope, with: .color(Palette.lineSoft.opacity(0.6)), lineWidth: 1.4)

        // 종 아래 달 홈
        let socket = Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.50, width: w * 0.08, height: w * 0.08))
        context.fill(socket, with: .color(Palette.duskDeep))
        context.stroke(socket, with: .color(Palette.lineSoft.opacity(0.5)), lineWidth: 1)

        // 별
        for index in 0..<10 {
            let star = Brush.star(
                center: CGPoint(
                    x: w * (0.10 + CGFloat(index % 5) * 0.18),
                    y: h * (0.12 + CGFloat(index / 5) * 0.12)
                ),
                outer: 6,
                inner: 2.5,
                points: 4
            )
            context.fill(star, with: .color(Palette.cream.opacity(0.85)))
        }

        // 종이 계단
        var stairs = Path()
        stairs.move(to: CGPoint(x: w * 0.82, y: h * 0.08))
        stairs.addLine(to: CGPoint(x: w * 0.92, y: h * 0.20))
        stairs.addLine(to: CGPoint(x: w * 0.86, y: h * 0.20))
        stairs.addLine(to: CGPoint(x: w * 0.96, y: h * 0.32))
        context.stroke(stairs, with: .color(Palette.cream.opacity(0.7)), lineWidth: 1.3)
    }

    // MARK: 보너스 장면 · 비밀 다락방 지하실

    private func paintCellarStairs(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 내려가는 돌계단
        for index in 0..<6 {
            let step = CGRect(
                x: w * (0.16 + CGFloat(index) * 0.015),
                y: h * (0.30 + CGFloat(index) * 0.085),
                width: w * (0.66 - CGFloat(index) * 0.03),
                height: h * 0.062
            )
            Brush.paint(Brush.rect(step, corner: 5), in: &context, fill: Color(red: 0.52, green: 0.47, blue: 0.42))
            var edge = Path()
            edge.move(to: CGPoint(x: step.minX, y: step.maxY))
            edge.addLine(to: CGPoint(x: step.maxX, y: step.maxY))
            context.stroke(edge, with: .color(Palette.lineSoft.opacity(0.35)), lineWidth: 1)
        }

        // 벽돌 아치
        var arch = Path()
        arch.move(to: CGPoint(x: w * 0.10, y: h * 0.30))
        arch.addQuadCurve(to: CGPoint(x: w * 0.90, y: h * 0.30), control: CGPoint(x: w * 0.50, y: h * 0.02))
        context.stroke(arch, with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 2)

        var bricks = Path()
        var y: CGFloat = h * 0.05
        while y < h * 0.30 {
            bricks.move(to: CGPoint(x: w * 0.08, y: y))
            bricks.addLine(to: CGPoint(x: w * 0.92, y: y))
            y += h * 0.05
        }
        context.stroke(bricks, with: .color(Palette.lineSoft.opacity(0.12)), lineWidth: 1)

        // 벽 고리와 기름등잔 자리
        let hook = CGPoint(x: w * 0.82, y: h * 0.26)
        context.stroke(
            Path { path in
                path.move(to: hook)
                path.addLine(to: CGPoint(x: hook.x, y: hook.y + 18))
            },
            with: .color(Palette.lineSoft.opacity(0.6)),
            lineWidth: 1.6
        )
        Brush.glow(&context, center: CGPoint(x: w * 0.82, y: h * 0.36), radius: w * 0.20, strength: 0.34)

        // 벽돌 틈
        let nook = CGRect(x: w * 0.06, y: h * 0.74, width: w * 0.10, height: h * 0.07)
        Brush.paint(Brush.rect(nook, corner: 3), in: &context, fill: Palette.duskDeep.opacity(0.85))

        pole(&context, size)
    }

    private func paintCellarPantry(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 포도주 선반 두 줄
        for row in 0..<2 {
            let shelfY = h * (0.24 + CGFloat(row) * 0.20)
            Brush.paint(
                Brush.rect(CGRect(x: w * 0.30, y: shelfY, width: w * 0.52, height: h * 0.030), corner: 3),
                in: &context,
                fill: Color(red: 0.55, green: 0.42, blue: 0.32)
            )
            for index in 0..<4 {
                let bottle = CGRect(
                    x: w * (0.33 + CGFloat(index) * 0.12),
                    y: shelfY - h * 0.075,
                    width: w * 0.045,
                    height: h * 0.075
                )
                Brush.paint(Brush.rect(bottle, corner: 6), in: &context, fill: Palette.duskDeep.opacity(0.75))
                var neck = Path()
                neck.move(to: CGPoint(x: bottle.midX, y: bottle.minY))
                neck.addLine(to: CGPoint(x: bottle.midX, y: bottle.minY - 10))
                context.stroke(neck, with: .color(Palette.lineSoft.opacity(0.55)), lineWidth: 2)
            }
        }

        // 찢어진 라벨
        let label = CGRect(x: w * 0.14, y: h * 0.28, width: w * 0.13, height: h * 0.12)
        context.fill(Brush.rect(label, corner: 3), with: .color(Palette.cream.opacity(0.9)))
        var tear = Path()
        tear.move(to: CGPoint(x: label.midX, y: label.minY))
        tear.addLine(to: CGPoint(x: label.midX - 4, y: label.midY))
        tear.addLine(to: CGPoint(x: label.midX + 3, y: label.maxY))
        context.stroke(tear, with: .color(Palette.lineSoft.opacity(0.6)), lineWidth: 1.1)

        // 물 고인 바닥
        let puddle = CGRect(x: w * 0.58, y: h * 0.80, width: w * 0.38, height: h * 0.12)
        context.fill(Path(ellipseIn: puddle), with: .color(Palette.dusk.opacity(0.42)))
        context.stroke(Path(ellipseIn: puddle), with: .color(Palette.cream.opacity(0.4)), lineWidth: 1)

        // 양피지 상자
        Brush.paint(
            Brush.rect(CGRect(x: w * 0.22, y: h * 0.64, width: w * 0.20, height: h * 0.12), corner: 6),
            in: &context,
            fill: Color(red: 0.66, green: 0.51, blue: 0.37)
        )

        Brush.glow(&context, center: CGPoint(x: w * 0.60, y: h * 0.40), radius: w * 0.34, strength: 0.22)
        pole(&context, size)
    }

    private func paintCellarVault(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width
        let h = size.height

        // 달 모양 금고 문
        let door = CGRect(x: w * 0.32, y: h * 0.16, width: w * 0.36, height: w * 0.36)
        context.fill(Path(ellipseIn: door), with: .color(Color(red: 0.72, green: 0.62, blue: 0.45)))
        context.stroke(Path(ellipseIn: door), with: .color(Palette.lineSoft.opacity(0.6)), lineWidth: 2)

        let bite = Brush.blob(
            center: CGPoint(x: door.midX + door.width * 0.26, y: door.midY - door.height * 0.16),
            radius: door.width * 0.24,
            wobble: 0.05,
            seed: 7
        )
        context.fill(bite, with: .color(Palette.wall(.cellarVault)))
        context.stroke(bite, with: .color(Palette.lineSoft.opacity(0.45)), lineWidth: 1.1)

        // 열쇠 구멍과 암호판
        let keyhole = Path(ellipseIn: CGRect(
            x: door.midX - 7,
            y: door.midY - 6,
            width: 14,
            height: 14
        ))
        context.fill(keyhole, with: .color(Palette.duskDeep))
        Brush.paint(
            Brush.rect(CGRect(x: door.maxX + w * 0.03, y: door.midY - h * 0.05,
                              width: w * 0.09, height: h * 0.10), corner: 4),
            in: &context,
            fill: Palette.butter.opacity(0.75)
        )

        // 장부 책상
        Brush.paint(
            Brush.rect(CGRect(x: w * 0.66, y: h * 0.62, width: w * 0.26, height: h * 0.05), corner: 4),
            in: &context,
            fill: Color(red: 0.52, green: 0.40, blue: 0.31)
        )
        let book = CGRect(x: w * 0.70, y: h * 0.55, width: w * 0.14, height: h * 0.07)
        Brush.paint(Brush.rect(book, corner: 3), in: &context, fill: Palette.roseDeep.opacity(0.8))
        var pages = Path()
        pages.move(to: CGPoint(x: book.midX, y: book.minY + 2))
        pages.addLine(to: CGPoint(x: book.midX, y: book.maxY - 2))
        context.stroke(pages, with: .color(Palette.cream.opacity(0.7)), lineWidth: 1)

        // 낮은 앨범 선반
        Brush.paint(
            Brush.rect(CGRect(x: w * 0.10, y: h * 0.66, width: w * 0.22, height: h * 0.035), corner: 3),
            in: &context,
            fill: Color(red: 0.46, green: 0.36, blue: 0.29)
        )

        // 촛불 두 자루
        for index in 0..<2 {
            let x = w * (0.24 + CGFloat(index) * 0.52)
            Brush.glow(&context, center: CGPoint(x: x, y: h * 0.44), radius: w * 0.20, strength: 0.3)
            Brush.paint(
                Brush.rect(CGRect(x: x - w * 0.012, y: h * 0.50, width: w * 0.024, height: h * 0.08), corner: 2),
                in: &context,
                fill: Palette.cream
            )
            context.fill(
                Path(ellipseIn: CGRect(x: x - w * 0.007, y: h * 0.455, width: w * 0.014, height: h * 0.045)),
                with: .color(Palette.candle)
            )
        }

        pole(&context, size)
    }

}
