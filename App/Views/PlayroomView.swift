import SwiftUI
import PaperMoonCore

/// 엔딩 뒤에 열리는 「다락방 놀이방」.
/// 본편에서 만진 아이템과 같은 크림색 종이·촛불 빛을 그대로 써서, 다른 게임이 아니라
/// 다락방 서랍을 하나 더 연 느낌이 나게 했다.
struct PlayroomView: View {
    @ObservedObject var store: GameStore

    @State private var board: PlayroomBoard?

    var body: some View {
        ZStack {
            PaperBackground(tint: Color(red: 0.985, green: 0.945, blue: 0.878))

            if let board {
                switch board {
                case .memory(let difficulty):
                    MemoryDrawerBoard(
                        difficulty: difficulty,
                        bestRecord: store.miniGameRecord(for: .memoryDrawer, difficulty: difficulty),
                        onFinish: { moves, seconds, stars in
                            store.recordMemoryResult(
                                difficulty: difficulty,
                                moves: moves,
                                seconds: seconds,
                                stars: stars
                            )
                        },
                        onBack: { self.board = nil }
                    )
                case .challenge(let difficulty):
                    OrigamiChallengeBoard(
                        difficulty: difficulty,
                        bestRecord: store.miniGameRecord(for: .origamiChallenge, difficulty: difficulty),
                        onFinish: { completed, seconds, stars in
                            store.recordChallengeResult(
                                difficulty: difficulty,
                                completed: completed,
                                seconds: seconds,
                                stars: stars
                            )
                        },
                        onBack: { self.board = nil }
                    )
                }
            } else {
                hub
            }
        }
        .animation(.easeInOut(duration: 0.25), value: board)
    }

    // MARK: 놀이방 입구

