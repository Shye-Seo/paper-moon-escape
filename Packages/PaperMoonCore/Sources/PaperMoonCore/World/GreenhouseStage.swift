import Foundation

/// 스테이지 2 · 거꾸로 자라는 온실
enum GreenhouseStage {
    static let id = StageID.greenhouse

    static let rooms: [Room] = [
        Room(
            id: .greenhouseVines,
            stage: .greenhouse,
            title: "덩굴 문",
            caption: "식물이 하늘을 향해 거꾸로 자라는 온실 입구",
            art: .vineGate
        ),
        Room(
            id: .greenhousePond,
            stage: .greenhouse,
            title: "노래하는 연못",
            caption: "개구리 합창단이 사는 초록 연못",
            art: .frogPond
        ),
        Room(
            id: .greenhouseGlass,
            stage: .greenhouse,
            title: "거꾸로 유리방",
            caption: "빛이 닿지 않는 유리 온실 안쪽",
            art: .glassHouse,
            lock: Lock(
                .item(.lantern),
                message: "유리방 안이 깜깜하다. 손에 쥔 빛이 필요하다."
            )
        )
    ]

    static let puzzle = Puzzle(
        id: .frogSong,
        kind: .song,
        title: "개구리 합창단의 노래",
        prompt: "연못가 돌의 물빛 순서대로 음을 이어 불러라",
        clue: "돌의 물빛이 파 → 레 → 솔 → 미 순서로 번뜩인다",
        tokens: [
            PuzzleToken(value: 0, label: "도", symbol: "🔵"),
            PuzzleToken(value: 1, label: "레", symbol: "🟣"),
            PuzzleToken(value: 2, label: "미", symbol: "🟠"),
            PuzzleToken(value: 3, label: "파", symbol: "🟡"),
            PuzzleToken(value: 4, label: "솔", symbol: "🟢")
        ],
        solution: [3, 1, 4, 2],
        slotLabels: ["첫 소절", "둘째 소절", "셋째 소절", "넷째 소절"],
        successText: "개구리들이 마지막 음을 길게 늘였다. 연못 물이 도랑을 따라 온실 입구로 흘러간다.",
        retryText: "개구리들이 고개를 갸웃한다. 물빛이 번뜩이는 순서를 다시 보자.",
        rewards: [
            .flag(Flags.waterFlowing),
            .react(.frog, "🎶"),
            .say(.narration("연못 물이 도랑을 타고 덩굴 문 앞 화분으로 흘러갔다."))
        ]
    )

