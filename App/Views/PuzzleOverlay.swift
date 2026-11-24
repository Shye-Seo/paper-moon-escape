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

/// 퍼즐 카드의 공통 머리. 종류마다 아이콘만 바꾼다.
struct PuzzleHeader: View {
    let glyph: String
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: glyph)
                .font(.system(size: 20))
            Text(verbatim: title)
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
}

/// 퍼즐의 안내문 + 단서.
struct PuzzlePromptCard: View {
    let prompt: String
    let clue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: prompt)
                .font(.cozy(14, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: clue)
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
}

/// 미니게임 퍼즐 화면. 퍼즐 종류에 따라 몸통만 바뀐다.
struct PuzzleOverlay: View {
    let puzzle: Puzzle
    let misses: Int
    /// 종이접기에서 지금까지 접은 순서. 엔진이 갖고 있는 값을 그대로 그린다.
    let folded: [Int]
    @ObservedObject var motion: MotionManager
    let onSubmit: ([Int]) -> Void
    /// 종이를 한 번 접는다. 틀리면 엔진이 접힘을 전부 푼다.
    let onFold: (Int) -> Void
    let onResetFold: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Palette.line.opacity(0.30)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            switch puzzle.kind {
            case .origami:
                OrigamiBoard(
                    puzzle: puzzle,
                    misses: misses,
                    folded: folded,
                    onFold: onFold,
                    onResetFold: onResetFold,
                    onClose: onClose
                )
            case .lightReveal:
                LightRevealBoard(
                    puzzle: puzzle,
                    misses: misses,
                    motion: motion,
                    onSubmit: onSubmit,
                    onClose: onClose
                )
            case .blocks, .song, .dials:
                ClassicPuzzleBoard(puzzle: puzzle, misses: misses, onSubmit: onSubmit, onClose: onClose)
            }
        }
    }
}

/// 블록·노래·다이얼처럼 순서만 맞추면 되는 기존 퍼즐.
struct ClassicPuzzleBoard: View {
    let puzzle: Puzzle
    let misses: Int
    let onSubmit: ([Int]) -> Void
    let onClose: () -> Void

    @State private var answer: [Int] = []

    private var blockColors: [Color] {
        [Palette.rose, Palette.dusk, Palette.butter, Palette.sage, Palette.mauve]
    }

    var body: some View {
        VStack(spacing: 12) {
            PuzzleHeader(glyph: "🧩", title: puzzle.title, onClose: onClose)
            PuzzlePromptCard(prompt: puzzle.prompt, clue: puzzle.clue)
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
        .onAppear(perform: prepare)
    }

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

/// 종이접기 퍼즐. 화면의 종이를 쓸어 접거나, 접기 단추를 순서대로 누른다.
/// 쓸기 방향은 위(귀 모으기) · 아래(아래로 접기) · 왼쪽(가운데 누르기) · 오른쪽(모양 펴기).
///
/// 한 번 접을 때마다 엔진이 도안과 대조한다. 순서가 틀리면 **접힘이 전부 풀리고**
/// 첫 접기부터 다시 해야 한다. 그래서 확인 단추 없이, 접는 순간이 곧 판정이다.
struct OrigamiBoard: View {
    let puzzle: Puzzle
    let misses: Int
    let folded: [Int]
    let onFold: (Int) -> Void
    let onResetFold: () -> Void
    let onClose: () -> Void

    private var paperSize: CGFloat { 190 }

    /// 지금까지 접힌 만큼 종이가 기운다.
    private var foldTurn: Double { Double(folded.count) * 45 }

    private var remaining: Int { max(0, puzzle.solution.count - folded.count) }

    var body: some View {
        VStack(spacing: 12) {
            PuzzleHeader(glyph: "🪷", title: puzzle.title, onClose: onClose)
            PuzzlePromptCard(prompt: puzzle.prompt, clue: puzzle.clue)
            paper
            progressRow
            stepList
            folds
            if misses > 0 {
                Text("잘못 접으면 접힌 자리가 모두 풀린다. 지금까지 \(misses)번 풀렸다.")
                    .font(.cozy(11.5, weight: .semibold))
                    .foregroundStyle(Palette.roseDeep)
                    .multilineTextAlignment(.center)
            }
            footer
        }
        .padding(16)
        .frame(maxWidth: 420)
        .paperCard()
        .padding(.horizontal, 14)
    }

    // MARK: 접는 종이

    private var paper: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.cream)
                .frame(width: paperSize, height: paperSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.lineSoft.opacity(0.5), lineWidth: 1.3)
                )

