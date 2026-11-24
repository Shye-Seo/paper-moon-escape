import Foundation

/// 보너스 4장면 · 비밀 다락방 지하실.
///
/// 본편을 끝낸 뒤에만 열리고, 「비밀 다락방 지하실」 상품으로 잠금이 풀린다.
/// 본편과 같은 규칙(지점·아이템·조합·퍼즐) 위에 종이접기·빛 투과 퍼즐이 한 번씩 더 나오고,
/// 지하실만의 엔딩이 따로 있다.
enum CellarStage {
    static let id = StageID.cellar

    static let rooms: [Room] = [
        Room(
            id: .cellarSteps,
            stage: .cellar,
            title: "지하실 계단",
            caption: "삐걱이는 나무 계단이 이어지는 지하",
            art: .cellarStairs
        ),
        Room(
            id: .cellarPantry,
            stage: .cellar,
            title: "포도주 창고",
            caption: "빈 병과 오래된 양피지 냄새가 가득한 방",
            art: .cellarPantry,
            lock: Lock(
                .flag(Flags.cellarGateOpen),
                message: "철문이 굳게 닫혀 있다. 손잡이가 빠진 철문이다."
            )
        ),
        Room(
            id: .cellarVault,
            stage: .cellar,
            title: "종이달 금고",
            caption: "달 모양 금고가 놓인 마지막 방",
            art: .cellarVault,
            lock: Lock(
                .flag(Flags.vaultCodeSeen),
                message: "금고 방 문에 암호 자물쇠가 걸려 있다. 라벨의 암호를 먼저 읽어야 한다."
            )
        )
    ]

    /// 양피지를 접어 종이배를 만든다.
    static let boatPuzzle = Puzzle(
        id: .cellarBoat,
        kind: .origami,
        title: "양피지 배 접기",
        prompt: "물에 닿아도 잠깐은 뜨는 종이배를 접어라",
        clue: "양피지 접힌 자국: 반듯이 접고 → 귀를 세우고 → 밑을 벌려 → 지붕을 눌러 내려 접기",
        tokens: [
            PuzzleToken(value: 0, label: "반듯이 접기", symbol: "📃"),
            PuzzleToken(value: 1, label: "귀 세우기", symbol: "⛵"),
            PuzzleToken(value: 2, label: "밑 벌리기", symbol: "🔽"),
            PuzzleToken(value: 3, label: "지붕 내려 접기", symbol: "🚤")
        ],
        solution: [1, 3, 0, 2],
        slotLabels: ["첫 접기", "둘째 접기", "셋째 접기", "마지막 접기"],
        successText: "양피지가 배 모양으로 접혔다. 두꺼운 종이라 물에 조금 뜰 것 같다.",
        retryText: "양피지가 접히다 말려 옆으로 찢어졌다. 접힌 자국을 다시 보자.",
        rewards: [
            .take(.vellumPage),
            .flag(Flags.boatFolded),
            .give(.paperBoat),
            .react(.momo, "⛵"),
            .say(.narration("접은 종이배를 손바닥에 올렸다. 물에 띄우면 열쇠를 건질 수 있겠다."))
        ],
        goal: "종이배",
        resetText: "양피지가 접힌 자리에서 탁 풀려 다시 한 장이 되었다. 첫 접기부터 다시 해야 한다."
    )

    /// 포도주 라벨의 찢긴 종이를 맞추고 기름등잔 빛으로 금고 암호를 읽는다.
    static let vaultPuzzle = Puzzle(
        id: .cellarVaultCode,
        kind: .lightReveal,
        title: "포도주 라벨의 암호",
        prompt: "찢어진 라벨 조각을 맞추고, 기름등잔 빛을 비춰 금고 암호를 읽어라",
        clue: "라벨의 포도 덩굴 그림은 오른쪽 위에서 왼쪽 아래로 흐른다.",
        tokens: [
            PuzzleToken(value: 0, label: "포도 조각", symbol: "🍇"),
            PuzzleToken(value: 1, label: "나뭇잎 조각", symbol: "🍃"),
            PuzzleToken(value: 2, label: "봉랍 조각", symbol: "🕯"),
            PuzzleToken(value: 3, label: "이름표 조각", symbol: "🏷")
        ],
        solution: [3, 1, 0, 2],
        slotLabels: ["왼쪽 위", "오른쪽 위", "왼쪽 아래", "오른쪽 아래"],
        successText: "라벨이 이어지자 등잔 빛이 종이를 통과해 금고 암호가 떠올랐다.",
        retryText: "포도 덩굴이 끊어져 암호가 보이지 않는다. 조각의 흐름을 다시 보자.",
        rewards: [
            .flag(Flags.vaultCodeSeen),
            .react(.pico, "🔍"),
            .say(.narration("숨은 암호: '세 번 돌리고 두 번 멈춘다. 달이 문이 된다.'"))
        ],
        goal: "금고 암호",
        revealedCode: "세 번 돌리고, 두 번 멈춘다",
        lightSource: .oilLamp
    )

