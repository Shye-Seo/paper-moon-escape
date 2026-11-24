import Foundation

/// 스테이지 3 · 태엽 시계탑 꼭대기
enum ClocktowerStage {
    static let id = StageID.clocktower

    static let rooms: [Room] = [
        Room(
            id: .towerStairs,
            stage: .clocktower,
            title: "시계탑 계단",
            caption: "태엽 소리가 멈춘 나선 계단",
            art: .gearStairs
        ),
        Room(
            id: .towerGears,
            stage: .clocktower,
            title: "톱니바퀴 방",
            caption: "수백 개의 톱니가 잠든 방",
            art: .gearRoom
        ),
        Room(
            id: .towerBelfry,
            stage: .clocktower,
            title: "종탑 꼭대기",
            caption: "별이 종이로 접힌 하늘",
            art: .belfry,
            lock: Lock(
                .flag(Flags.clockWound),
                message: "종탑 문이 무겁게 잠겨 있다. 시계가 먼저 돌아야 한다."
            )
        )
    ]

    static let puzzle = Puzzle(
        id: .gearDials,
        kind: .dials,
        title: "세 개의 다이얼",
        prompt: "벽 그림과 같은 방향으로 다이얼을 맞춰라",
        clue: "벽 그림: 바깥 고리 12시, 가운데 고리 3시, 안쪽 고리 9시",
        tokens: [
            PuzzleToken(value: 0, label: "12시", symbol: "⬆️"),
            PuzzleToken(value: 1, label: "3시", symbol: "➡️"),
            PuzzleToken(value: 2, label: "6시", symbol: "⬇️"),
            PuzzleToken(value: 3, label: "9시", symbol: "⬅️")
        ],
        solution: [0, 1, 3],
        slotLabels: ["바깥 고리", "가운데 고리", "안쪽 고리"],
        successText: "세 다이얼이 맞물리며 톱니가 우르르 돌기 시작했다. 방 전체가 미세하게 떨린다.",
        retryText: "톱니가 서걱서걱 걸린다. 벽 그림의 바늘 방향을 다시 보자.",
        rewards: [
            .flag(Flags.gearsSolved),
            .react(.momo, "🎉"),
            .say(.narration("맞물린 톱니가 돌기 시작하자 방 안의 공기가 따뜻해졌다."))
        ]
    )

