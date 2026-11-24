import Foundation

/// 스테이지 1 · 삐걱이는 장난감 다락방
enum AtticStage {
    static let id = StageID.attic

    static let rooms: [Room] = [
        Room(
            id: .atticLanding,
            stage: .attic,
            title: "다락방 계단참",
            caption: "비 오는 토요일, 삐걱이는 나무 계단 끝",
            art: .atticLanding
        ),
        Room(
            id: .atticToyCloset,
            stage: .attic,
            title: "장난감 창고",
            caption: "먼지 냄새와 색 블록이 굴러다니는 방",
            art: .toyCloset
        ),
        Room(
            id: .atticMoonWindow,
            stage: .attic,
            title: "종이달 창",
            caption: "종이달이 창틀을 가득 채운 곳",
            art: .moonWindow
        )
    ]

    static let puzzle = Puzzle(
        id: .toyBlocks,
        kind: .blocks,
        title: "네 색 블록 자물쇠",
        prompt: "벽 그림과 같은 순서로 블록을 놓아라",
        clue: "벽 그림: 로즈 → 세이지 → 버터 → 라벤더",
        tokens: [
            PuzzleToken(value: 0, label: "로즈", symbol: "🟠"),
            PuzzleToken(value: 1, label: "라벤더", symbol: "🔵"),
            PuzzleToken(value: 2, label: "버터", symbol: "🟡"),
            PuzzleToken(value: 3, label: "세이지", symbol: "🟢")
        ],
        solution: [0, 3, 2, 1],
        slotLabels: ["첫째", "둘째", "셋째", "넷째"],
        successText: "네 색 블록이 제자리에 놓이자 뚜껑이 덜컹, 열렸다. 안에서 톱니 모양 열쇠 조각이 나왔다.",
        retryText: "블록이 서걱거리며 튕겨 나왔다. 벽 그림의 색 순서를 다시 보자.",
        rewards: [
            .flag(Flags.toyBoxOpen),
            .give(.keyShardTooth),
            .react(.pico, "🤩"),
            .say(.narration("상자 안에서 톱니처럼 생긴 열쇠 조각을 꺼냈다. 다른 조각과 맞물릴 것 같다."))
        ]
    )

    /// 종이 도면을 순서대로 접어 종이달 등불을 만든다.
    /// 화면에서는 도면을 직접 스와이프하거나, 접기 단추를 순서대로 눌러도 된다.
    static let origamiPuzzle = Puzzle(
        id: .paperMoonOrigami,
        kind: .origami,
        title: "종이달 접기",
        prompt: "도면의 순서대로 종이를 접어 달 모양 등불을 만들어라",
        clue: "도면 가장자리: 네 귀를 모으고 → 아래로 접고 → 가운데를 눌러 → 달 모양으로 펴기",
        tokens: [
            PuzzleToken(value: 0, label: "네 귀 모으기", symbol: "🔻"),
            PuzzleToken(value: 1, label: "가운데 누르기", symbol: "🔶"),
            PuzzleToken(value: 2, label: "아래로 접기", symbol: "🔹"),
            PuzzleToken(value: 3, label: "달 모양 펴기", symbol: "🌙")
        ],
        solution: [0, 2, 1, 3],
        slotLabels: ["첫 접기", "둘째 접기", "셋째 접기", "마지막 접기"],
        successText: "마지막 접기에서 종이가 살짝 부풀며 작은 달 모양 등불이 되었다. 심지는 아직 비어 있다.",
        retryText: "접힌 자리가 삐뚤게 어긋났다. 도면의 순서를 다시 보자.",
        rewards: [
            .take(.paperSheet),
            .flag(Flags.origamiMoon),
            .give(.paperMoonLamp),
            .react(.momo, "✨"),
            .say(.narration("도면 한 장이 달 모양 등불이 되었다. 안을 들여다보니 심지를 꽂을 자리가 비어 있다."))
        ],
        goal: "종이달 등불",
        resetText: "손이 미끄러져 접힌 자리가 탁 풀렸다. 종이가 다시 반듯해졌다. 첫 접기부터 다시 해야 한다."
    )

