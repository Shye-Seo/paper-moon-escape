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
                }
                .padding(.horizontal, 40)

                Text("모모 & 피코의 종이 모험 · 세 장면")
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

/// 스테이지 선택. 지난 장면은 다시 골라 들어갈 수 있다.
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
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(store.stageList) { stage in
                            stageCard(stage)
                        }
                        Text("앞 장면을 깨면 다음 장면이 열린다.")
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

        return Button {
            if unlocked {
                store.enter(stage.id)
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
                    Text(stage.subtitle)
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
            .opacity(unlocked ? 1 : 0.75)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(Text(verbatim: stage.title))
        .accessibilityHint(Text(verbatim: unlocked ? "이 장면으로 들어간다" : "아직 잠겨 있다"))
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

            VStack(spacing: 14) {
                Spacer(minLength: 10)

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
                        .frame(width: 260, height: 260)

                    MoonView(fill: Palette.cream)
                        .frame(width: 150, height: 150)

                    CharacterAvatar(character: .pico)
                        .offset(x: 52, y: 44)

                    CharacterAvatar(character: .momo)
                        .offset(x: -54, y: 40)
                }

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
                }
                .padding(16)
                .frame(maxWidth: 330)
                .paperCard(fill: Palette.cream)

                Spacer(minLength: 6)

                VStack(spacing: 10) {
                    Button("한 번 더 모험하기", action: store.playAgain)
                        .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                    Button("타이틀로", action: store.backToTitle)
                        .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                }
                .padding(.bottom, 18)
            }
        }
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

/// 앱의 최상위 화면. 지금 단계에 맞는 화면 하나만 보여 준다.
struct RootView: View {
    @StateObject private var store = GameStore()

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
            }
        }
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.3), value: store.phase)
    }
}
