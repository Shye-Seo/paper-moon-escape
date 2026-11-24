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
                .say(.pico("종이학이 날개를 파닥이며 인사하고 창밖으로 사라졌어."))
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
                    text: "이어 붙인 열쇠가 걸쇠 틈에서 딸깍, 돌아갔다. 창이 스르르 열린다.",
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
            doneIf: .flag(Flags.toyBoxOpen),
            levelOne: "장난감 창고 벽의 그림을 자세히 보자. 색 순서가 적혀 있다.",
            levelTwo: "로즈, 세이지, 버터, 라벤더 순서대로 블록을 놓으면 상자가 열린다."
        ),
        Hint(
            id: "attic.progress.4",
            stage: .attic,
            doneIf: .flag(Flags.keyMended),
            levelOne: "열쇠가 두 동강 났다. 붙일 것이 필요하다.",
            levelTwo: "인벤토리에서 두 조각을 합치고, 다시 접착제와 합쳐 보자."
        ),
        Hint(
            id: "attic.progress.5",
            stage: .attic,
            doneIf: .cleared(.attic),
            levelOne: "이제 창가로 갈 차례. 눈에 밟히는 잠금 장치가 있다.",
            levelTwo: "종이달 창의 녹슨 걸쇠에 이어 붙인 열쇠를 골라 써 보자."
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