    static let hotspots: [Hotspot] = [
        // 시계탑 계단
        Hotspot(
            id: .pendulum,
            room: .towerStairs,
            label: "멈춘 진자",
            glyph: "🕰",
            position: ScenePoint(0.30, 0.48),
            effects: [
                .say(.narration("진자가 비스듬히 기울어진 채 멈춰 있다. 아래에 낡은 나무 상자가 놓여 있다."))
            ]
        ),
        Hotspot(
            id: .woodBox,
            room: .towerStairs,
            label: "낡은 나무 상자",
            glyph: "📦",
            position: ScenePoint(0.34, 0.78),
            effects: [
                .say(.narration("상자 안에서 오래된 태엽 열쇠를 발견했다. 손때가 묻어 반들반들하다.")),
                .give(.windKey)
            ],
            repeatText: "상자는 비어 있다. 바닥에 톱니 자국만 남았다."
        ),
        Hotspot(
            id: .towerWindow,
            room: .towerStairs,
            label: "계단 창",
            glyph: "🌫",
            position: ScenePoint(0.70, 0.30),
            effects: [
                .say(.narration("창밖은 온통 종이 안개다. 아주 멀리 종이달의 잘린 가장자리가 보인다."))
            ]
        ),
        Hotspot(
            id: .paperBat,
            room: .towerStairs,
            label: "종이 박쥐",
            glyph: "🦇",
            position: ScenePoint(0.84, 0.44),
            effects: [
                .react(.pico, "😆"),
                .say(.pico("종이 박쥐가 팔락팔락. 우리를 따라오는 것 같아."))
            ]
        ),

        // 톱니바퀴 방
        Hotspot(
            id: .dialPanel,
            room: .towerGears,
            label: "세 개의 다이얼",
            glyph: "⚙️",
            position: ScenePoint(0.50, 0.52),
            effects: [
                .say(.narration("다이얼 세 개가 어긋난 채 멈춰 있다. 벽의 문자판 그림과 같은 방향으로 맞춰야 할 것 같다.")),
                .openPuzzle(.gearDials)
            ],
            repeatText: "다이얼이 맞물려 돌아가고 있다. 더 손댈 곳은 없다."
        ),
        Hotspot(
            id: .clockFace,
            room: .towerGears,
            label: "문자판 그림",
            glyph: "🕒",
            position: ScenePoint(0.20, 0.28),
            effects: [
                .say(.narration("벽 그림: 바깥 고리는 12시, 가운데 고리는 3시, 안쪽 고리는 9시를 가리키고 있다."))
            ]
        ),
        Hotspot(
            id: .windSocket,
            room: .towerGears,
            label: "태엽 구멍",
            glyph: "🔩",
            position: ScenePoint(0.52, 0.84),
            effects: [
                .say(.narration("기둥에 태엽을 넣는 네모난 구멍이 뚫려 있다. 안이 텅 비어 있다."))
            ],
            itemReactions: [
                ItemReaction(
                    item: .clockPart,
                    consume: true,
                    text: "시계 부품을 끼우자 태엽이 사르르 감기며 진자가 다시 흔들린다.",
                    effects: [
                        .flag(Flags.clockWound),
                        .react(.momo, "😲"),
                        .say(.narration("덜컹, 종탑으로 이어지는 문이 열렸다."))
                    ]
                )
            ],
            mismatchText: "구멍은 네모난데 넣을 것이 없다. 시계 부품이 필요할 것 같다."
        ),
        Hotspot(
            id: .shadowKeeper,
            room: .towerGears,
            label: "시계 지기 그림자",
            glyph: "🕯",
            position: ScenePoint(0.38, 0.32),
            effects: [
                .say(.creature(name: "시계 지기 그림자", text: "달을 맞추면 너희는 집으로 갈 수 있어. 종 위에, 종이 달을. 종 아래 홈은 먼저 닦아야 하지만."))
            ]
        ),
        Hotspot(
            id: .dustyMirror,
            room: .towerGears,
            label: "먼지 쌓인 거울",
            glyph: "🪞",
            position: ScenePoint(0.90, 0.54),
            requiredCharacter: .momo,
            characterNote: "거울이 높이 걸려 있다. 발끝으로는 닿지 않으니 모모가 손으로 닦자.",
            effects: [
                .say(.narration("벽에 먼지가 두껍게 앉은 손거울이 걸려 있다. 손으로 문질러 닦으면 뒤에 새겨진 글씨가 보일 것 같다.")),
                .openDust("tower.mirror")
            ],
            hiddenWhen: [.flag(Flags.mirrorWiped)],
            repeatText: "거울은 이미 반짝이고 있다."
        ),
        Hotspot(
            id: .gearLoft,
            room: .towerGears,
            label: "톱니 선반",
            glyph: "🧱",
            position: ScenePoint(0.12, 0.66),
            requiredCharacter: .momo,
            characterNote: "선반이 벽 높이 붙어 있다. 모모가 팔을 뻗어야 닿겠다.",
            effects: [
                .say(.narration("낮은 선반에 톱니가 가지런히 꽂혀 있다. 제일 큰 톱니 옆에 '종 아래 홈을 닦아라'라고 새겨져 있다.")),
                .flag(Flags.sawGearLoft)
            ],
            repeatText: "선반의 글씨는 그대로다."
        ),

        // 종탑 꼭대기
        Hotspot(
            id: .paperBell,
            room: .towerBelfry,
            label: "종이 종",
            glyph: "🔔",
            position: ScenePoint(0.50, 0.42),
            effects: [
                .say(.narration("종이가 접힌 종이 거꾸로 매달려 있다. 종 아래엔 달 모양 홈이 파여 있다. 홈이 먼지로 덮여 있다."))
            ],
            itemReactions: [
                ItemReaction(
                    item: .paperMoonShard,
                    consume: true,
                    requires: [.flag(Flags.mirrorWiped)],
                    blocked: "달 모양 홈이 먼지로 덮여 조각이 들어가지 않는다. 무언가로 홈을 닦아야 한다.",
                    text: "닦아 낸 홈에 종이달 조각을 맞추자 종 전체가 달빛으로 빛나며 은은하게 울렸다.",
                    effects: [
                        .flag(Flags.moonRestored),
                        .react(.momo, "🌙"),
                        .say(.narration("하늘의 종이 달이 온전해졌다. 종이 소리가 비 오는 다락방의 창을 두드린다.")),
                        .clearStage
                    ]
                )
            ],
            mismatchText: "종은 조용하다. 달 모양 홈에 맞출 무언가가 필요하다."
        ),
        Hotspot(
            id: .starPaper,
            room: .towerBelfry,
            label: "종이 별",
            glyph: "⭐",
            position: ScenePoint(0.24, 0.24),
            effects: [
                .say(.narration("별 하나를 손으로 만지자 따뜻했다가 손가락을 빠져나갔다."))
            ]
        ),
        Hotspot(
            id: .belfryView,
            room: .towerBelfry,
            label: "종탑 발코니",
            glyph: "🌌",
            position: ScenePoint(0.76, 0.32),
            effects: [
                .react(.pico, "😭"),
                .say(.pico("여기서 보면 우리 집 다락방 창이 보여!"))
            ]
        )
    ]

