import SwiftUI
import PaperMoonCore

/// 타이틀 화면. 종이달, 빗방울, 그리고 세 개의 버튼.
struct TitleView: View {
    @ObservedObject var store: GameStore
    @State private var float = false

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 16) {
                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Palette.candleGlow.opacity(0.42),
                                    Palette.candleGlow.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 12,
                                endRadius: 155
                            )
                        )
                        .frame(width: 310, height: 310)

                    MoonView()
                        .frame(width: 182, height: 182)
                        .rotationEffect(.degrees(-7))

                    HStack(spacing: 13) {
                        ForEach(0..<4, id: \.self) { _ in
                            Capsule()
                                .fill(Palette.dusk.opacity(0.30))
                                .frame(width: 2, height: 16)
                                .rotationEffect(.degrees(14))
                        }
                    }
                    .offset(x: -84, y: 64)

                    CharacterAvatar(character: .pico)
                        .scaleEffect(1.05)
                        .offset(x: 64, y: float ? 64 : 60)

                    CharacterAvatar(character: .momo)
                        .scaleEffect(0.9)
                        .offset(x: 98, y: float ? 76 : 72)
                }
                .frame(height: 200)

                VStack(spacing: 5) {
                    Text("종이달 다락방 탈출")
                        .font(.cozy(29, weight: .bold))
                        .foregroundStyle(Palette.line)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("Paper Moon Escape")
                        .font(.cozy(12.5, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                    Text("비 오는 토요일, 모모와 고양이 피코는 종이로 접힌 달 속으로 들어갔다.")
                        .font(.cozy(12, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 2)
                }

                Spacer(minLength: 8)

                VStack(spacing: 10) {
                    if store.hasSave {
                        Button("이어하기", action: store.continueGame)
                            .buttonStyle(CozyButtonStyle(fill: Palette.dusk, textColor: Palette.cream))
                    }
                    Button("새로 시작", action: store.startNewGame)
                        .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                    Button("스테이지 선택", action: store.openStageSelect)
                        .buttonStyle(CozyButtonStyle(fill: Palette.cream))

                    if store.playroomUnlocked {
                        Button {
                            store.openPlayroom()
                        } label: {
                            Label("다락방 놀이방", systemImage: "sparkles")
                                .font(.cozy(14, weight: .semibold))
                        }
                        .buttonStyle(CozyButtonStyle(fill: Palette.sage.opacity(0.55)))
                        .accessibilityHint(Text(verbatim: "엔딩 뒤에 열린 기억의 서랍과 종이접기 연쇄"))
                    }

                    HStack(spacing: 10) {
                        Button {
                            store.openScrapbook()
                        } label: {
                            Label("스크랩북 \(store.craneCount)/\(store.craneGoal)", systemImage: "book.closed.fill")
                                .font(.cozy(13, weight: .semibold))
                        }
                        .buttonStyle(CozyButtonStyle(fill: Palette.cream))

                        Button {
                            store.openShop()
                        } label: {
                            Label("상점", systemImage: "bag.fill")
                                .font(.cozy(13, weight: .semibold))
                        }
                        .buttonStyle(CozyButtonStyle(fill: Palette.paper))
                    }
                }
                .padding(.horizontal, 30)

                Text("모모 & 피코의 종이 모험 · 본편 세 장면 + 보너스 지하실")
                    .font(.cozy(10, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft.opacity(0.75))
                    .padding(.bottom, 14)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                float = true
            }
        }
    }
}