    static let hotspots: [Hotspot] = [
        // 지하실 계단
        Hotspot(
            id: .oilLampHook,
            room: .cellarSteps,
            label: "벽 고리",
            glyph: "🪔",
            position: ScenePoint(0.82, 0.26),
            requiredCharacter: .momo,
            characterNote: "고리가 높이 달려 있다. 피코가 뛰어도 닿지 않으니 모모가 맡자.",
            effects: [
                .react(.momo, "🪔"),
                .say(.narration("벽 고리에 작은 기름등잔이 걸려 있었다. 흔들자 심지에 기름이 남아 있는 게 보인다.")),
                .give(.oilLamp)
            ],
            repeatText: "벽 고리만 덩그러니 남아 있다."
        ),
        Hotspot(
            id: .ironGateLatch,
            room: .cellarSteps,
            label: "철문 손잡이 자리",
            glyph: "🚪",
            position: ScenePoint(0.48, 0.56),
            effects: [
                .say(.narration("철문 손잡이가 통째로 빠져 있다. 네모난 자국만 남았다. 안쪽에 끼울 쇠가 필요하다."))
            ],
            itemReactions: [
                ItemReaction(
                    item: .rustyHandle,
                    consume: true,
                    text: "녹슨 손잡이를 네모난 자국에 밀어 넣자, 철문이 무거운 소리를 내며 안쪽으로 열렸다.",
                    effects: [
                        .flag(Flags.cellarGateOpen),
                        .react(.momo, "😲"),
                        .say(.narration("문 너머로 포도주 창고가 보인다. 오래된 종이와 먼지 냄새가 훅 끼친다."))
                    ]
                )
            ],
            mismatchText: "손잡이 자리는 네모난데, 넣을 것이 없다."
        ),
        Hotspot(
            id: .cellarSign,
            room: .cellarSteps,
            label: "지하실 표지",
            glyph: "🪧",
            position: ScenePoint(0.70, 0.74),
            effects: [
                .say(.narration("손으로 쓴 표지: '달이 문이 되는 방. 열쇠는 물 위에 뜬다.' 아래에 작게 '접어서 띄워 보세요'라고 적혀 있다."))
            ]
        ),

        // 포도주 창고
        Hotspot(
            id: .paperCrate,
            room: .cellarPantry,
            label: "양피지 상자",
            glyph: "📦",
            position: ScenePoint(0.30, 0.72),
            requiredCharacter: .momo,
            characterNote: "상자 뚜껑이 무겁게 눌려 있다. 모모의 힘이 필요하겠다.",
            effects: [
                .react(.momo, "📃"),
                .say(.narration("뚜껑을 열자 두꺼운 양피지가 한 장 접힌 채 들어 있었다. 접힌 자국이 배 모양을 닮았다.")),
                .give(.vellumPage),
                .flag(Flags.vellumTaken)
            ],
            repeatText: "상자 안에는 부스러기만 남아 있다."
        ),
        Hotspot(
            id: .foldingStool,
            room: .cellarPantry,
            label: "접이 의자",
            glyph: "🪑",
            position: ScenePoint(0.62, 0.58),
            requires: [.item(.vellumPage)],
            blocked: "의자 위에 무언가를 펼쳐 놓을 자리가 비어 있다. 접을 종이가 필요하다.",
            requiredCharacter: .momo,
            characterNote: "종이접기는 모모의 손이 필요하다. 피코의 앞발로는 양피지가 찢어질 것 같다.",
            effects: [
                .say(.narration("의자에 양피지를 펼쳤다. 접힌 자국이 길을 알려 준다.")),
                .openPuzzle(.cellarBoat)
            ],
            itemReactions: [
                ItemReaction(
                    item: .vellumPage,
                    consume: false,
                    text: "양피지를 의자에 펼쳤다. 접힌 자국이 순서를 알려 준다.",
                    effects: [.openPuzzle(.cellarBoat)]
                )
            ],
            hiddenWhen: [.flag(Flags.boatFolded)],
            repeatText: "의자 위에는 이미 접힌 배가 놓여 있다."
        ),
        Hotspot(
            id: .tornLabel,
            room: .cellarPantry,
            label: "찢어진 라벨",
            glyph: "🏷",
            position: ScenePoint(0.18, 0.34),
            requires: [.item(.oilLamp)],
            blocked: "라벨이 어두워 조각이 보이지 않는다. 빛을 비출 것이 필요하다.",
            requiredCharacter: .pico,
            characterNote: "라벨 조각이 손톱만 하다. 발끝이 가벼운 피코가 맞출 수 있겠다.",
            effects: [
                .say(.narration("포도주 병에 붙은 라벨이 찢어져 있다. 조각을 맞추고 뒤에서 등잔을 비추면 무언가 보일 것 같다.")),
                .openPuzzle(.cellarVaultCode)
            ],
            itemReactions: [
                ItemReaction(
                    item: .oilLamp,
                    consume: false,
                    text: "기름등잔을 라벨 뒤로 대자 찢긴 가장자리가 밝게 드러났다.",
                    effects: [.openPuzzle(.cellarVaultCode)]
                )
            ],
            hiddenWhen: [.flag(Flags.vaultCodeSeen)],
            repeatText: "라벨은 이미 제자리에 맞춰져 있다."
        ),
        Hotspot(
            id: .floodedDrain,
            room: .cellarPantry,
            label: "물 고인 바닥",
            glyph: "💧",
            position: ScenePoint(0.84, 0.82),
            effects: [
                .say(.narration("바닥에 물이 고여 있다. 그 아래로 무언가 반짝이지만 손이 닿지 않는다. 물 위에 띄울 것이 필요하겠다."))
            ],
            itemReactions: [
                ItemReaction(
                    item: .paperBoat,
                    consume: true,
                    text: "종이배를 물에 띄우자 배가 반짝이는 곳으로 미끄러져 갔다. 배가 무거워지더니 작은 열쇠를 싣고 돌아왔다.",
                    effects: [
                        .flag(Flags.vaultKeyTaken),
                        .give(.vaultKey),
                        .react(.pico, "🗝"),
                        .say(.narration("물에서 건진 열쇠는 작고 무거웠다. 금고에 맞을 것 같다."))
                    ]
                )
            ],
            mismatchText: "물이 고여 있어 손이 닿지 않는다. 물 위에 띄울 만한 것이 필요하다."
        ),
        Hotspot(
            id: .wineRack,
            room: .cellarPantry,
            label: "포도주 선반",
            glyph: "🍷",
            position: ScenePoint(0.44, 0.22),
            effects: [
                .say(.narration("먼지 앉은 병들이 누워 있다. 라벨마다 같은 달 그림이 찍혀 있고, 하나만 라벨이 찢겨 있다."))
            ]
        ),

        // 종이달 금고
        Hotspot(
            id: .moonVault,
            room: .cellarVault,
            label: "종이달 금고",
            glyph: "🗄",
            position: ScenePoint(0.50, 0.44),
            effects: [
                .say(.narration("달 모양 손잡이가 달린 금고다. 열쇠 구멍이 작고 둥글다. 암호판도 함께 붙어 있다."))
            ],
            itemReactions: [
                ItemReaction(
                    item: .vaultKey,
                    consume: true,
                    text: "열쇠를 세 번 돌리고 두 번 멈추자, 금고 문이 달빛처럼 스르르 열렸다.",
                    effects: [
                        .react(.momo, "🌙"),
                        .say(.narration("금고 안에는 종이로 접은 작은 다락방이 들어 있었다. 지붕 위에 모모와 피코가 나란히 앉아 있다.")),
                        .clearStage
                    ]
                )
            ],
            mismatchText: "열쇠 구멍은 작고 둥글다. 맞는 열쇠가 필요하다."
        ),
        Hotspot(
            id: .oldAlbum,
            room: .cellarVault,
            label: "오래된 앨범",
            glyph: "📔",
            position: ScenePoint(0.22, 0.70),
            requiredCharacter: .pico,
            characterNote: "앨범이 낮은 선반 깊숙이 꽂혀 있다. 작은 발이 닿는 피코가 꺼내자.",
            effects: [
                .react(.pico, "😌"),
                .say(.pico("앨범에 우리 다락방 사진이 있어. 아주 오래전, 같은 종이달 아래에서 찍은 것 같아."))
            ],
            repeatText: "앨범은 펼쳐진 채 놓여 있다."
        ),
        Hotspot(
            id: .vaultLedger,
            room: .cellarVault,
            label: "금고 장부",
            glyph: "📕",
            position: ScenePoint(0.78, 0.66),
            requiredCharacter: .momo,
            characterNote: "장부가 높은 책상 위에 놓여 있다. 모모가 닦아 내야 읽을 수 있겠다.",
            effects: [
                .say(.narration("책상 위 장부에 먼지가 두껍게 앉아 있다. 손으로 문질러 닦으면 마지막 장이 읽힐 것 같다.")),
                .openDust("cellar.ledger")
            ],
            hiddenWhen: [.flag(Flags.cellarLedgerRead)],
            repeatText: "장부는 이미 펼쳐져 있다."
        )
    ]