            // 접힌 자리
            Rectangle()
                .fill(Palette.lineSoft.opacity(0.18))
                .frame(width: 1.2, height: paperSize)
                .rotationEffect(.degrees(foldTurn))

            Triangle()
                .fill(Palette.butter.opacity(0.55))
                .frame(width: paperSize * 0.7, height: paperSize * 0.7)
                .rotationEffect(.degrees(foldTurn))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous).size(width: paperSize, height: paperSize))
                .offset(y: folded.isEmpty ? 0 : 6)

            VStack(spacing: 2) {
                Text(verbatim: "🌙")
                    .font(.system(size: 40))
                    .opacity(folded.isEmpty ? 0.25 : 0.9)
                Text(verbatim: goalText)
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 22)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    if abs(dx) > abs(dy) {
                        fold(index(matching: dx < 0 ? "가운데" : "펴"))
                    } else {
                        fold(index(matching: dy < 0 ? "귀" : "아래"))
                    }
                }
        )
        .accessibilityLabel(Text(verbatim: "접는 종이. 위아래좌우로 쓸거나 아래 단추로 접는다."))
    }

    private var goalText: String {
        if let goal = puzzle.goal { return "목표: \(goal)" }
        return "순서대로 접기"
    }

    // MARK: 접은 순서

    private var progressRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Text(folded.isEmpty
                 ? "첫 접기를 고르면 종이가 움직인다"
                 : "지금 \(folded.count)번 접었다. \(remaining)번 남았다.")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Spacer(minLength: 0)
        }
    }

    private var stepList: some View {
        HStack(spacing: 6) {
            ForEach(0..<puzzle.solution.count, id: \.self) { index in
                let value = index < folded.count ? folded[index] : nil
                let token = value.flatMap { stepsValue in puzzle.tokens.first { $0.value == stepsValue } }
                VStack(spacing: 2) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(token == nil ? Palette.paper : Palette.cream)
                            .frame(width: 46, height: 46)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                Palette.lineSoft.opacity(0.5),
                                style: StrokeStyle(lineWidth: 1.1, dash: token == nil ? [4, 4] : [])
                            )
                            .frame(width: 46, height: 46)
                        Text(verbatim: token?.symbol ?? "·")
                            .font(.system(size: 20))
                            .foregroundStyle(token == nil ? Palette.lineSoft.opacity(0.4) : Palette.line)
                    }
                    Text(verbatim: index < puzzle.slotLabels.count ? puzzle.slotLabels[index] : "\(index + 1)")
                        .font(.cozy(9, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 접기 단추

    private var folds: some View {
        VStack(spacing: 6) {
            Text("종이를 쓸거나, 접기 단추를 차례로 눌러도 된다")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            HStack(spacing: 8) {
                ForEach(puzzle.tokens, id: \.value) { token in
                    Button {
                        fold(token.value)
                    } label: {
                        VStack(spacing: 3) {
                            Text(verbatim: token.symbol)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Palette.butter.opacity(0.55))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1)
                                )
                            Text(verbatim: token.label)
                                .font(.cozy(9.5, weight: .semibold))
                                .foregroundStyle(Palette.line)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(remaining == 0)
                    .accessibilityLabel(Text(verbatim: token.label))
                    .accessibilityHint(Text(verbatim: "이 순서로 접으면 종이가 접힌다. 틀리면 처음부터"))
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button("펼치기", action: onResetFold)
                .buttonStyle(CozyButtonStyle(fill: Palette.cream))
            Spacer()
            Text(remaining == 0 ? "마지막 접기다" : "\(remaining)번 남음")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
        }
    }

    private func index(matching needle: String) -> Int? {
        puzzle.tokens.first { $0.label.contains(needle) }?.value
    }

    private func fold(_ value: Int?) {
        guard let value, remaining > 0 else { return }
        onFold(value)
    }
}

/// 빛 투과 퍼즐. 찢긴 조각을 칸에 맞추고, 빛을 비춰 숨은 글자를 읽는다.
/// 기기를 기울이면 빛줄기가 따라 움직이고, '빛 비추기' 단추로도 같은 일을 할 수 있다.
struct LightRevealBoard: View {
    let puzzle: Puzzle
    let misses: Int
    @ObservedObject var motion: MotionManager
    let onSubmit: ([Int]) -> Void
    let onClose: () -> Void

    @State private var slots: [Int?] = []
    @State private var picked: Int?
    @State private var lit = false
    @State private var beam: CGFloat = 0

    private var allFilled: Bool {
        slots.count == puzzle.solution.count && slots.allSatisfy { $0 != nil }
    }

    private var answer: [Int] {
        slots.compactMap { $0 }
    }

    private var tray: [PuzzleToken] {
        puzzle.tokens.filter { token in !slots.contains(where: { $0 == token.value }) }
    }

    var body: some View {
        VStack(spacing: 12) {
            PuzzleHeader(glyph: "🔦", title: puzzle.title, onClose: onClose)
            PuzzlePromptCard(prompt: puzzle.prompt, clue: puzzle.clue)
            paper
            trayView
            lightRow
            if misses > 0 {
                Text("조각이 어긋나 글씨가 보이지 않는다. 가장자리를 다시 보자.")
                    .font(.cozy(12, weight: .semibold))
                    .foregroundStyle(Palette.rose)
            }
            footer
        }
        .padding(16)
        .frame(maxWidth: 420)
        .paperCard()
        .padding(.horizontal, 14)
        .onAppear {
            if slots.isEmpty {
                slots = Array(repeating: nil, count: puzzle.solution.count)
            }
            motion.start()
        }
        .onChange(of: motion.tiltX) { _, value in
            withAnimation(.easeOut(duration: 0.2)) {
                beam = CGFloat(value)
            }
        }
    }

    // MARK: 종이 판

    private var paper: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.cream)
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.lineSoft.opacity(0.5), lineWidth: 1.3)
                )
                .overlay(
                    GridShape(columns: 2, rows: 2, inset: 18)
                        .stroke(Palette.lineSoft.opacity(0.18), lineWidth: 1)
                )

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    slotCell(0)
                    slotCell(1)
                }
                HStack(spacing: 8) {
                    slotCell(2)
                    slotCell(3)
                }
            }
            .opacity(lit ? 0.35 : 1)

            if lit {
                revealedCode
            }

            // 빛줄기
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Palette.candleGlow.opacity(0), Palette.candleGlow.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 54, height: 200)
                .offset(x: beam * 70)
                .blendMode(.plusLighter)
                .opacity(lit ? 1 : 0)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    lit = true
                    beam = max(-1, min(1, (value.location.x / 220) * 2 - 1))
                }
        )
        .accessibilityLabel(Text(verbatim: "찢어진 종이 판. 조각을 맞추고 빛을 비춘다."))
    }

    private func slotCell(_ index: Int) -> some View {
        let value = index < slots.count ? slots[index] : nil
        let token = value.flatMap { placed in puzzle.tokens.first { $0.value == placed } }
        let label = index < puzzle.slotLabels.count ? puzzle.slotLabels[index] : "\(index + 1)"
        let isRight = value != nil && index < puzzle.solution.count && value == puzzle.solution[index]

        return Button {
            tapSlot(index)
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(token == nil ? Palette.paper : Palette.butter.opacity(0.35))
                        .frame(width: 78, height: 62)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            token == nil
                                ? Palette.lineSoft.opacity(0.55)
                                : (isRight ? Palette.sage : Palette.roseDeep.opacity(0.9)),
                            style: StrokeStyle(lineWidth: 1.1, dash: token == nil ? [5, 4] : [])
                        )
                        .frame(width: 78, height: 62)
                    Text(verbatim: token?.symbol ?? "＋")
                        .font(.system(size: token == nil ? 18 : 24))
                        .foregroundStyle(token == nil ? Palette.lineSoft.opacity(0.55) : Palette.line)
                }
                Text(verbatim: label)
                    .font(.cozy(9, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "\(label) 칸"))
    }

    private var revealedCode: some View {
        let readout = self.readout
        return VStack(spacing: 4) {
            Text(readout.isCrisp ? "숨은 글씨" : "숨은 글씨 · 아직 흐릿하다")
                .font(.cozy(10, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Text(verbatim: readout.partialCode)
                .font(.cozy(15, weight: .bold))
                .foregroundStyle(Palette.line)
                .multilineTextAlignment(.center)
                .blur(radius: readout.isCrisp ? 0 : CGFloat(readout.blurRadius))
                .padding(.horizontal, 12)
            Text(verbatim: readout.isCrisp ? "조각이 모두 제자리에 있다" : readout.clarityText)
                .font(.cozy(10, weight: .semibold))
                .foregroundStyle(readout.isCrisp ? Palette.lineSoft : Palette.roseDeep)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.butter.opacity(readout.isCrisp ? 0.55 : 0.35))
        )
        .padding(.horizontal, 16)
    }

    /// 지금 놓인 조각이 만드는 또렷함. 한 칸이라도 어긋나면 글씨가 번진다.
    /// 빈 칸은 -1로 채워 칸 순서가 밀리지 않게 한다.
    private var readout: LightReadout {
        puzzle.lightReadout(for: slots.map { $0 ?? -1 })
    }

    // MARK: 조각 고르기

    private var trayView: some View {
        VStack(spacing: 6) {
            Text(picked == nil ? "조각을 골라 칸에 놓아 보자" : "칸을 눌러 조각을 놓아 보자")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            HStack(spacing: 8) {
                if tray.isEmpty {
                    Text("모든 조각이 제자리에 있다.")
                        .font(.cozy(11, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                        .padding(.vertical, 8)
                }
                ForEach(tray, id: \.value) { token in
                    Button {
                        picked = (picked == token.value) ? nil : token.value
                    } label: {
                        VStack(spacing: 2) {
                            Text(verbatim: token.symbol)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(picked == token.value ? Palette.butter : Palette.paper)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1)
                                )
                            Text(verbatim: token.label)
                                .font(.cozy(9, weight: .semibold))
                                .foregroundStyle(Palette.line)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: token.label))
                }
            }
        }
    }

    private var lightRow: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.5)) {
                    lit.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: lit ? "sun.max.fill" : "sun.max")
                        .font(.system(size: 14, weight: .semibold))
                    Text(lit ? "빛 비추는 중" : "빛 비추기")
                        .font(.cozy(13, weight: .semibold))
                }
                .foregroundStyle(Palette.line)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(Palette.butter))
                .overlay(Capsule().stroke(Palette.lineSoft.opacity(0.5), lineWidth: 1.1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "빛 비추기"))

            Text(motion.available ? "기기를 기울여도 빛이 움직인다" : "기울이기 대신 이 단추를 써도 된다")
                .font(.cozy(10, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
                .lineLimit(2)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button("흩뜨리기", action: reset)
                .buttonStyle(CozyButtonStyle(fill: Palette.cream))
            Spacer()
            Text(canSubmit ? "조각이 맞았다" : "조각을 정확히 맞춰야 읽힌다")
                .font(.cozy(10.5, weight: .semibold))
                .foregroundStyle(canSubmit ? Palette.lineSoft : Palette.lineSoft.opacity(0.75))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
            Button("확인", action: submit)
                .buttonStyle(CozyButtonStyle(fill: canSubmit ? Palette.butter : Palette.cloud))
                .disabled(!canSubmit)
        }
    }

    /// 모든 칸이 차고 빛을 비추며 조각이 **정확히** 맞아야 확인할 수 있다.
    private var canSubmit: Bool {
        allFilled && lit && readout.isCrisp
    }

    private func tapSlot(_ index: Int) {
        guard index < slots.count else { return }
        if let picked {
            if slots.contains(where: { $0 == picked }) {
                return
            }
            slots[index] = picked
            self.picked = nil
        } else if let placed = slots[index] {
            slots[index] = nil
            picked = placed
        }
    }

    private func reset() {
        slots = Array(repeating: nil, count: puzzle.solution.count)
        picked = nil
        lit = false
        beam = 0
    }

    private func submit() {
        guard canSubmit else { return }
        onSubmit(answer)
    }
}

/// 2×2 격자 선.
struct GridShape: Shape {
    let columns: Int
    let rows: Int
    let inset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inner = rect.insetBy(dx: inset, dy: inset)
        for column in 1..<max(columns, 1) {
            let x = inner.minX + inner.width * CGFloat(column) / CGFloat(columns)
            path.move(to: CGPoint(x: x, y: inner.minY))
            path.addLine(to: CGPoint(x: x, y: inner.maxY))
        }
        for row in 1..<max(rows, 1) {
            let y = inner.minY + inner.height * CGFloat(row) / CGFloat(rows)
            path.move(to: CGPoint(x: inner.minX, y: y))
            path.addLine(to: CGPoint(x: inner.maxX, y: y))
        }
        return path
    }
}