    static let hotspots: [Hotspot] = [
        // 다락방 계단참
        Hotspot(
            id: .rockingHorse,
            room: .atticLanding,
            label: "목마",
            glyph: "🐴",
            position: ScenePoint(0.26, 0.66),
            effects: [
                .react(.momo, "😲"),
                .say(.narration("목마를 쓰다듬자 삐걱, 하고 크게 흔들렸다. 안장 밑에서 반짝이는 열쇠 조각이 톡 떨어졌다.")),
                .give(.keyShardOval),
                .flag(Flags.horseRocked)
            ],
            repeatText: "목마는 만족한 듯 조용히 흔들리기만 한다. 안장 밑은 이제 텅 비어 있다."
        ),
        Hotspot(
            id: .owlClock,
            room: .atticLanding,
            label: "부엉이 시계지기",
            glyph: "🦉",
            position: ScenePoint(0.62, 0.42),
            requires: [.flag(Flags.horseRocked)],
            blocked: "졸린 부엉이 시계지기가 눈을 감고 새근새근 잔다. 무언가 소리가 나야 깰 것 같다.",
            effects: [
                .react(.owl, "😳"),
                .say(.creature(name: "부엉이 시계지기", text: "부엉, 삐걱 소리에 잠이 확 달아났구나. 이걸 가져가렴. 열쇠를 붙일 때 쓸 거란다.")),
                .give(.glueBottle),
                .flag(Flags.owlAwake)
            ],
            repeatText: "부엉이 시계지기가 다시 꾸벅꾸벅 졸고 있다. 서랍은 열린 채다."
        ),
        Hotspot(
            id: .atticLadder,
            room: .atticLanding,
            label: "사다리",
            glyph: "🪜",
            position: ScenePoint(0.08, 0.52),
            effects: [
                .say(.pico("사다리 아래 거실 문이 종이처럼 얇게 접혀 있어. 돌아갈 문이 없어졌어!"))
            ]
        ),
        Hotspot(
            id: .paperCrane,
            room: .atticLanding,
            label: "종이학",
            glyph: "🕊",
            position: ScenePoint(0.84, 0.26),
            effects: [
                .react(.pico, "🤩"),
                .say(.pico("종이학이 날개를 파닥이며 인사하고 창밖으로 사라졌어. 방마다 한 마리씩 숨어 있는 것 같아."))
            ]
        ),

        // 장난감 창고
        Hotspot(
            id: .toyBox,
            room: .atticToyCloset,
            label: "장난감 상자",
            glyph: "🧸",
            position: ScenePoint(0.44, 0.72),
            effects: [
                .react(.pico, "🤩"),
                .say(.narration("상자 뚜껑에 네 색 블록 자물쇠가 걸려 있다. 벽 그림과 같은 순서로 블록을 놓아야 할 것 같다.")),
                .openPuzzle(.toyBlocks)
            ],
            repeatText: "상자는 활짝 열려 있다. 안에는 부스러기만 남았다."
        ),
        Hotspot(
            id: .blockPoster,
            room: .atticToyCloset,
            label: "벽 그림",
            glyph: "🖼",
            position: ScenePoint(0.20, 0.26),
            effects: [
                .say(.narration("벽에 아이가 그린 그림이 있다. 로즈, 세이지, 버터, 라벤더 순서로 블록이 쌓여 있고 아래에 '이 순서!'라고 삐뚤빼뚤 적혀 있다.")),
                .flag(Flags.sawPoster)
            ]
        ),
        Hotspot(
            id: .blockPile,
            room: .atticToyCloset,
            label: "블록 더미",
            glyph: "🧩",
            position: ScenePoint(0.74, 0.78),
            effects: [
                .say(.pico("블록이 네 색이야. 상자 자물쇠에 딱 맞을 것 같아."))
            ]
        ),
        Hotspot(
            id: .toyShelf,
            room: .atticToyCloset,
            label: "장난감 선반",
            glyph: "🎠",
            position: ScenePoint(0.86, 0.46),
            effects: [
                .say(.narration("고장 난 태엽 인형들이 나란히 앉아 있다. 하나같이 같은 방향, 시계탑 쪽을 가리키고 있다."))
            ]
        ),
        Hotspot(
            id: .foldingDesk,
            room: .atticToyCloset,
            label: "종이접기 책상",
            glyph: "🪑",
            position: ScenePoint(0.50, 0.22),
            requires: [.item(.paperSheet)],
            blocked: "책상 위에 도면을 펼 자리가 비어 있다. 접을 종이부터 찾아야 한다.",
            requiredCharacter: .momo,
            characterNote: "접기는 모모의 손이 필요하다. 피코의 앞발로는 종이가 찢어질 것 같다.",
            effects: [
                .say(.narration("도면을 책상에 펼쳤다. 접힌 자리를 따라 순서대로 접어야 한다.")),
                .openPuzzle(.paperMoonOrigami)
            ],
            itemReactions: [
                ItemReaction(
                    item: .paperSheet,
                    consume: false,
                    text: "도면을 책상 위에 펼쳤다. 접힌 자국이 순서를 알려 준다.",
                    effects: [.openPuzzle(.paperMoonOrigami)]
                )
            ],
            hiddenWhen: [.flag(Flags.origamiMoon)],
            repeatText: "책상 위에는 이미 달 모양 등불이 놓여 있다."
        ),

        // 종이달 창
        Hotspot(
            id: .moonLatch,
            room: .atticMoonWindow,
            label: "녹슨 걸쇠",
            glyph: "🔒",
            position: ScenePoint(0.50, 0.52),
            effects: [
                .say(.narration("창문이 굳게 잠겨 있다. 걸쇠 틈이 조금 벌어져 있어 무언가를 끼워 볼 수 있을 것 같다."))
            ],
            itemReactions: [
                ItemReaction(
                    item: .mendedKey,
                    consume: true,
                    requires: [.flag(Flags.lampLit)],
                    blocked: "열쇠는 들어갈 것 같은데 창틀이 너무 어둡다. 종이달 등불을 켜서 비춰 봐야겠다.",
                    text: "이어 붙인 열쇠가 걸쇠 틈에서 딸깍, 돌아갔다. 등불을 든 채 창이 스르르 열린다.",
                    effects: [
                        .flag(Flags.moonOpened),
                        .react(.momo, "😲"),
                        .say(.narration("종이달이 커다랗게 부풀어 오르며 창틀을 가득 채웠다. 달빛이 발밑에 종잇장 같은 길을 그린다.")),
                        .clearStage
                    ]
                )
            ],
            mismatchText: "그걸로는 걸쇠가 꿈쩍도 하지 않는다. 열쇠 모양의 무언가가 필요하다."
        ),
        Hotspot(
            id: .paperMoonMobile,
            room: .atticMoonWindow,
            label: "종이달 모빌",
            glyph: "🌙",
            position: ScenePoint(0.74, 0.22),
            effects: [
                .say(.narration("종이로 접은 달이 실에 매달려 천천히 돈다. 달의 한쪽이 뭉툭하게 잘려 나가 있다.")),
                .flag(Flags.sawMoonGap)
            ]
        ),
        Hotspot(
            id: .rainyWindow,
            room: .atticMoonWindow,
            label: "빗방울 창",
            glyph: "🌧",
            position: ScenePoint(0.22, 0.30),
            effects: [
                .say(.pico("비가 창에 닿을 때마다 종이 젖는 소리가 나. 우리 지금 종이 안에 있는 거 아냐?"))
            ]
        ),
        Hotspot(
            id: .curtain,
            room: .atticMoonWindow,
            label: "커튼",
            glyph: "🎐",
            position: ScenePoint(0.88, 0.62),
            effects: [
                .say(.narration("커튼 뒤에 크레파스 낙서가 있다. '달이 다 되면 집에 갈 수 있어.'")),
                .flag(Flags.readCurtainNote)
            ]
        )
    ]