    static let hotspots: [Hotspot] = [
        // 덩굴 문
        Hotspot(
            id: .seedPouch,
            room: .greenhouseVines,
            label: "씨앗 주머니",
            glyph: "🌰",
            position: ScenePoint(0.22, 0.84),
            effects: [
                .say(.narration("덩굴 사이에 매달린 씨앗 주머니에서 반짝이는 씨앗 하나를 꺼냈다.")),
                .give(.seed)
            ],
            repeatText: "씨앗 주머니는 이제 바스락거리기만 한다."
        ),
        Hotspot(
            id: .wateringCanCorner,
            room: .greenhouseVines,
            label: "물뿌리개",
            glyph: "🚿",
            position: ScenePoint(0.14, 0.60),
            effects: [
                .say(.narration("낡은 물뿌리개를 들었다. 안은 비어 있다. 물이 흐르는 곳에서 채워야 할 것 같다.")),
                .give(.wateringCan)
            ],
            repeatText: "물뿌리개는 이미 내 손안에 있다."
        ),
        Hotspot(
            id: .flowerPot,
            room: .greenhouseVines,
            label: "빈 화분",
            glyph: "🪴",
            position: ScenePoint(0.36, 0.72),
            effects: [
                .say(.narration("화분 흙이 바싹 말라 있다. 무언가 심으면 자랄 것 같다. 옆으로 물길이 이어져 있다."))
            ],
            itemReactions: [
                ItemReaction(
                    item: .seed,
                    consume: true,
                    text: "씨앗을 흙에 살며시 묻었다. 흙이 꿈틀, 하고 숨을 쉰다.",
                    effects: [
                        .flag(Flags.seedPlanted),
                        .react(.pico, "🌱"),
                        .say(.narration("씨앗이 흙 속에서 작게 맥박친다. 이제 물이 필요하다."))
                    ]
                ),
                ItemReaction(
                    item: .wateringCan,
                    consume: false,
                    requires: [.flag(Flags.seedPlanted), .flag(Flags.waterFlowing)],
                    blocked: "물뿌리개가 비어 있거나, 심은 씨앗이 아직 없다. 물길과 씨앗을 먼저 챙기자.",
                    text: "물을 주자 흙에서 덩굴이 솟구쳐 하늘로 뻗었다!",
                    effects: [
                        .flag(Flags.vineGrown),
                        .react(.momo, "😲"),
                        .say(.narration("덩굴이 계단처럼 엮이며 천장 너머로 올라간다. 이제 위로 갈 수 있다."))
                    ]
                )
            ],
            mismatchText: "화분에는 씨앗이나 물이 어울릴 것 같다."
        ),
        Hotspot(
            id: .vineGate,
            room: .greenhouseVines,
            label: "덩굴 문",
            glyph: "🌿",
            position: ScenePoint(0.64, 0.40),
            requires: [.flag(Flags.vineGrown)],
            blocked: "덩굴이 아직 얇다. 화분의 씨앗이 자라야 문이 열릴 것 같다.",
            effects: [
                .react(.momo, "🤩"),
                .say(.narration("덩굴이 계단처럼 엮이며 위로 올라가는 길이 열렸다. 저 위에서 태엽 소리가 들린다.")),
                .clearStage
            ]
        ),
        Hotspot(
            id: .signpost,
            room: .greenhouseVines,
            label: "이끼 낀 표지판",
            glyph: "🪧",
            position: ScenePoint(0.84, 0.66),
            effects: [
                .say(.narration("이끼 낀 표지판: '노래가 맞으면 물이 흐른다. 병은 연못가 선반에.'")),
                .flag(Flags.readSign)
            ]
        ),

        // 노래하는 연못
        Hotspot(
            id: .frogChorus,
            room: .greenhousePond,
            label: "개구리 합창단",
            glyph: "🐸",
            position: ScenePoint(0.44, 0.62),
            effects: [
                .react(.frog, "🎵"),
                .say(.creature(name: "개구리 합창단", text: "개굴! 우리 노래를 따라 불러 봐. 연못가 돌의 물빛 순서대로야.")),
                .openPuzzle(.frogSong)
            ],
            repeatText: "개구리들이 만족스럽게 꿀꺽, 하고 울음소리를 삼켰다."
        ),
        Hotspot(
            id: .pondShelf,
            room: .greenhousePond,
            label: "연못가 선반",
            glyph: "🫙",
            position: ScenePoint(0.74, 0.68),
            effects: [
                .say(.narration("선반 위에 맑은 유리병이 하나 놓여 있었다. 뚜껑이 딸려 있다.")),
                .give(.emptyJar)
            ],
            repeatText: "선반에는 병이 놓여 있던 자국만 남아 있다."
        ),
        Hotspot(
            id: .fireflies,
            room: .greenhousePond,
            label: "반딧불이 떼",
            glyph: "✨",
            position: ScenePoint(0.62, 0.28),
            effects: [
                .react(.pico, "🤲"),
                .say(.pico("반딧불이가 손끝에 앉았어! 따뜻해...")),
                .give(.firefly)
            ],
            repeatText: "반딧불이들이 손끝을 맴돌다 흩어진다."
        ),
        Hotspot(
            id: .stoneSteps,
            room: .greenhousePond,
            label: "물빛 돌",
            glyph: "🪨",
            position: ScenePoint(0.22, 0.52),
            effects: [
                .say(.narration("연못가에 다섯 개의 돌이 있고, 물에 잠긴 높이가 제각각이다. 물빛이 파 → 레 → 솔 → 미 순서로 번뜩인다."))
            ]
        ),
        Hotspot(
            id: .lilyPad,
            room: .greenhousePond,
            label: "수련잎",
            glyph: "🪷",
            position: ScenePoint(0.88, 0.82),
            effects: [
                .say(.narration("수련잎 위에 이슬이 맺혀 있다. 손대면 노래처럼 소리가 난다."))
            ]
        ),

        // 거꾸로 유리방
        Hotspot(
            id: .moonShardBranch,
            room: .greenhouseGlass,
            label: "종이달 조각",
            glyph: "🌙",
            position: ScenePoint(0.52, 0.44),
            effects: [
                .react(.momo, "🌙"),
                .say(.narration("거꾸로 매달린 나뭇가지 끝에 종이달 조각이 걸려 있었다. 손에 쥐자 따뜻하다.")),
                .give(.paperMoonShard),
                .flag(Flags.shardFound)
            ],
            repeatText: "나뭇가지 끝이 비어 있다."
        ),
        Hotspot(
            id: .upsideTree,
            room: .greenhouseGlass,
            label: "거꾸로 자라는 나무",
            glyph: "🌳",
            position: ScenePoint(0.26, 0.30),
            effects: [
                .say(.narration("나무가 뿌리를 천장에 박고 아래로 자란다. 잎마다 작은 종이 별이 달려 있다."))
            ]
        ),
        Hotspot(
            id: .glassWindow,
            room: .greenhouseGlass,
            label: "유리창",
            glyph: "🪟",
            position: ScenePoint(0.78, 0.32),
            effects: [
                .say(.pico("유리에 비친 달이 조각난 달과 똑같이 생겼어."))
            ]
        ),
        Hotspot(
            id: .mossNote,
            room: .greenhouseGlass,
            label: "이끼 글씨",
            glyph: "📜",
            position: ScenePoint(0.66, 0.76),
            effects: [
                .say(.narration("이끼로 쓰인 글씨: '시계탑 꼭대기에서 달을 맞추면 집으로 가는 문이 열린다.'")),
                .flag(Flags.readMoss)
            ]
        )
    ]