/// 스테이지 선택. 지난 장면은 다시 골라 들어갈 수 있고, 잠긴 장면은 상점으로 안내한다.
struct StageSelectView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    RoundIconButton(systemName: "chevron.left", accessibility: "뒤로") {
                        store.backToTitle()
                    }
                    Text("스테이지 선택")
                        .font(.cozy(18, weight: .semibold))
                    Spacer()
                    Button {
                        store.openShop()
                    } label: {
                        Label("상점", systemImage: "bag.fill")
                            .font(.cozy(12, weight: .semibold))
                    }
                    .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(store.stageList) { stage in
                            stageCard(stage)
                        }

                        if let bonus = store.bonusStage {
                            bonusCard(bonus)
                        }

                        Text("1장면은 무료다. 구매한 장면은 앞 장면을 깨면 열린다.")
                            .font(.cozy(11, weight: .semibold))
                            .foregroundStyle(Palette.lineSoft.opacity(0.8))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func stageCard(_ stage: Stage) -> some View {
        let unlocked = store.isStageUnlocked(stage.id)
        let isCleared = store.clearedStages.contains(stage.id)
        let lockText = store.stageLockText(stage.id)

        return Button {
            if unlocked {
                store.enter(stage.id)
            } else {
                store.openShop(reason: lockText)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Palette.stageTint(stage.id))
                        .frame(width: 46, height: 46)
                    Circle()
                        .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1)
                        .frame(width: 46, height: 46)
                    Text("\(stage.number)")
                        .font(.cozy(20, weight: .semibold))
                        .foregroundStyle(Palette.line)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.title)
                        .font(.cozy(16, weight: .bold))
                        .foregroundStyle(Palette.line)
                        .multilineTextAlignment(.leading)
                    Text(unlocked ? stage.subtitle : (lockText ?? stage.subtitle))
                        .font(.cozy(11.5, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Text(verbatim: isCleared ? "✔" : (unlocked ? "▶" : "🔒"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.line)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard(fill: unlocked ? Palette.cream : Palette.cloud, radius: 20)
            .opacity(unlocked ? 1 : 0.8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: stage.title))
        .accessibilityHint(Text(verbatim: unlocked ? "이 장면으로 들어간다" : "상점에서 잠금을 해제할 수 있다"))
    }

    private func bonusCard(_ stage: Stage) -> some View {
        let unlocked = store.isStageUnlocked(stage.id)
        let isCleared = store.clearedStages.contains(stage.id)
        let lockText = store.stageLockText(stage.id)

        return Button {
            if unlocked {
                store.enterBonusChapter()
            } else {
                store.openShop(reason: lockText)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(verbatim: "🗝")
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("보너스 · " + stage.title)
                            .font(.cozy(15.5, weight: .bold))
                            .foregroundStyle(Palette.line)
                        Text(stage.subtitle)
                            .font(.cozy(11, weight: .semibold))
                            .foregroundStyle(Palette.lineSoft)
                    }
                    Spacer(minLength: 4)
                    Text(verbatim: isCleared ? "✔" : (unlocked ? "▶" : "🔒"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Palette.line)
                }
                Text(unlocked
                     ? "지하실 세 방과 새 퍼즐, 지하실만의 엔딩이 기다린다."
                     : (lockText ?? StoreProduct.cellarChapter.summary))
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard(fill: unlocked ? Palette.butter.opacity(0.32) : Palette.paper, radius: 20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: stage.title))
    }
}

/// 엔딩: 플레이 요약과 함께 다락방으로.
struct EndingView: View {
    @ObservedObject var store: GameStore

    private var summary: GameSummary? {
        store.ending
    }

    private func minutes(_ seconds: Double) -> String {
        let total = Int(seconds)
        return "\(total / 60)분 \(total % 60)초"
    }

