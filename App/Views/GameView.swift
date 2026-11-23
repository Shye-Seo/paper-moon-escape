import SwiftUI
import PaperMoonCore

/// 게임 본 화면: 씬 + 지점 + 주인공 + 인벤토리 + 힌트/퍼즐 오버레이.
/// 세로가 길면 여유 있게, 가로처럼 높이가 낮으면 compact 모드로 씬을 줄인다.
struct GameView: View {
    @ObservedObject var store: GameStore
    @State private var bounce = false
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 540

            ZStack {
                PaperBackground()

                VStack(spacing: 0) {
                    topBar(compact: compact)
                    sceneArea(compact: compact)
                    narrationArea(compact: compact)
                    InventoryBarView(store: store, compact: compact)
                }

                if let hint = store.hint {
                    HintOverlay(card: hint, onMore: store.askMoreHint, onClose: store.closeHint)
                        .transition(.opacity)
                }

                if let puzzle = store.puzzle {
                    PuzzleOverlay(
                        puzzle: puzzle,
                        misses: store.puzzleMisses,
                        onSubmit: store.submitPuzzle,
                        onClose: store.closePuzzle
                    )
                    .transition(.opacity)
                }

                if let flash = store.stageFlash, let cleared = store.stageInfo(for: flash) {
                    StageFlashView(stage: cleared)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: store.hint?.id)
        .animation(.easeInOut(duration: 0.28), value: store.puzzle?.id)
        .animation(.easeInOut(duration: 0.28), value: store.stageFlash)
        .animation(.easeInOut(duration: 0.25), value: store.bubble?.id)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bounce = true
                pulse = true
            }
        }
    }

    // MARK: 상단 바

    private func topBar(compact: Bool) -> some View {
        HStack(spacing: 10) {
            RoundIconButton(systemName: "house.fill", accessibility: "타이틀 화면으로") {
                store.backToTitle()
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(store.stage?.title ?? "종이달 다락방")
                    .font(.cartoon(compact ? 12.5 : 14, weight: .heavy))
                    .lineLimit(1)
                Text(store.room.title + " · " + store.room.caption)
                    .font(.cartoon(compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            RoundIconButton(systemName: "lightbulb.fill", fill: Palette.mustard, accessibility: "힌트 보기") {
                store.requestHint()
            }
            RoundIconButton(systemName: "arrow.counterclockwise", accessibility: "스테이지 처음부터") {
                store.resetStage()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, compact ? 2 : 6)
        .padding(.bottom, compact ? 4 : 8)
    }

    // MARK: 씬

    private func sceneArea(compact: Bool) -> some View {
        GeometryReader { geo in
            ZStack {
                RoomSceneView(room: store.room)

                ForEach(store.hotspots) { hotspot in
                    hotspotButton(hotspot, in: geo.size)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    PaperKid(kind: .momo)
                        .offset(y: bounce ? -2 : 0)
                    PaperKid(kind: .pico)
                        .offset(y: bounce ? 0 : -2)
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.bottom, 2)
                .allowsHitTesting(false)

                HStack {
                    RoundIconButton(systemName: "chevron.left", accessibility: "왼쪽 방으로") {
                        store.moveLeft()
                    }
                    Spacer()
                    RoundIconButton(systemName: "chevron.right", accessibility: "오른쪽 방으로") {
                        store.moveRight()
                    }
                }
                .padding(.horizontal, 10)

                if let reaction = store.reaction {
                    VStack {
                        Spacer()
                        HStack {
                            ReactionBubble(reaction: reaction)
                                .padding(.leading, 24)
                                .padding(.bottom, 84)
                            Spacer()
                        }
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Palette.ink, lineWidth: 3)
            )
            .shadow(color: Palette.ink.opacity(0.16), radius: 0, x: 5, y: 6)
            .padding(.horizontal, 10)
        }
        .frame(minHeight: compact ? 160 : 300)
    }

    private func hotspotButton(_ hotspot: Hotspot, in size: CGSize) -> some View {
        Button {
            store.tap(hotspot)
        } label: {
            ZStack {
                Circle()
                    .stroke(Palette.mustard, lineWidth: 3)
                    .frame(width: 54, height: 54)
                    .scaleEffect(pulse ? 1.22 : 1.0)
                    .opacity(pulse ? 0.0 : 0.8)

                Circle()
                    .fill(Palette.cream.opacity(0.94))
                    .frame(width: 50, height: 50)
                Circle()
                    .stroke(Palette.ink, lineWidth: 3)
                    .frame(width: 50, height: 50)

                Text(verbatim: hotspot.glyph)
                    .font(.system(size: 24))
            }
            .shadow(color: Palette.ink.opacity(0.22), radius: 0, x: 2, y: 3)
        }
        .buttonStyle(.plain)
        .position(
            x: size.width * CGFloat(hotspot.position.x),
            y: size.height * CGFloat(hotspot.position.y)
        )
        .accessibilityLabel(Text(verbatim: hotspot.label))
    }

    // MARK: 대사 영역

    private func narrationArea(compact: Bool) -> some View {
        ZStack {
            if let bubble = store.bubble {
                NarrationBubble(line: bubble.line)
                    .padding(.horizontal, 14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text(store.room.caption)
                    .font(.cartoon(compact ? 11 : 12, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft.opacity(0.8))
            }
        }
        .frame(height: compact ? 68 : 92)
        .frame(maxWidth: .infinity)
    }
}

/// 말풍선 한 줄.
struct NarrationBubble: View {
    let line: Line

    private var speaker: String? {
        switch line {
        case .narration:
            return nil
        case .momo:
            return "모모"
        case .pico:
            return "피코"
        case .creature(let name, _):
            return name
        }
    }

    private var avatar: CharacterID? {
        switch line {
        case .narration:
            return nil
        case .momo:
            return .momo
        case .pico:
            return .pico
        case .creature(let name, _):
            return name.contains("개구리") ? .frog : (name.contains("부엉이") ? .owl : .keeper)
        }
    }

    private var tint: Color {
        switch line {
        case .narration:
            return Palette.cream
        case .momo:
            return Palette.coral.opacity(0.22)
        case .pico:
            return Palette.cobalt.opacity(0.18)
        case .creature:
            return Palette.mint.opacity(0.24)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let avatar {
                CharacterAvatar(character: avatar)
            }
            VStack(alignment: .leading, spacing: 3) {
                if let speaker {
                    Text(verbatim: speaker)
                        .font(.cartoon(11, weight: .heavy))
                        .foregroundStyle(Palette.inkSoft)
                }
                Text(line.text)
                    .font(.cartoon(13.5, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(11)
        .paperCard(fill: tint, radius: 18)
    }
}

/// 스테이지 클리어 배너.
struct StageFlashView: View {
    let stage: Stage

    var body: some View {
        VStack(spacing: 6) {
            Text("스테이지 클리어")
                .font(.cartoon(13, weight: .heavy))
                .foregroundStyle(Palette.inkSoft)
            Text(stage.title)
                .font(.cartoon(24, weight: .heavy))
                .foregroundStyle(Palette.ink)
            Text("다음 장면으로")
                .font(.cartoon(12, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 22)
        .paperCard(fill: Palette.mustard, radius: 26)
        .rotationEffect(.degrees(-2))
    }
}