    private var hub: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    RoundIconButton(systemName: "chevron.left", accessibility: "타이틀로") {
                        store.closePlayroom()
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("다락방 놀이방")
                            .font(.cozy(18, weight: .bold))
                            .foregroundStyle(Palette.line)
                        Text("엔딩 뒤에 열린 작은 서랍 두 개")
                            .font(.cozy(11, weight: .semibold))
                            .foregroundStyle(Palette.lineSoft)
                    }
                    Spacer()
                    Text(verbatim: "★ \(store.miniGameRecords.totalStars)/18")
                        .font(.cozy(12, weight: .semibold))
                        .foregroundStyle(Palette.line)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Palette.butter.opacity(0.7)))
                        .overlay(Capsule().stroke(Palette.lineSoft.opacity(0.4), lineWidth: 1.1))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Palette.candleGlow.opacity(0.32), Palette.candleGlow.opacity(0)],
                                center: .center,
                                startRadius: 6,
                                endRadius: 110
                            )
                        )
                        .frame(width: 210, height: 210)
                    MoonView(fill: Palette.cream)
                        .frame(width: 118, height: 118)
                    Text(verbatim: "🗄")
                        .font(.system(size: 34))
                        .offset(x: 62, y: 34)
                    Text(verbatim: "🪷")
                        .font(.system(size: 30))
                        .offset(x: -66, y: 30)
                }
                .frame(height: 170)

                gameCard(
                    id: .memoryDrawer,
                    tint: Palette.butter,
                    footer: "카드를 뒤집어 짝을 맞춘다. 적게 움직일수록 별이 늘어난다."
                ) { difficulty in
                    board = .memory(difficulty)
                }

                gameCard(
                    id: .origamiChallenge,
                    tint: Palette.sage,
                    footer: "도안의 접는 순서를 외워 연달아 접는다. 잘못 접으면 그 도안은 처음부터."
                ) { difficulty in
                    board = .challenge(difficulty)
                }

                Text("기록은 난이도별로 저장된다. 본편 진행에는 영향을 주지 않는다.")
                    .font(.cozy(10.5, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft.opacity(0.8))
                    .padding(.bottom, 20)
            }
        }
    }

    private func gameCard(
        id: MiniGameID,
        tint: Color,
        footer: String,
        onPick: @escaping (MiniGameDifficulty) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(verbatim: id.glyph)
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: id.title)
                        .font(.cozy(15.5, weight: .bold))
                        .foregroundStyle(Palette.line)
                    Text(verbatim: id.shortSubtitle)
                        .font(.cozy(11, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                }
                Spacer(minLength: 2)
                Text(verbatim: "★ \(store.miniGameRecords.stars(for: id))")
                    .font(.cozy(12, weight: .semibold))
                    .foregroundStyle(Palette.line)
            }

            Text(verbatim: footer)
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(MiniGameDifficulty.allCases, id: \.rawValue) { difficulty in
                    difficultyButton(id: id, difficulty: difficulty, onPick: onPick)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard(fill: tint.opacity(0.28), radius: 20)
        .padding(.horizontal, 14)
    }

    private func difficultyButton(
        id: MiniGameID,
        difficulty: MiniGameDifficulty,
        onPick: @escaping (MiniGameDifficulty) -> Void
    ) -> some View {
        let record = store.miniGameRecord(for: id, difficulty: difficulty)
        return Button {
            onPick(difficulty)
        } label: {
            VStack(spacing: 3) {
                Text(verbatim: difficulty.title)
                    .font(.cozy(11.5, weight: .semibold))
                    .foregroundStyle(Palette.line)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                StarRow(stars: record?.stars ?? 0)
                Text(verbatim: bestLine(id: id, record: record))
                    .font(.cozy(9.5, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(record?.hasRecord == true ? Palette.cream : Palette.paper.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Palette.lineSoft.opacity(0.4), lineWidth: 1.1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "\(id.title) \(difficulty.title)"))
    }

    private func bestLine(id: MiniGameID, record: MiniGameRecord?) -> String {
        guard let record, record.hasRecord else { return "아직 기록 없음" }
        switch id {
        case .memoryDrawer:
            guard let moves = record.bestMoves else { return "\(record.plays)판" }
            return "최고 \(moves)번"
        case .origamiChallenge:
            guard let chain = record.bestChain else { return "\(record.plays)판" }
            return "최고 \(chain)도안"
        }
    }
}

/// 놀이방에서 지금 고른 놀이.
enum PlayroomBoard: Equatable {
    case memory(MiniGameDifficulty)
    case challenge(MiniGameDifficulty)
}

/// 별 세 개 표시.
struct StarRow: View {
    let stars: Int
    var size: CGFloat = 10

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { index in
                Text(verbatim: index < stars ? "★" : "☆")
                    .font(.system(size: size))
                    .foregroundStyle(index < stars ? Palette.butterDeep : Palette.lineSoft.opacity(0.5))
            }
        }
        .accessibilityLabel(Text(verbatim: "별 \(stars)개"))
    }
}

// MARK: - 기억의 서랍

/// 「다락방 기억의 서랍」. 본편 주머니에 들어왔던 물건이 서랍 칸마다 뒤집혀 있다.
struct MemoryDrawerBoard: View {
    let difficulty: MiniGameDifficulty
    let bestRecord: MiniGameRecord?
    let onFinish: (Int, Double, Int) -> Void
    let onBack: () -> Void

    @State private var game: MemoryDrawerGame
    @State private var startedAt = Date()
    @State private var finishedAt: Date?

    init(
        difficulty: MiniGameDifficulty,
        bestRecord: MiniGameRecord?,
        onFinish: @escaping (Int, Double, Int) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.difficulty = difficulty
        self.bestRecord = bestRecord
        self.onFinish = onFinish
        self.onBack = onBack
        _game = State(initialValue: MemoryDrawerGame(difficulty: difficulty))
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    }

