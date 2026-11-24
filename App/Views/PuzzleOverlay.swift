import SwiftUI
import PaperMoonCore

/// 힌트 카드. 1단계는 방향만, 2단계는 구체적인 해법을 보여 준다.
struct HintOverlay: View {
    let card: GameStore.HintCard
    let onMore: () -> Void
    let onClose: () -> Void

    private var title: String {
        card.level <= 1 ? "힌트 1단계 · 어디를 볼까" : "힌트 2단계 · 이렇게 해 보자"
    }

    var body: some View {
        ZStack {
            Palette.line.opacity(0.26)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Palette.line)
                    Text(verbatim: title)
                        .font(.cozy(14, weight: .semibold))
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
                    .accessibilityLabel(Text(verbatim: "힌트 닫기"))
                }

                Text(card.text)
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Palette.line)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Palette.butter.opacity(0.22))
                    )

                HStack(spacing: 10) {
                    if card.hasMore {
                        Button("한 번 더 알려줘", action: onMore)
                            .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                    }
                    Button("혼자 해 볼래", action: onClose)
                        .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .frame(maxWidth: 360)
            .paperCard()
            .padding(.horizontal, 22)
        }
    }
}

/// 미니게임 퍼즐 화면.
struct PuzzleOverlay: View {
    let puzzle: Puzzle
    let misses: Int
    let onSubmit: ([Int]) -> Void
    let onClose: () -> Void

    @State private var answer: [Int] = []

    private var blockColors: [Color] {
        [Palette.rose, Palette.dusk, Palette.butter, Palette.sage, Palette.mauve]
    }

    var body: some View {
        ZStack {
            Palette.line.opacity(0.30)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 12) {
                header
                prompt
                slots
                if puzzle.kind == .dials {
                    dials
                } else {
                    tokens
                }
                if misses > 0 {
                    Text("아직 아니야. 단서를 다시 보자.")
                        .font(.cozy(12, weight: .semibold))
                        .foregroundStyle(Palette.rose)
                }
                footer
            }
            .padding(16)
            .frame(maxWidth: 420)
            .paperCard()
            .padding(.horizontal, 14)
        }
        .onAppear(perform: prepare)
    }

    // MARK: 머리

    private var header: some View {
        HStack(spacing: 8) {
            Text(verbatim: "🧩")
                .font(.system(size: 20))
            Text(puzzle.title)
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
            .accessibilityLabel(Text(verbatim: "퍼즐 닫기"))
        }
    }

    private var prompt: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(puzzle.prompt)
                .font(.cozy(14, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(puzzle.clue)
                .font(.cozy(12, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.paper)
        )
    }

    // MARK: 답 칸

    private var slots: some View {
        HStack(spacing: 8) {
            ForEach(0..<puzzle.solution.count, id: \.self) { index in
                slotView(index)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func slotView(_ index: Int) -> some View {
        let placed = index < answer.count ? answer[index] : nil
        let token = placed.flatMap { value in puzzle.tokens.first { $0.value == value } }

        return VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(token == nil ? Palette.paper : Palette.cream)
                    .frame(width: 52, height: 52)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        Palette.lineSoft.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1.1, dash: token == nil ? [5, 4] : [])
                    )
                    .frame(width: 52, height: 52)
                if let token {
                    Text(verbatim: token.symbol)
                        .font(.system(size: 22))
                } else {
                    Text(verbatim: "?")
                        .font(.cozy(16, weight: .bold))
                        .foregroundStyle(Palette.lineSoft.opacity(0.5))
                }
            }
            if index < puzzle.slotLabels.count {
                Text(verbatim: puzzle.slotLabels[index])
                    .font(.cozy(9.5, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                    .lineLimit(1)
            }
        }
    }

    // MARK: 입력(블록 · 노래)

    private var tokens: some View {
        VStack(spacing: 6) {
            Text("아래에서 차례대로 골라 보자")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)

            HStack(spacing: 8) {
                ForEach(puzzle.tokens, id: \.value) { token in
                    Button {
                        append(token.value)
                    } label: {
                        VStack(spacing: 3) {
                            Text(verbatim: token.symbol)
                                .font(.system(size: 22))
                                .frame(width: 46, height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(blockColors[token.value % blockColors.count].opacity(0.85))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1)
                                )
                            Text(verbatim: token.label)
                                .font(.cozy(10, weight: .semibold))
                                .foregroundStyle(Palette.line)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: token.label))
                }
            }
        }
    }

    // MARK: 입력(다이얼)

    private var dials: some View {
        HStack(spacing: 10) {
            ForEach(0..<answer.count, id: \.self) { index in
                Button {
                    cycleDial(index)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Palette.cream)
                                .frame(width: 62, height: 62)
                            Circle()
                                .stroke(Palette.lineSoft.opacity(0.55), lineWidth: 1.3)
                                .frame(width: 62, height: 62)
                            Text(verbatim: dialSymbol(index))
                                .font(.system(size: 26))
                        }
                        Text(verbatim: dialLabel(index))
                            .font(.cozy(10, weight: .semibold))
                            .foregroundStyle(Palette.line)
                        if index < puzzle.slotLabels.count {
                            Text(verbatim: puzzle.slotLabels[index])
                                .font(.cozy(9, weight: .semibold))
                                .foregroundStyle(Palette.lineSoft)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "다이얼 \(index + 1) 돌리기"))
            }
        }
    }

    // MARK: 아래 버튼

    private var footer: some View {
        HStack(spacing: 10) {
            Button("지우기", action: reset)
                .buttonStyle(CozyButtonStyle(fill: Palette.cream))
            Spacer()
            Button("확인", action: submit)
                .buttonStyle(CozyButtonStyle(fill: canSubmit ? Palette.butter : Palette.cloud))
                .disabled(!canSubmit)
        }
    }

    // MARK: 동작

    private var canSubmit: Bool {
        answer.count == puzzle.solution.count
    }

    private func prepare() {
        if puzzle.kind == .dials {
            let first = puzzle.tokens.first?.value ?? 0
            answer = Array(repeating: first, count: puzzle.solution.count)
        } else {
            answer = []
        }
    }

    private func append(_ value: Int) {
        guard answer.count < puzzle.solution.count else { return }
        answer.append(value)
    }

    private func reset() {
        prepare()
    }

    private func submit() {
        guard canSubmit else { return }
        onSubmit(answer)
    }

    private func cycleDial(_ index: Int) {
        guard index < answer.count else { return }
        let values = puzzle.tokens.map { $0.value }
        guard let position = values.firstIndex(of: answer[index]) else { return }
        answer[index] = values[(position + 1) % values.count]
    }

    private func dialSymbol(_ index: Int) -> String {
        guard index < answer.count else { return "?" }
        return puzzle.tokens.first { $0.value == answer[index] }?.symbol ?? "?"
    }

    private func dialLabel(_ index: Int) -> String {
        guard index < answer.count else { return "?" }
        return puzzle.tokens.first { $0.value == answer[index] }?.label ?? "?"
    }
}