    static let searchSpots: [SearchSpot] = [
        SearchSpot(
            id: "tower.gearPile",
            room: .towerGears,
            label: "톱니 더미",
            glyph: "🔧",
            position: ScenePoint(0.76, 0.76),
            requires: [.solved(.gearDials)],
            blocked: "톱니가 서로 잠겨 있다. 다이얼을 먼저 맞춰야 움직일 것 같다.",
            odds: [0.35, 0.60, 0.82, 1.0],
            observations: [
                "맞물린 톱니 사이로 손을 넣어 보지만 끝이 닫혀 있다. 톱니가 걸린 소리만 난다.",
                "작은 톱니가 안쪽으로 밀려 들어갔다. 손목을 더 넣으면 닿을 것 같다."
            ],
            foundText: "맞물린 톱니 사이를 더듬어 작은 톱니바퀴 하나를 빼냈다.",
            reward: .item(.gear),
            flags: [Flags.gearTaken],
            repeatText: "톱니 더미엔 작은 부품 하나가 남아 있다."
        ),
        SearchSpot(
            id: "tower.woodBoxUnderside",
            room: .towerStairs,
            label: "나무 상자 밑",
            glyph: "🏷",
            position: ScenePoint(0.58, 0.88),
            odds: [0.25, 0.50, 0.75, 1.0],
            observations: [
                "상자 밑으로 손가락을 넣어 보다. 먼지와 톱니 모양 자국만 묻어난다.",
                "바닥 널이 조금 들이켜 있다. 안쪽에 얇은 종이가 깔려 있는 것 같다.",
                "손끝에 톱니 그림이 만져진다. 종이 한 장이 끼어 있다."
            ],
            foundText: "상자 밑 바닥에서 톱니바퀴가 인쇄된 오래된 우표를 꺼냈다.",
            reward: .collectible(.stampTower),
            repeatText: "상자 밑은 먼지와 톱니 자국만 남아 있다."
        )
    ]

    static let hints: [Hint] = [
        Hint(
            id: "tower.progress.1",
            stage: .clocktower,
            doneIf: .flag(Flags.gearsSolved),
            levelOne: "톱니바퀴 방의 다이얼 세 개가 어긋나 있다. 벽 그림이 답을 쥐고 있다.",
            levelTwo: "바깥 고리 12시, 가운데 고리 3시, 안쪽 고리 9시로 맞추면 톱니가 물린다."
        ),
        Hint(
            id: "tower.progress.2",
            stage: .clocktower,
            doneIf: .flag(Flags.gearTaken),
            levelOne: "다이얼이 돌기 시작하면, 잠겨 있던 톱니 더미가 조금 열린다.",
            levelTwo: "톱니 더미를 여러 번 더듬어 작은 톱니바퀴를 꺼내자. 다이얼을 맞추지 않으면 더미가 열리지 않는다."
        ),
        Hint(
            id: "tower.progress.3",
            stage: .clocktower,
            doneIf: .flag(Flags.clockWound),
            levelOne: "멈춘 시계는 태엽이 감겨야 돌아간다. 태엽 열쇠는 계단 아래 상자에 있었다.",
            levelTwo: "태엽 열쇠와 톱니바퀴를 합쳐 시계 부품을 만들고, 기둥의 태엽 구멍에 넣자."
        ),
        Hint(
            id: "tower.progress.4",
            stage: .clocktower,
            doneIf: .flag(Flags.mirrorWiped),
            levelOne: "종 아래 홈이 먼지로 덮여 있다고 했다. 톱니바퀴 방 벽의 거울이 눈에 밟힌다.",
            levelTwo: "모모로 바꿔 먼지 쌓인 거울을 누르고, 화면을 문질러 닦아 글씨를 읽자."
        ),
        Hint(
            id: "tower.progress.5",
            stage: .clocktower,
            doneIf: .cleared(.clocktower),
            levelOne: "종탑 문이 열렸다. 종 아래에 달 모양 홈이 파여 있다.",
            levelTwo: "종이 종을 누른 채 종이달 조각을 골라 쓰면, 달이 온전해진다."
        )
    ]

    static let stage = Stage(
        id: .clocktower,
        number: 3,
        title: "태엽 시계탑 꼭대기",
        subtitle: "달을 맞추는 마지막 종",
        rooms: [.towerStairs, .towerGears, .towerBelfry],
        opening: "마지막 계단 앞. 톱니바퀴가 한 번 크게 돌아가고, 멀리서 태엽이 감기는 소리가 들린다.",
        closing: "종이달이 온전히 빛났다. 하늘에서 종이 계단이 접혀 내려와 다락방 창으로 이어졌고, 모모는 종이학을 품에 안고, 고양이 피코는 그 옆을 종종걸음으로 따라 계단을 내려갔다. 거실에선 아직 비가 내리고, 목마는 조용히 웃고 있다.",
        next: nil
    )
}