    private var elapsed: Double {
        (finishedAt ?? Date()).timeIntervalSince(startedAt)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    RoundIconButton(systemName: "chevron.left", accessibility: "놀이방으로") {
                        onBack()
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: MiniGameID.memoryDrawer.title)
                            .font(.cozy(16, weight: .bold))
                            .foregroundStyle(Palette.line)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(verbatim: difficulty.title)
                            .font(.cozy(11, weight: .semibold))
                            .foregroundStyle(Palette.lineSoft)
                    }
                    Spacer()
                    Button {
                        restart()
                    } label: {
                        Label("다시 서랍", systemImage: "arrow.counterclockwise")
                            .font(.cozy(11.5, weight: .semibold))
                    }
                    .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                HStack(spacing: 10) {
                    statChip("짝", "\(game.matched.count / 2)/\(game.pairCount)")
                    statChip("움직임", "\(game.moves)")
                    statChip("최고", bestRecord?.bestMoves.map { "\($0)번" } ?? "-")
                }
                .padding(.horizontal, 14)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<game.cardCount, id: \.self) { index in
                        card(index)
                    }
                }
                .padding(.horizontal, 14)

                Text(hintText)
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)

                if game.isFinished {
                    resultCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            startedAt = Date()
            finishedAt = nil
        }
    }

    private var hintText: String {
        if game.isFinished { return "서랍을 모두 닫았다." }
        if game.needsResolve { return "짝이 아니었다. 카드가 다시 뒤집힌다." }
        return "카드를 눌러 뒤집고, 같은 물건 두 장을 찾자."
    }

    private var resultCard: some View {
        VStack(spacing: 8) {
            StarRow(stars: game.stars, size: 20)
            Text(verbatim: "\(game.pairCount)쌍을 \(game.moves)번 만에 맞췄다")
                .font(.cozy(13, weight: .semibold))
                .foregroundStyle(Palette.line)
            Text(verbatim: "완벽한 기록은 \(game.perfectMoves)번 · 지금 \(Int(elapsed))초")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            if let best = bestRecord?.bestMoves {
                Text(verbatim: "최고 기록 \(best)번")
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
            }
            HStack(spacing: 10) {
                Button("한 번 더") { restart() }
                    .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                Button("놀이방으로", action: onBack)
                    .buttonStyle(CozyButtonStyle(fill: Palette.cream))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .paperCard(fill: Palette.butter.opacity(0.3))
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: title)
                .font(.cozy(9.5, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Text(verbatim: value)
                .font(.cozy(14, weight: .semibold))
                .foregroundStyle(Palette.line)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Palette.cream))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Palette.lineSoft.opacity(0.35), lineWidth: 1.1)
        )
    }

    private func card(_ index: Int) -> some View {
        let face = game.face(at: index)
        let isOpen = game.isFaceUp(index) || game.isMatched(index)
        let cardTint = PlayroomTint.color(face?.tint ?? .cloud)

        return Button {
            flip(index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOpen ? cardTint.opacity(0.55) : Palette.cream)
                    .aspectRatio(0.82, contentMode: .fit)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        game.isMatched(index) ? Palette.sage : Palette.lineSoft.opacity(0.45),
                        lineWidth: game.isMatched(index) ? 1.8 : 1.1
                    )
                    .aspectRatio(0.82, contentMode: .fit)

                if isOpen {
                    VStack(spacing: 1) {
                        Text(verbatim: face?.glyph ?? "?")
                            .font(.system(size: 22))
                        Text(verbatim: face?.name ?? "")
                            .font(.cozy(7.5, weight: .semibold))
                            .foregroundStyle(Palette.line)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 2)
                    }
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft.opacity(0.55))
                }
            }
            .opacity(game.isMatched(index) ? 0.75 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.22), value: isOpen)
        .accessibilityLabel(Text(verbatim: "\(index + 1)번 서랍 칸"))
        .accessibilityHint(Text(verbatim: isOpen ? (face?.name ?? "") : "눌러서 연다"))
    }

    private func flip(_ index: Int) {
        guard !game.isFinished else { return }
        let result = game.flip(index)
        switch result {
        case .mismatched:
            let snapshot = game.moves
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                guard game.moves == snapshot else { return }
                var copy = game
                _ = copy.resolveMismatch()
                game = copy
            }
        case .matched:
            if game.isFinished {
                finishedAt = Date()
                onFinish(game.moves, elapsed, game.stars)
            }
        case .ignored, .revealed, .alreadyFaceUp:
            break
        }
    }

    private func restart() {
        game = MemoryDrawerGame(difficulty: difficulty)
        startedAt = Date()
        finishedAt = nil
    }
}

