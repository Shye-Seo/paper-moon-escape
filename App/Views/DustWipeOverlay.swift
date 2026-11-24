import SwiftUI
import PaperMoonCore

/// 먼지 쌓인 거울·장부를 문질러 닦는 화면.
///
/// - 손가락으로 문지르면 그 자리의 먼지가 걷힌다.
/// - 기기를 흔들면 조금씩 닦인다(자이로가 있을 때).
/// - 시뮬레이터·접근성 환경에서는 `대신 닦아 주기`가 한 번에 끝낸다.
struct DustWipeOverlay: View {
    let session: GameStore.DustSession
    @ObservedObject var motion: MotionManager
    let onWipe: (ScenePoint) -> Void
    let onShake: () -> Void
    let onSweep: () -> Void
    let onClose: () -> Void

    private var puzzle: DustWipePuzzle { session.puzzle }

    var body: some View {
        ZStack {
            Palette.line.opacity(0.34)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 12) {
                header
                Text(verbatim: session.panel.prompt)
                    .font(.cozy(12, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if session.isRevealed {
                    revealed
                } else {
                    board
                    gauge
                    controls
                }
            }
            .padding(16)
            .frame(maxWidth: 430)
            .paperCard()
            .padding(.horizontal, 14)
        }
        .onChange(of: motion.shakes) { _, _ in
            if !session.isRevealed {
                onShake()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(verbatim: "🪞")
                .font(.system(size: 20))
            Text(verbatim: session.panel.title)
                .font(.cozy(16, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.line)
                    .padding(6)
                    .background(Circle().fill(Palette.cream))
                    .overlay(Circle().stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "먼지 닦기 닫기"))
        }
    }

    private var board: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.paper)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Palette.lineSoft.opacity(0.5), lineWidth: 1.2)

                // 닦이면 드러날 글씨
                Text(verbatim: session.panel.revealText)
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(18)

                Canvas { context, size in
                    let columns = puzzle.columns
                    let rows = puzzle.rows
                    let cellWidth = size.width / CGFloat(max(columns, 1))
                    let cellHeight = size.height / CGFloat(max(rows, 1))
                    for row in 0..<rows {
                        for column in 0..<columns {
                            let dirt = puzzle.dust(column: column, row: row)
                            guard dirt > 0.02 else { continue }
                            let rect = CGRect(
                                x: CGFloat(column) * cellWidth,
                                y: CGFloat(row) * cellHeight,
                                width: cellWidth + 1,
                                height: cellHeight + 1
                            )
                            context.fill(
                                Path(rect),
                                with: .color(Palette.cloud.opacity(0.18 + dirt * 0.78))
                            )
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let width = max(geo.size.width, 1)
                        let height = max(geo.size.height, 1)
                        let x = min(1, max(0, value.location.x / width))
                        let y = min(1, max(0, value.location.y / height))
                        onWipe(ScenePoint(Double(x), Double(y)))
                    }
            )
            .accessibilityLabel(Text(verbatim: "먼지 판. 손가락으로 문질러 닦는다."))
        }
        .frame(height: 230)
    }

    private var gauge: some View {
        VStack(spacing: 4) {
            HStack {
                Text("닦은 정도")
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                Spacer()
                Text(verbatim: "\(puzzle.percent)%")
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.line)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.cloud)
                    Capsule()
                        .fill(Palette.butter)
                        .frame(width: geo.size.width * CGFloat(min(1, max(0, puzzle.clearedRatio))))
                }
            }
            .frame(height: 8)
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button("대신 닦아 주기", action: onSweep)
                    .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                Spacer()
                Button("그만 닦기", action: onClose)
                    .buttonStyle(CozyButtonStyle(fill: Palette.cloud))
            }
            Text(motion.available
                 ? "문지르거나 기기를 흔들어도 된다. 손이 불편하면 위 단추를 써도 된다."
                 : "기울이기·흔들기를 쓸 수 없는 환경이라면 '대신 닦아 주기'로 넘어가면 된다.")
                .font(.cozy(10, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var revealed: some View {
        VStack(spacing: 10) {
            Text(session.panel.revealText)
                .font(.cozy(13, weight: .semibold))
                .foregroundStyle(Palette.line)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.butter.opacity(0.35))
                )
            Button("확인", action: onClose)
                .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