    static let searchSpots: [SearchSpot] = [
        SearchSpot(
            id: "cellar.brickNook",
            room: .cellarSteps,
            label: "벽돌 틈",
            glyph: "🧱",
            position: ScenePoint(0.12, 0.80),
            requiredCharacter: .pico,
            characterNote: "벽돌 틈이 손가락 하나만큼 벌어져 있다. 피코라면 앞발을 넣을 수 있겠다.",
            odds: [0.40, 0.70, 1.0],
            observations: [
                "벽돌 틈은 손가락 하나만큼 벌어져 있다. 앞발을 넣어도 먼지와 서늘한 이끼만 묻는다.",
                "틈 안쪽에 쇠 냄새가 난다. 손목을 비틀면 닿을 것 같다."
            ],
            foundText: "틈 안에 끼어 있던 녹슨 손잡이를 뺐다. 철문 손잡이 자리에 맞을 것 같다.",
            reward: .item(.rustyHandle),
            repeatText: "벽돌 틈은 이제 텅 비어 있다."
        )
    ]

    static let hints: [Hint] = [
        Hint(
            id: "cellar.progress.1",
            stage: .cellar,
            doneIf: .flag(Flags.cellarGateOpen),
            levelOne: "철문 손잡이가 통째로 빠져 있다. 안쪽에 끼울 쇠가 어딘가에 있을 것이다.",
            levelTwo: "피코로 바꿔 지하실 계단 왼쪽 아래의 벽돌 틈을 여러 번 더듬어 녹슨 손잡이를 꺼내고, 철문 손잡이 자리에 끼우자."
        ),
        Hint(
            id: "cellar.progress.2",
            stage: .cellar,
            doneIf: .flag(Flags.boatFolded),
            levelOne: "물 위에 띄울 것이 필요하다. 창고의 나무 상자와 접이 의자를 보자.",
            levelTwo: "모모로 양피지 상자를 열어 양피지를 얻고, 접이 의자에서 귀 세우기 → 지붕 내려 접기 → 반듯이 접기 → 밑 벌리기 순서로 접자."
        ),
        Hint(
            id: "cellar.progress.3",
            stage: .cellar,
            doneIf: .flag(Flags.vaultCodeSeen),
            levelOne: "금고 방 문에는 암호 자물쇠가 있다. 창고의 찢어진 라벨이 암호를 감추고 있다.",
            levelTwo: "기름등잔을 든 채 피코로 바꿔 라벨을 누르고, 이름표 → 나뭇잎 → 포도 → 봉랍 순서로 조각을 맞춘 뒤 등잔을 비추자."
        ),
        Hint(
            id: "cellar.progress.4",
            stage: .cellar,
            doneIf: .flag(Flags.vaultKeyTaken),
            levelOne: "물 고인 바닥 아래에 무언가 반짝인다. 띄울 것이 있으면 건질 수 있다.",
            levelTwo: "주머니의 접은 종이배를 골라 물 고인 바닥에 사용하면 열쇠가 올라온다."
        ),
        Hint(
            id: "cellar.progress.5",
            stage: .cellar,
            doneIf: .flag(Flags.cellarLedgerRead),
            levelOne: "금고 장부에 먼지가 두껍다. 모모가 손으로 닦아 볼 수 있다.",
            levelTwo: "모모로 금고 장부를 누르고 화면을 문질러 닦으면 마지막 장이 읽힌다."
        ),
        Hint(
            id: "cellar.progress.6",
            stage: .cellar,
            doneIf: .cleared(.cellar),
            levelOne: "금고 방까지 왔다. 손에 열쇠가 있다면 문 앞에서 쓰면 된다.",
            levelTwo: "종이달 금고를 누른 채 금고 열쇠를 골라 쓰자. 지하실의 마지막 이야기가 열린다."
        )
    ]

    static let stage = Stage(
        id: .cellar,
        number: 4,
        title: "비밀 다락방 지하실",
        subtitle: "보너스 장면 · 달이 문이 되는 방",
        rooms: [.cellarSteps, .cellarPantry, .cellarVault],
        opening: "다락방 벽판을 밀자 낡은 계단이 아래로 이어졌다. 종이 냄새와 먼지, 그리고 아주 오래된 달빛이 계단 끝에서 기다리고 있다.",
        closing: "금고 안의 종이 다락방을 꺼내자, 지하실 벽이 종잇장처럼 접히며 위층 다락방과 이어졌다. 모모와 피코는 나란히 계단을 올라갔다. 이제 이 집의 지도에는 지하실도 한 칸 더 그려져 있다.",
        next: nil,
        isBonus: true
    )
}