    var body: some View {
        ZStack {
            PaperBackground(tint: Color(red: 0.99, green: 0.93, blue: 0.80))

            ScrollView {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Palette.candleGlow.opacity(0.38),
                                        Palette.candleGlow.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)

                        MoonView(fill: Palette.cream)
                            .frame(width: 150, height: 150)

                        CharacterAvatar(character: .pico)
                            .offset(x: 52, y: 44)

                        CharacterAvatar(character: .momo)
                            .offset(x: -54, y: 40)
                    }
                    .padding(.top, 8)

                    Text("탈출 성공!")
                        .font(.cozy(30, weight: .bold))
                        .foregroundStyle(Palette.line)

                    Text("종이달이 온전해지고, 다락방 창으로 종이 계단이 내려왔다.")
                        .font(.cozy(12.5, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    VStack(spacing: 8) {
                        summaryRow("걸린 시간", summary.map { minutes($0.seconds) } ?? "-")
                        summaryRow("사용한 힌트", summary.map { "\($0.hintsUsed)번" } ?? "-")
                        summaryRow("깬 스테이지", summary.map { "\($0.clearedStages) / 3" } ?? "-")
                        summaryRow("만든 물건", summary.map { "\($0.craftedCount)개" } ?? "-")
                        summaryRow("모은 종이학", "\(store.craneCount) / \(store.craneGoal)")
                    }
                    .padding(16)
                    .frame(maxWidth: 340)
                    .paperCard(fill: Palette.cream)

                    if store.canOpenSecretDrawer {
                        drawerCard
                    }

                    VStack(spacing: 10) {
                        Button("스크랩북 열기", action: store.openScrapbook)
                            .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                        Button {
                            store.openPlayroom()
                        } label: {
                            Label("다락방 놀이방에서 한 판 더", systemImage: "sparkles")
                                .font(.cozy(14, weight: .semibold))
                        }
                        .buttonStyle(CozyButtonStyle(fill: Palette.sage.opacity(0.55)))
                        if let bonus = store.bonusStage {
                            Button(store.isStageUnlocked(.cellar) ? "보너스 지하실로" : "보너스 지하실 · \(StoreProduct.cellarChapter.priceText)") {
                                if store.isStageUnlocked(.cellar) {
                                    store.enterBonusChapter()
                                } else {
                                    store.openShop(reason: store.stageLockText(.cellar))
                                }
                            }
                            .buttonStyle(CozyButtonStyle(fill: store.isStageUnlocked(.cellar) ? Palette.dusk : Palette.paper,
                                                         textColor: store.isStageUnlocked(.cellar) ? Palette.cream : Palette.line))
                            .accessibilityHint(Text(verbatim: bonus.subtitle))
                        }
                        Button("한 번 더 모험하기", action: store.playAgain)
                            .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                        Button("타이틀로", action: store.backToTitle)
                            .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                    }
                    .padding(.bottom, 22)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var drawerCard: some View {
        VStack(spacing: 8) {
            Text(verbatim: "🗄")
                .font(.system(size: 26))
            Text(store.hasOpenedSecretDrawer ? "비밀 서랍은 열린 채다" : "열두 마리 종이학이 서랍을 열었다")
                .font(.cozy(14, weight: .bold))
                .foregroundStyle(Palette.line)
            Text(store.hasOpenedSecretDrawer
                 ? "종이학 모빌이 창가에서 천천히 돌고 있다."
                 : "다락방 벽판 안쪽에서 작은 선물이 기다린다.")
                .font(.cozy(11, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
                .multilineTextAlignment(.center)
            Button(store.hasOpenedSecretDrawer ? "다시 보기" : "비밀 서랍 열기") {
                store.openSecretDrawer()
            }
            .buttonStyle(CozyButtonStyle(fill: Palette.butter))
        }
        .padding(16)
        .frame(maxWidth: 340)
        .paperCard(fill: Palette.butter.opacity(0.3))
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: title)
                .font(.cozy(13, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Spacer()
            Text(verbatim: value)
                .font(.cozy(14, weight: .semibold))
                .foregroundStyle(Palette.line)
        }
    }
}

/// 보너스 지하실만의 엔딩.
struct BonusEndingView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        ZStack {
            PaperBackground(tint: Color(red: 0.93, green: 0.90, blue: 0.85))

            ScrollView {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Palette.candleGlow.opacity(0.28))
                            .frame(width: 210, height: 210)
                        Text(verbatim: "🗝")
                            .font(.system(size: 86))
                    }
                    .padding(.top, 18)

                    Text("지하실의 끝")
                        .font(.cozy(27, weight: .bold))
                        .foregroundStyle(Palette.line)

                    Text(store.bonusEndingStage?.title ?? "비밀 다락방 지하실")
                        .font(.cozy(13, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)

                    Text(store.bonusEndingStage?.closing ?? "")
                        .font(.cozy(13, weight: .semibold))
                        .foregroundStyle(Palette.line)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: 340)
                        .paperCard(fill: Palette.cream)

                    VStack(spacing: 8) {
                        summaryRow("걸린 시간", minutes(store.bonusEndingSummary?.seconds ?? 0))
                        summaryRow("사용한 힌트", "\(store.bonusEndingSummary?.hintsUsed ?? 0)번")
                        summaryRow("모은 종이학", "\(store.craneCount) / \(store.craneGoal)")
                    }
                    .padding(16)
                    .frame(maxWidth: 340)
                    .paperCard(fill: Palette.cream)

                    VStack(spacing: 10) {
                        Button("스크랩북 열기", action: store.openScrapbook)
                            .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                        Button {
                            store.openPlayroom()
                        } label: {
                            Label("다락방 놀이방", systemImage: "sparkles")
                                .font(.cozy(14, weight: .semibold))
                        }
                        .buttonStyle(CozyButtonStyle(fill: Palette.sage.opacity(0.55)))
                        Button("본편 엔딩 다시 보기", action: store.openStageSelect)
                            .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                        Button("타이틀로", action: store.backToTitle)
                            .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                    }
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func minutes(_ seconds: Double) -> String {
        let total = Int(seconds)
        return "\(total / 60)분 \(total % 60)초"
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: title)
                .font(.cozy(13, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Spacer()
            Text(verbatim: value)
                .font(.cozy(14, weight: .semibold))
                .foregroundStyle(Palette.line)
        }
    }
}

/// 종이학 12마리를 모았을 때 열리는 다락방 비밀 서랍.
struct SecretGiftOverlay: View {
    let gift: SecretGift
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Palette.line.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 10) {
                Text(verbatim: gift.glyph)
                    .font(.system(size: 34))
                Text(verbatim: gift.title)
                    .font(.cozy(18, weight: .bold))
                    .foregroundStyle(Palette.line)
                ForEach(gift.lines, id: \.self) { line in
                    Text(verbatim: line)
                        .font(.cozy(12.5, weight: .semibold))
                        .foregroundStyle(Palette.line)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 6) {
                    Text(verbatim: "🎐")
                    Text(verbatim: gift.keepsake)
                        .font(.cozy(12, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)

                Button("서랍 닫기", action: onClose)
                    .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: 360)
            .paperCard(fill: Palette.cream)
            .padding(.horizontal, 22)
        }
    }
}

/// 앱의 최상위 화면. 지금 단계에 맞는 화면 하나만 보여 주고, 상점·스크랩북은 시트로 덮는다.
struct RootView: View {
    @StateObject private var store = GameStore()
    @StateObject private var shop = StoreManager()

    private var shopBinding: Binding<Bool> {
        Binding(
            get: { store.showingShop },
            set: { showing in
                if !showing {
                    store.closeShop()
                }
            }
        )
    }

    private var scrapbookBinding: Binding<Bool> {
        Binding(
            get: { store.showingScrapbook },
            set: { showing in
                if !showing {
                    store.closeScrapbook()
                }
            }
        )
    }

    var body: some View {
        ZStack {
            switch store.phase {
            case .title:
                TitleView(store: store)
            case .stageSelect:
                StageSelectView(store: store)
            case .playing:
                GameView(store: store)
            case .ending:
                EndingView(store: store)
            case .bonusEnding:
                BonusEndingView(store: store)
            case .playroom:
                PlayroomView(store: store)
            }

            if let gift = store.secretGift {
                SecretGiftOverlay(gift: gift, onClose: store.closeSecretGift)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.3), value: store.phase)
        .animation(.easeInOut(duration: 0.25), value: store.secretGift?.title)
        .sheet(isPresented: shopBinding) {
            ShopView(store: store, shop: shop, onClose: store.closeShop)
                .presentationDetents([.large])
        }
        .sheet(isPresented: scrapbookBinding) {
            ScrapbookView(store: store, onClose: store.closeScrapbook)
                .presentationDetents([.large])
        }
        .task {
            shop.start()
            store.applyEntitlements(shop.entitlements)
        }
        .onChange(of: shop.entitlements) { _, value in
            store.applyEntitlements(value)
        }
    }
}
