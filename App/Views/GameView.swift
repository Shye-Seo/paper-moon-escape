import SwiftUI
import PaperMoonCore

/// 게임 본 화면: 씬 + 지점 + 주인공 + 인벤토리 + 힌트/퍼즐 오버레이.
/// 세로가 길면 여유 있게, 가로처럼 높이가 낮으면 compact 모드로 씬을 줄인다.
struct GameView: View {
    @ObservedObject var store: GameStore
    @StateObject private var motion = MotionManager()
    @State private var bounce = false
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 560

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
                        folded: store.foldSteps,
                        motion: motion,
                        onSubmit: store.submitPuzzle,
                        onFold: store.fold,
                        onResetFold: store.resetFolds,
                        onClose: store.closePuzzle
                    )
                    .transition(.opacity)
                }

                if let dust = store.dust {
                    DustWipeOverlay(
                        session: dust,
                        motion: motion,
                        onWipe: store.wipeDust,
                        onShake: store.shakeDust,
                        onSweep: store.sweepDustByHand,
                        onClose: store.closeDust
                    )
                    .transition(.opacity)
                }

                if let flash = store.stageFlash, let cleared = store.stageInfo(for: flash) {
                    StageFlashView(stage: cleared)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .allowsHitTesting(false)
                }

                if let note = store.dustFlash {
                    VStack {
                        Text(verbatim: note)
                            .font(.cozy(12, weight: .semibold))
                            .foregroundStyle(Palette.line)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .paperCard(fill: Palette.butter, radius: 16)
                        Spacer()
                    }
                    .padding(.top, compact ? 54 : 74)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                if let note = store.searchFlash {
                    VStack {
                        Spacer()
                        Text(verbatim: note)
                            .font(.cozy(11.5, weight: .semibold))
                            .foregroundStyle(Palette.line)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .paperCard(fill: Palette.cloud, radius: 15)
                            .padding(.bottom, compact ? 96 : 118)
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: store.hint?.id)
        .animation(.easeInOut(duration: 0.28), value: store.puzzle?.id)
        .animation(.easeInOut(duration: 0.28), value: store.stageFlash)
        .animation(.easeInOut(duration: 0.25), value: store.bubble?.id)
        .animation(.easeInOut(duration: 0.25), value: store.dust?.id)
        .animation(.easeInOut(duration: 0.25), value: store.dustFlash)
        .animation(.easeInOut(duration: 0.25), value: store.searchFlash)
        .onAppear {
            motion.start()
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bounce = true
                pulse = true
            }
        }
        .onDisappear {
            motion.stop()
        }
    }

    // MARK: 상단 바

    private func topBar(compact: Bool) -> some View {
        HStack(spacing: 8) {
            RoundIconButton(systemName: "house.fill", accessibility: "타이틀 화면으로") {
                store.backToTitle()
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(store.stage?.title ?? "종이달 다락방")
                    .font(.cozy(compact ? 12.5 : 14, weight: .semibold))
                    .lineLimit(1)
                Text(store.room.title + " · " + store.room.caption)
                    .font(.cozy(compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            RoundIconButton(systemName: "book.closed.fill", fill: Palette.cream, accessibility: "스크랩북") {
                store.openScrapbook()
            }
            RoundIconButton(systemName: "lightbulb.fill", fill: Palette.butter, accessibility: "힌트 보기") {
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

                ForEach(store.collectibles) { collectible in
                    collectibleButton(collectible, in: geo.size)
                }

                ForEach(store.searches) { spot in
                    searchButton(spot, in: geo.size)
                }

                ForEach(store.hotspots) { hotspot in
                    hotspotButton(hotspot, in: geo.size)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    if store.character == .momo {
                        PaperKid(kind: .momo)
                            .offset(y: bounce ? -2 : 0)
                        PaperKid(kind: .pico)
                            .scaleEffect(0.82)
                            .opacity(0.55)
                            .offset(y: bounce ? 0 : -2)
                    } else {
                        PaperKid(kind: .momo)
                            .scaleEffect(0.82)
                            .opacity(0.55)
                            .offset(y: bounce ? -2 : 0)
                        PaperKid(kind: .pico)
                            .offset(y: bounce ? 0 : -2)
                    }
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.bottom, 2)
                .allowsHitTesting(false)

                VStack {
                    HStack {
                        characterSwitch
                        Spacer()
                        craneBadge
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)

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
                    .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.2)
            )
            .shadow(color: Palette.shadow, radius: 10, x: 0, y: 4)
            .padding(.horizontal, 10)
        }
        .frame(minHeight: compact ? 170 : 300)
    }

    /// 모모 ↔ 피코 전환 스위치. 지금 조종 중인 캐릭터가 진하게 보인다.
    private var characterSwitch: some View {
        HStack(spacing: 4) {
            ForEach(PlayableCharacter.allCases, id: \.rawValue) { character in
                let active = store.character == character
                Button {
                    if !active {
                        store.toggleCharacter()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(verbatim: character.glyph)
                            .font(.system(size: 13))
                        Text(verbatim: character.shortName)
                            .font(.cozy(10.5, weight: .semibold))
                            .foregroundStyle(Palette.line)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(active ? Palette.butter : Palette.cream.opacity(0.85)))
                    .overlay(
                        Capsule()
                            .stroke(Palette.lineSoft.opacity(active ? 0.8 : 0.35), lineWidth: 1.1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(character.displayName)으로 조종"))
                .accessibilityHint(Text(verbatim: character.trait))
            }
        }
        .padding(3)
        .background(Capsule().fill(Palette.paper.opacity(0.75)))
    }

    private var craneBadge: some View {
        Button {
            store.openScrapbook()
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: "🕊")
                    .font(.system(size: 12))
                Text(verbatim: "\(store.craneCount)/\(store.craneGoal)")
                    .font(.cozy(10.5, weight: .semibold))
                    .foregroundStyle(Palette.line)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(Palette.paper.opacity(0.8)))
            .overlay(Capsule().stroke(Palette.lineSoft.opacity(0.35), lineWidth: 1.1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "스크랩북에 모은 종이학 \(store.craneCount)마리"))
    }

    private func hotspotButton(_ hotspot: Hotspot, in size: CGSize) -> some View {
        let needsOtherCharacter = hotspot.requiredCharacter != nil
            && hotspot.requiredCharacter != store.character

        return Button {
            store.tap(hotspot)
        } label: {
            ZStack {
                Circle()
                    .stroke(needsOtherCharacter ? Palette.lineSoft.opacity(0.4) : Palette.butter, lineWidth: 1.3)
                    .frame(width: 54, height: 54)
                    .scaleEffect(pulse && !needsOtherCharacter ? 1.22 : 1.0)
                    .opacity(pulse && !needsOtherCharacter ? 0.0 : 0.8)

                Circle()
                    .fill(Palette.cream.opacity(needsOtherCharacter ? 0.7 : 0.94))
                    .frame(width: 50, height: 50)
                Circle()
                    .stroke(Palette.lineSoft.opacity(0.45), lineWidth: 1.1)
                    .frame(width: 50, height: 50)

                Text(verbatim: hotspot.glyph)
                    .font(.system(size: 24))
                    .saturation(needsOtherCharacter ? 0.35 : 1)
            }
            .shadow(color: Palette.shadow, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .position(
            x: size.width * CGFloat(hotspot.position.x),
            y: size.height * CGFloat(hotspot.position.y)
        )
        .accessibilityLabel(Text(verbatim: hotspot.label))
        .accessibilityHint(Text(verbatim: hotspot.requiredCharacter.map { "\($0.shortName)만 만질 수 있다" } ?? ""))
    }

    /// 꼼꼼히 더듬는 자리. 돋보기 링과 지금까지 빗나간 횟수를 함께 보여 준다.
    private func searchButton(_ spot: SearchSpot, in size: CGSize) -> some View {
        let tries = store.searchTries(spot)
        let needsOtherCharacter = spot.requiredCharacter != nil
            && spot.requiredCharacter != store.character

        return Button {
            store.search(spot)
        } label: {
            ZStack {
                Circle()
                    .fill(Palette.paper.opacity(needsOtherCharacter ? 0.7 : 0.92))
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(
                        tries > 0 ? Palette.roseDeep.opacity(0.85) : Palette.dusk.opacity(0.8),
                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
                    )
                    .frame(width: 44, height: 44)

                Text(verbatim: spot.glyph)
                    .font(.system(size: 19))
                    .saturation(needsOtherCharacter ? 0.35 : 1)

                if tries > 0 {
                    Text(verbatim: "\(tries)/\(spot.maxAttempts)")
                        .font(.cozy(8.5, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Palette.roseDeep.opacity(0.9)))
                        .offset(x: 16, y: -16)
                }
            }
            .shadow(color: Palette.shadow, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .position(
            x: size.width * CGFloat(spot.position.x),
            y: size.height * CGFloat(spot.position.y)
        )
        .accessibilityLabel(Text(verbatim: "\(spot.label) 꼼꼼히 살펴보기"))
        .accessibilityHint(Text(verbatim: "\(spot.maxAttempts)번 안에 반드시 찾는다. 지금까지 \(tries)번 빗나갔다"))
    }

    private func collectibleButton(_ collectible: Collectible, in size: CGSize) -> some View {
        Button {
            store.collect(collectible)
        } label: {
            ZStack {
                Circle()
                    .fill(Palette.butter.opacity(0.28))
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(Palette.butterDeep.opacity(0.65), lineWidth: 1)
                    .frame(width: 34, height: 34)
                Text(verbatim: collectible.glyph)
                    .font(.system(size: 15))
                    .opacity(pulse ? 0.75 : 1)
            }
        }
        .buttonStyle(.plain)
        .position(
            x: size.width * CGFloat(collectible.position.x),
            y: size.height * CGFloat(collectible.position.y)
        )
        .accessibilityLabel(Text(verbatim: "숨은 \(collectible.label)"))
        .accessibilityHint(Text(verbatim: "눌러서 스크랩북에 붙인다"))
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
                    .font(.cozy(compact ? 11 : 12, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft.opacity(0.8))
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
            return Palette.rose.opacity(0.22)
        case .pico:
            return Palette.butter.opacity(0.26)
        case .creature:
            return Palette.sage.opacity(0.24)
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
                        .font(.cozy(11, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                }
                Text(line.text)
                    .font(.cozy(13.5, weight: .semibold))
                    .foregroundStyle(Palette.line)
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
                .font(.cozy(13, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
            Text(stage.title)
                .font(.cozy(24, weight: .bold))
                .foregroundStyle(Palette.line)
            Text("다음 장면으로")
                .font(.cozy(12, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 22)
        .paperCard(fill: Palette.butter.opacity(0.9), radius: 26)
        .rotationEffect(.degrees(-1.2))
    }
}