    static let hints: [Hint] = [
        Hint(
            id: "greenhouse.progress.1",
            stage: .greenhouse,
            doneIf: .flag(Flags.waterFlowing),
            levelOne: "연못의 개구리들이 무언가 기다리는 표정이다. 노래가 열쇠일지도.",
            levelTwo: "개구리에게 말을 걸어 노래를 시작하고, 연못가 돌의 물빛 순서(파-레-솔-미)대로 음을 이어 보자."
        ),
        Hint(
            id: "greenhouse.progress.2",
            stage: .greenhouse,
            doneIf: .flag(Flags.seedPlanted),
            levelOne: "덩굴 문 앞 화분이 텅 비어 있다. 심을 것이 필요하다.",
            levelTwo: "씨앗 주머니에서 씨앗을 꺼내 인벤토리에서 골라 화분에 심자."
        ),
        Hint(
            id: "greenhouse.progress.3",
            stage: .greenhouse,
            doneIf: .flag(Flags.vineGrown),
            levelOne: "심은 씨앗에게 필요한 것은 물이다. 물은 어디로 흐르고 있나?",
            levelTwo: "개구리 노래로 물이 흐르게 한 뒤, 물뿌리개를 골라 화분에 사용하자."
        ),
        Hint(
            id: "greenhouse.progress.4",
            stage: .greenhouse,
            doneIf: .flag(Flags.shardFound),
            levelOne: "오른쪽으로 가면 문이 하나 더 있는데, 안이 깜깜하다.",
            levelTwo: "반딧불이와 유리병을 합쳐 랜턴을 만들고, 랜턴을 든 채 유리방으로 들어가자."
        ),
        Hint(
            id: "greenhouse.progress.5",
            stage: .greenhouse,
            doneIf: .cleared(.greenhouse),
            levelOne: "덩굴이 하늘로 뻗었다. 이제 위로 갈 차례다.",
            levelTwo: "덩굴 문을 눌러 위로 올라가자. 다음은 태엽이 멈춘 시계탑."
        )
    ]

    static let stage = Stage(
        id: .greenhouse,
        number: 2,
        title: "거꾸로 자라는 온실",
        subtitle: "노래가 물을 데려가는 곳",
        rooms: [.greenhouseVines, .greenhousePond, .greenhouseGlass],
        opening: "거꾸로 자라는 덩굴 사이로 두 남매가 미끄러졌다. 흙 냄새, 젖은 이끼, 그리고 노래 소리가 가득한 온실.",
        closing: "덩굴이 계단처럼 엮여 하늘로 뻗었다. 올라가며 뒤를 돌아보니 연못의 개구리들이 화음을 길게 늘여 배웅했다. 저 위엔 태엽이 멈춘 시계탑.",
        next: .clocktower
    )
}