    static let searchSpots: [SearchSpot] = [
        SearchSpot(
            id: "attic.highShelf",
            room: .atticLanding,
            label: "높은 선반",
            glyph: "🗄",
            position: ScenePoint(0.90, 0.60),
            requiredCharacter: .momo,
            characterNote: "선반이 높다. 피코가 아무리 발끝을 세워도 닿지 않는다. 모모라면 손이 닿을 것 같다.",
            odds: [0.45, 0.75, 1.0],
            observations: [
                "선반 위에 상자가 몇 개 쌓여 있고, 그 위로 먼지가 두껍다. 팔을 뻗어 더듬어 보지만 손끝에 닿는 건 상자뿐이다.",
                "상자 사이 틈으로 바람이 새는 자리가 있다. 무언가 끼어 있는 듯하다."
            ],
            foundText: "상자 틈에서 먼지를 뒤집어쓴 종이 도면을 조심히 빼냈다. 접힌 자국이 아직 살아 있다.",
            reward: .item(.paperSheet),
            flags: [Flags.paperSheetTaken],
            repeatText: "선반 위에는 도면이 놓여 있던 먼지 자국만 남아 있다."
        ),
        SearchSpot(
            id: "attic.mouseHole",
            room: .atticToyCloset,
            label: "쥐구멍",
            glyph: "🕳",
            position: ScenePoint(0.06, 0.90),
            requiredCharacter: .pico,
            characterNote: "쥐구멍은 모모의 손이 들어가기엔 좁다. 피코라면 앞발을 넣어 볼 수 있겠다.",
            odds: [0.30, 0.50, 0.70, 0.88, 1.0],
            observations: [
                "쥐구멍이 깜깜하다. 앞발을 넣어 휘저어 보지만 먼지와 실밥만 묻는다.",
                "안쪽은 바깥보다 따뜻하다. 무언가 종이처럼 부스럭거린다.",
                "꼬리 끝이 무언가 길쭉한 것에 스쳤다. 조금만 더 들어가면 닿을 것 같다.",
                "거의 잡힐 것 같은데 굴러가 버렸다. 발톱을 더 바닥에 붙여 보자."
            ],
            foundText: "앞발을 깊이 넣어 짧은 초를 굴려 꺼냈다. 심지가 살아 있다.",
            reward: .item(.candleStub),
            flags: [Flags.candleStubTaken],
            repeatText: "쥐구멍 안은 이제 깨끗하다."
        ),
        SearchSpot(
            id: "attic.toyShelfCrane",
            room: .atticToyCloset,
            label: "장난감 선반 끝",
            glyph: "🕊",
            position: ScenePoint(0.94, 0.28),
            odds: [0.30, 0.55, 0.80, 1.0],
            observations: [
                "선반 끝은 먼지로 덮여 있어 무엇이 앉아 있는지 분간이 안 된다.",
                "먼지를 쓸어 내자 종이 냄새가 난다. 접힌 날개 같은 것이 손등을 스쳤다."
            ],
            foundText: "선반 끝에 먼지를 쓴 채 앉아 있던 종이학을 조심히 집어 올렸다.",
            reward: .collectible(.craneToyShelf),
            repeatText: "선반 끝은 거미줄만 남아 있다."
        ),
        SearchSpot(
            id: "attic.curtainCrane",
            room: .atticMoonWindow,
            label: "커튼 주름",
            glyph: "🕊",
            position: ScenePoint(0.14, 0.56),
            requires: [.flag(Flags.readCurtainNote)],
            blocked: "커튼 주름에 무언가 끼어 있는지는 모르겠다. 커튼을 먼저 살펴보자.",
            odds: [0.30, 0.55, 0.80, 1.0],
            observations: [
                "커튼 주름을 한 겸씩 들춰도 바스락거리는 소리뿐이다.",
                "주름 사이에 바람이 고여 있다. 달빛이 비치는 자리가 한 군데 유난히 밝다."
            ],
            foundText: "커튼 주름 사이에 끼어 있던 종이학을 꺼냈다. 달빛에 날개가 반투명하게 빛난다.",
            reward: .collectible(.craneMoonWindow),
            repeatText: "커튼 주름은 이제 반듯이 펴져 있다."
        )
    ]