// MARK: - 종이접기 연쇄

/// 「달빛 종이접기 연쇄 챌린지」. 도안을 잠깐 보여 준 뒤, 같은 순서로 접는다.
struct OrigamiChallengeBoard: View {
    let difficulty: MiniGameDifficulty
    let bestRecord: MiniGameRecord?
    let onFinish: (Int, Double, Int) -> Void
    let onBack: () -> Void

    @State private var challenge: OrigamiChallenge
    @State private var startedAt = Date()
    @State private var finishedAt: Date?
    /// 도안을 외우는 동안 true. 이때는 접기 단추가 잠긴다.
    @State private var memorizing = true
    @State private var flash: String?

    init(
        difficulty: MiniGameDifficulty,
        bestRecord: MiniGameRecord?,
        onFinish: @escaping (Int, Double, Int) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.difficulty = difficulty
        self.bestRecord = bestRecord
        self.onFinish = onFinish
        self.onBack = onBack
        _challenge = State(initialValue: OrigamiChallenge(difficulty: difficulty))
    }

    private var elapsed: Double {
        (finishedAt ?? Date()).timeIntervalSince(startedAt)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                statusRow
                designCard
                placedRow
                foldButtons
                if let flash {
                    Text(verbatim: flash)
                        .font(.cozy(11.5, weight: .semibold))
                        .foregroundStyle(Palette.roseDeep)
                        .transition(.opacity)
                }
                Text("도안은 잠깐만 보인다. 순서를 기억해 접자.")
                    .font(.cozy(10.5, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft.opacity(0.85))
                    .padding(.bottom, 14)

                if challenge.isOver {
                    resultCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            startedAt = Date()
            finishedAt = nil
            beginMemorize()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundIconButton(systemName: "chevron.left", accessibility: "놀이방으로") {
                onBack()
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: MiniGameID.origamiChallenge.title)
                    .font(.cozy(15.5, weight: .bold))
                    .foregroundStyle(Palette.line)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(verbatim: difficulty.title)
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
            }
            Spacer()
            Button {
                restart()
            } label: {
                Label("처음부터", systemImage: "arrow.counterclockwise")
                    .font(.cozy(11.5, weight: .semibold))
            }
            .buttonStyle(CozyButtonStyle(fill: Palette.cream))
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            chip("완성", "\(challenge.completed)/\(challenge.chainLength)")
            chip("실수", "\(challenge.mistakesLeft)/\(difficulty.mistakeBudget)")
            chip("최고", bestRecord?.bestChain.map { "\($0)도안" } ?? "-")
        }
        .padding(.horizontal, 14)
    }

