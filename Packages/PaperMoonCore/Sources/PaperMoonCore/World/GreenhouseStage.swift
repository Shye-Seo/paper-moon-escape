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

    /// 찢어진 종잇조각을 맞춘 뒤 랜턴 빛을 비추면 숨은 글자가 드러난다.
    /// 화면에서는 조각을 끌어다 놓고, 조명을 좌우로 기울이거나 손가락으로 쓸어 비춘다.
    static let lightPuzzle = Puzzle(
        id: .tornPaperCode,
        kind: .lightReveal,
        title: "찢어진 종이 도면",
        prompt: "찢어진 종잇조각을 제자리에 맞추고, 랜턴 빛을 비춰 숨은 글자를 읽어라",
        clue: "가장자리의 이끼 무늬와 잉크선이 이어진다. 빛은 종이 뒤에서 비춘다.",
        tokens: [
            PuzzleToken(value: 0, label: "달무리 조각", symbol: "🌙"),
            PuzzleToken(value: 1, label: "이끼 조각", symbol: "🌿"),
            PuzzleToken(value: 2, label: "잉크 조각", symbol: "🖋"),
            PuzzleToken(value: 3, label: "물방울 조각", symbol: "💧")
        ],
        solution: [2, 0, 3, 1],
        slotLabels: ["왼쪽 위", "오른쪽 위", "왼쪽 아래", "오른쪽 아래"],
        successText: "마지막 조각이 들어가자 이끼 무늬가 한 줄로 이어졌다. 랜턴을 뒤로 대자 종이에 숨은 글씨가 떠올랐다.",
        retryText: "무늬가 어긋나 글씨가 두 동강으로 갈라졌다. 조각의 가장자리를 다시 보자.",
        rewards: [
            .flag(Flags.lightCodeSeen),
            .react(.pico, "🔍"),
            .say(.narration("숨은 글씨: '달은 나뭇가지 끝에서 잠깐 쉰다. 종이달의 이 빠진 자리를 찾아라.'"))
        ],
        goal: "숨은 암호",
        revealedCode: "달은 나뭇가지 끝에서 잠깐 쉰다",
        lightSource: .lantern
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
            requires: [.flag(Flags.vineGrown), .flag(Flags.shardFound)],
            blocked: "덩굴이 아직 얇거나, 달 조각을 아직 챙기지 않았다. 손에 든 것이 없으면 문이 열리지 않는다.",
            effects: [
                .react(.momo, "🤩"),
                .say(.narration("종이달 조각을 든 채 덩굴을 밀자, 덩굴이 계단처럼 엮이며 위로 올라가는 길이 열렸다. 저 위에서 태엽 소리가 들린다.")),
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
        Hotspot(
            id: .hangingPot,
            room: .greenhouseVines,
            label: "매달린 화분",
            glyph: "🪻",
            position: ScenePoint(0.86, 0.18),
            requiredCharacter: .momo,
            characterNote: "천장에 매달린 화분은 높다. 피코가 뛰어도 닿지 않으니 모모가 맡자.",
            effects: [
                .react(.momo, "🌿"),
                .say(.narration("모모가 화분을 받쳐 내려다본다. 흙 속에 오래된 물길 지도 조각이 꽂혀 있다. '물이 흐르면 화분까지 닿는다'고 적혀 있다.")),
                .flag(Flags.sawHangingPot)
            ],
            repeatText: "화분은 조용히 매달려 있다."
        ),

        // 노래하는 연못
        Hotspot(
            id: .frogChorus,
            room: .greenhousePond,
            label: "개구리 합창단",
            glyph: "🐸",
            position: ScenePoint(0.44, 0.62),
            requiredCharacter: .pico,
            characterNote: "개구리들이 낯선 사람에게는 입을 다문다. 작은 고양이 피코라면 노래를 따라 부를 수 있을 것 같다.",
            effects: [
                .react(.frog, "🎵"),
                .say(.creature(name: "개구리 합창단", text: "개굴! 고양이 목소리구나. 우리 노래를 따라 불러 봐. 연못가 돌의 물빛 순서대로야.")),
                .openPuzzle(.frogSong)
            ],
            repeatText: "개구리들이 만족스럽게 눈을 감고 작게 울었다."
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
            requires: [.flag(Flags.lightCodeSeen)],
            blocked: "나뭇가지 끝이 찢긴 종이에 가려 흐릿하다. 종이 너머로 빛을 비춰 무엇이 있는지 먼저 확인하자.",
            effects: [
                .react(.momo, "🌙"),
                .say(.narration("숨은 글씨가 가리킨 자리, 거꾸로 매달린 나뭇가지 끝에 종이달 조각이 걸려 있었다. 손에 쥐자 따뜻하다.")),
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
            id: .tornPaperWindow,
            room: .greenhouseGlass,
            label: "찢어진 종이창",
            glyph: "📄",
            position: ScenePoint(0.90, 0.52),
            requires: [.item(.lantern)],
            blocked: "종이가 겹겹이 붙어 어둡다. 뒤에서 비출 빛이 있어야 조각을 맞출 수 있겠다.",
            requiredCharacter: .pico,
            characterNote: "종잇조각이 바람에 팔랑인다. 발끝이 가벼운 피코가 조각을 맞출 수 있을 것 같다.",
            effects: [
                .say(.narration("유리창 안쪽에 종이가 찢어진 채 붙어 있다. 조각을 맞추고 뒤에서 랜턴을 비추면 무언가 보일 것 같다.")),
                .openPuzzle(.tornPaperCode)
            ],
            itemReactions: [
                ItemReaction(
                    item: .lantern,
                    consume: false,
                    text: "랜턴을 종이 뒤로 대자 조각의 가장자리가 밝게 드러났다.",
                    effects: [.openPuzzle(.tornPaperCode)]
                )
            ],
            hiddenWhen: [.flag(Flags.lightCodeSeen)],
            repeatText: "종잇조각은 이미 제자리에 맞춰져 있다."
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

    static let searchSpots: [SearchSpot] = [
        SearchSpot(
            id: "greenhouse.pondShelf",
            room: .greenhousePond,
            label: "연못가 선반",
            glyph: "🫙",
            position: ScenePoint(0.74, 0.68),
            odds: [0.40, 0.70, 1.0],
            observations: [
                "선반에 병이 가지런히 놓여 있다. 하나씩 들어 보지만 모두 바닥이 깨져 비어 있다.",
                "선반 뒤쪽에 손이 들어가는 틈이 있다. 무언가 딸그락 소리를 낸다."
            ],
            foundText: "선반 뒤에서 뚜껑이 딸린 맑은 유리병을 꺼냈다. 흔들어 보니 안이 비어 있다.",
            reward: .item(.emptyJar),
            repeatText: "선반에는 병이 놓여 있던 자국만 남아 있다."
        ),
        SearchSpot(
            id: "greenhouse.firefly",
            room: .greenhousePond,
            label: "반딧불이 떼",
            glyph: "✨",
            position: ScenePoint(0.62, 0.28),
            requiredCharacter: .pico,
            characterNote: "반딧불이는 겁이 많아 큰 손을 피한다. 앞발이 작은 피코라면 조심히 잡을 수 있겠다.",
            odds: [0.28, 0.48, 0.68, 0.86, 1.0],
            observations: [
                "반딧불이가 손끝을 스치고 도망간다. 조금만 움직여도 다 흩어진다.",
                "연못 위쪽에 불빛이 모여 있다. 숨을 죽이고 기다려야 할 것 같다.",
                "이제 한 마리가 앞발 가까이 왔다. 숨을 참으면 잡힐 것 같다.",
                "반딧불이 한 마리가 앞발 위에서 맴돈다. 조심히 감싸 보자."
            ],
            foundText: "앞발을 조심히 오므로자 반딧불이 한 마리가 손안에 앉았다. 따뜻하다.",
            reward: .item(.firefly),
            repeatText: "반딧불이들이 손끝을 맴돌다 흩어진다."
        ),
        SearchSpot(
            id: "greenhouse.fireflyCrane",
            room: .greenhousePond,
            label: "반딧불이 곁 풀숲",
            glyph: "🕊",
            position: ScenePoint(0.88, 0.12),
            requires: [.item(.lantern)],
            blocked: "풀숲이 어두우니 빛을 들고 와야 보일 것 같다.",
            odds: [0.30, 0.55, 0.80, 1.0],
            observations: [
                "랜턴을 들이대도 풀숲이 우거져 바닥이 잘 보이지 않는다.",
                "풀잎 사이에 종이 같은 것이 깔려 있다. 하나 더 밝은 곳을 찾아보자."
            ],
            foundText: "풀숲 아래에 반딧불 빛을 머금은 붓 채 놓인 종이학을 발견했다.",
            reward: .collectible(.craneFirefly),
            repeatText: "풀숲 아래는 이제 휑하다."
        )
    ]

    static let hints: [Hint] = [
        Hint(
            id: "greenhouse.progress.1",
            stage: .greenhouse,
            doneIf: .flag(Flags.waterFlowing),
            levelOne: "연못의 개구리들이 무언가 기다리는 표정이다. 노래가 열쇠일지도.",
            levelTwo: "피코로 바꿔 개구리에게 말을 걸고, 연못가 돌의 물빛 순서(파-레-솔-미)대로 음을 이어 보자."
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
            doneIf: .item(.lantern),
            levelOne: "유리방은 깜깜하다. 연못가에서 빛을 만들 재료를 챙기자.",
            levelTwo: "연못가 선반을 여러 번 더듬어 유리병을, 피코로 반딧불이 떼를 여러 번 더듬어 반딧불이를 얻은 뒤 주머니에서 둘을 합치자."
        ),
        Hint(
            id: "greenhouse.progress.5",
            stage: .greenhouse,
            doneIf: .flag(Flags.lightCodeSeen),
            levelOne: "유리방 구석의 찢어진 종이가 눈에 밟힌다. 피코의 작은 발끝이면 조각을 맞출 수 있다.",
            levelTwo: "반딧불이 랜턴을 든 채 피코로 바꿔 '찢어진 종이창'을 누르고, 조각을 정확히 맞춘 뒤 랜턴을 비추자."
        ),
        Hint(
            id: "greenhouse.progress.6",
            stage: .greenhouse,
            doneIf: .flag(Flags.shardFound),
            levelOne: "숨은 글씨가 가리킨 자리를 다시 떠올려 보자. 나뭇가지 끝이다.",
            levelTwo: "유리방의 거꾸로 매달린 나뭇가지 끝, 종이달 조각을 눌러 챙기자."
        ),
        Hint(
            id: "greenhouse.progress.7",
            stage: .greenhouse,
            doneIf: .cleared(.greenhouse),
            levelOne: "손에 종이달 조각이 있다면, 이제 덩굴 문으로 갈 차례다.",
            levelTwo: "덩굴 문을 눌러 위로 올라가자. 다음은 태엽이 멈춘 시계탑."
        )
    ]

    static let stage = Stage(
        id: .greenhouse,
        number: 2,
        title: "거꾸로 자라는 온실",
        subtitle: "노래가 물을 데려가는 곳",
        rooms: [.greenhouseVines, .greenhousePond, .greenhouseGlass],
        opening: "거꾸로 자라는 덩굴 사이로 모모와 고양이 피코가 미끄러졌다. 흙 냄새, 젖은 이끼, 그리고 노래 소리가 가득한 온실.",
        closing: "덩굴이 계단처럼 엮여 하늘로 뻗었다. 올라가며 뒤를 돌아보니 연못의 개구리들이 화음을 길게 늘여 배웅했다. 저 위엔 태엽이 멈춘 시계탑.",
        next: .clocktower
    )
}