    static let hints: [Hint] = [
        Hint(
            id: "attic.progress.1",
            stage: .attic,
            doneIf: .flag(Flags.horseRocked),
            levelOne: "계단참 바닥의 목마가 심심해 보인다. 무언가 떨어질 것 같기도 하고.",
            levelTwo: "목마를 쓰다듬어 흔들어 보자. 안장 밑에서 열쇠 조각이 떨어진다."
        ),
        Hint(
            id: "attic.progress.2",
            stage: .attic,
            doneIf: .flag(Flags.owlAwake),
            levelOne: "잠든 부엉이 시계지기를 깨울 방법이 필요하다. 소리라면 좋겠다.",
            levelTwo: "목마의 삐걱 소리가 나면 부엉이가 눈을 뜬다. 그 뒤 서랍을 확인하자."
        ),
        Hint(
            id: "attic.progress.3",
            stage: .attic,
            doneIf: .flag(Flags.paperSheetTaken),
            levelOne: "종이를 접으려면 접을 종이가 먼저 필요하다. 높은 곳을 살펴보자.",
            levelTwo: "모모로 바꾼 뒤 계단참 오른쪽의 높은 선반을 여러 번 더듬어 보자. 한 번에 안 나와도 세 번 안에는 상자 틈에서 도면이 나온다."
        ),
        Hint(
            id: "attic.progress.4",
            stage: .attic,
            doneIf: .flag(Flags.origamiMoon),
            levelOne: "장난감 창고에 종이접기 책상이 있다. 모모의 손이라면 접을 수 있다.",
            levelTwo: "주머니의 종이 도면을 든 채 책상을 누르고, 귀 모으기 → 아래로 접기 → 가운데 누르기 → 달 모양 펴기 순서로 접자."
        ),
        Hint(
            id: "attic.progress.5",
            stage: .attic,
            doneIf: .flag(Flags.candleStubTaken),
            levelOne: "등불에 불을 붙일 것이 필요하다. 작은 것은 좁은 곳에 숨어 있다.",
            levelTwo: "피코로 바꾼 뒤 장난감 창고 구석의 쥐구멍을 여러 번 더듬어 보자. 다섯 번 안에는 짧은 초가 굴러나온다."
        ),
        Hint(
            id: "attic.progress.6",
            stage: .attic,
            doneIf: .flag(Flags.lampLit),
            levelOne: "종이달 등불은 아직 비어 있다. 초와 합쳐 보자.",
            levelTwo: "주머니에서 종이달 등불과 짧은 초를 차례로 눌러 합치면 켜진 등불이 된다."
        ),
        Hint(
            id: "attic.progress.7",
            stage: .attic,
            doneIf: .flag(Flags.toyBoxOpen),
            levelOne: "장난감 창고 벽의 그림을 자세히 보자. 색 순서가 적혀 있다.",
            levelTwo: "로즈, 세이지, 버터, 라벤더 순서대로 블록을 놓으면 상자가 열린다."
        ),
        Hint(
            id: "attic.progress.8",
            stage: .attic,
            doneIf: .flag(Flags.keyMended),
            levelOne: "열쇠가 두 동강 났다. 붙일 것이 필요하다.",
            levelTwo: "인벤토리에서 두 조각을 합치고, 다시 접착제와 합쳐 보자."
        ),
        Hint(
            id: "attic.progress.9",
            stage: .attic,
            doneIf: .cleared(.attic),
            levelOne: "이제 창가로 갈 차례. 눈에 밟히는 잠금 장치가 있다.",
            levelTwo: "켜진 종이달 등불을 든 채, 종이달 창의 녹슨 걸쇠에 이어 붙인 열쇠를 골라 써 보자."
        )
    ]

    static let stage = Stage(
        id: .attic,
        number: 1,
        title: "삐걱이는 장난감 다락방",
        subtitle: "비 오는 토요일의 시작",
        rooms: [.atticLanding, .atticToyCloset, .atticMoonWindow],
        opening: "비 오는 토요일 오후, 다락방 문이 삐걱 열렸다. 종이로 접은 달이 빛나고, 바닥의 장난감들이 하나둘 고개를 들었다.",
        closing: "종이달이 창을 가득 채웠다. 창틀 아래로 달빛이 종잇장 같은 길을 놓았고, 모모와 고양이 피코는 그 위로 조심조심 발을 내디뎠다. 다음은 거꾸로 자라는 온실.",
        next: .greenhouse
    )
}