    private var designCard: some View {
        VStack(spacing: 8) {
            if let design = challenge.currentDesign {
                Text(verbatim: memorizing ? "이 순서로 접는다" : "지금 접을 차례")
                    .font(.cozy(10.5, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                HStack(spacing: 8) {
                    Text(verbatim: design.glyph)
                        .font(.system(size: 26))
                    Text(verbatim: design.name)
                        .font(.cozy(18, weight: .bold))
                        .foregroundStyle(Palette.line)
                }
                HStack(spacing: 6) {
                    ForEach(0..<design.steps.count, id: \.self) { index in
                        let shown = memorizing || index < challenge.placed.count
                        VStack(spacing: 2) {
                            Text(verbatim: shown ? design.steps[index].symbol : "?")
                                .font(.system(size: 19))
                                .frame(width: 42, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(shown ? Palette.butter.opacity(0.5) : Palette.paper)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Palette.lineSoft.opacity(0.4), lineWidth: 1.1)
                                )
                            Text(verbatim: index < challenge.placed.count ? "접음" : "")
                                .font(.cozy(8.5, weight: .semibold))
                                .foregroundStyle(Palette.lineSoft)
                        }
                    }
                }
            } else {
                Text("모든 도안을 접었다")
                    .font(.cozy(15, weight: .bold))
                    .foregroundStyle(Palette.line)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .paperCard(fill: Palette.butter.opacity(0.26), radius: 20)
        .padding(.horizontal, 14)
    }

    private var placedRow: some View {
        HStack(spacing: 6) {
            Text(verbatim: "🪷")
                .font(.system(size: 15))
            Text(challenge.remainingSteps.isEmpty
                 ? "이 도안은 다 접었다"
                 : "남은 접기 \(challenge.remainingSteps.count)번")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Spacer()
        }
        .padding(.horizontal, 18)
    }

    private var foldButtons: some View {
        HStack(spacing: 8) {
            ForEach(OrigamiFold.allCases, id: \.rawValue) { fold in
                Button {
                    apply(fold)
                } label: {
                    VStack(spacing: 3) {
                        Text(verbatim: fold.symbol)
                            .font(.system(size: 20))
                            .frame(width: 54, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Palette.cream)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1)
                            )
                        Text(verbatim: fold.label)
                            .font(.cozy(9, weight: .semibold))
                            .foregroundStyle(Palette.line)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(.plain)
                .disabled(memorizing || challenge.isOver)
                .opacity(memorizing || challenge.isOver ? 0.45 : 1)
                .accessibilityLabel(Text(verbatim: fold.label))
            }
        }
        .padding(.horizontal, 14)
    }

    private var resultCard: some View {
        VStack(spacing: 8) {
            StarRow(stars: challenge.stars, size: 20)
            Text(verbatim: "도안 \(challenge.completed)개를 완성했다")
                .font(.cozy(13, weight: .semibold))
                .foregroundStyle(Palette.line)
            Text(verbatim: "\(Int(elapsed))초 · 남은 실수 \(challenge.mistakesLeft)번")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            if let best = bestRecord?.bestChain {
                Text(verbatim: "최고 기록 \(best)도안")
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
            }
            HStack(spacing: 10) {
                Button("한 번 더") { restart() }
                    .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                Button("놀이방으로", action: onBack)
                    .buttonStyle(CozyButtonStyle(fill: Palette.cream))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .paperCard(fill: Palette.sage.opacity(0.25))
    }

    private func chip(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: title)
                .font(.cozy(9.5, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Text(verbatim: value)
                .font(.cozy(14, weight: .semibold))
                .foregroundStyle(Palette.line)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Palette.cream))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Palette.lineSoft.opacity(0.35), lineWidth: 1.1)
        )
    }

    private func beginMemorize() {
        memorizing = true
        Task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            memorizing = false
        }
    }

    private func apply(_ fold: OrigamiFold) {
        guard !memorizing, !challenge.isOver else { return }
        let result = challenge.fold(fold)
        switch result {
        case .accepted:
            flash = nil
        case .unfolded(let mistakesLeft):
            flash = "접힘이 풀렸다. 이 도안은 처음부터. 남은 실수 \(mistakesLeft)번."
        case .designCompleted(_, _):
            flash = "도안 완성! 다음 도안을 보자."
            beginMemorize()
        case .finished:
            finishedAt = Date()
            flash = nil
            onFinish(challenge.completed, elapsed, challenge.stars)
        case .ignored:
            break
        }
    }

    private func restart() {
        challenge = OrigamiChallenge(difficulty: difficulty)
        startedAt = Date()
        finishedAt = nil
        flash = nil
        beginMemorize()
    }
}

/// Core가 이름으로만 들고 있는 색 토큰을 화면 색으로 옮긴다.
enum PlayroomTint {
    static func color(_ token: MiniGameTint) -> Color {
        switch token {
        case .butter: return Palette.butter
        case .rose: return Palette.rose
        case .sage: return Palette.sage
        case .dusk: return Palette.dusk
        case .mauve: return Palette.mauve
        case .wood: return Palette.wood
        case .candle: return Palette.candle
        case .cloud: return Palette.cloud
        }
    }
}
