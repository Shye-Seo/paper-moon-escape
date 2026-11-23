import Foundation

/// 손에 쥐는 물건들. 이름과 설명은 화면의 인벤토리와 획득 대사에 함께 쓰인다.
enum ItemCatalog {
    static let all: [Item] = [
        Item(id: .keyShardOval, name: "달걀 모양 열쇠 조각", glyph: "🗝", note: "한쪽 끝이 달걀처럼 둥글게 깎인 열쇠 조각."),
        Item(id: .keyShardTooth, name: "톱니 열쇠 조각", glyph: "🦷", note: "톱니처럼 이가 패인 열쇠 조각. 다른 조각과 맞물릴 것 같다."),
        Item(id: .brokenKey, name: "부러진 열쇠", glyph: "🔑", note: "두 조각을 맞댔지만 틈이 벌어져 있다."),
        Item(id: .glueBottle, name: "접착제 통", glyph: "🧴", note: "뚜껑이 굳어 꾹 눌러야 열리는 접착제."),
        Item(id: .mendedKey, name: "이어 붙인 열쇠", glyph: "🔐", note: "접착제로 튼튼하게 이어 붙인 열쇠."),

        Item(id: .seed, name: "반짝이는 씨앗", glyph: "🌰", note: "손바닥에서 작게 맥박치는 씨앗."),
        Item(id: .wateringCan, name: "낡은 물뿌리개", glyph: "🚿", note: "안이 비어 있는 물뿌리개."),
        Item(id: .emptyJar, name: "맑은 유리병", glyph: "🫙", note: "뚜껑이 달린 유리병. 무언가 담으면 빛날 것 같다."),
        Item(id: .firefly, name: "반딧불이", glyph: "✨", note: "손끝에서 따뜻하게 반짝이는 불빛."),
        Item(id: .lantern, name: "반딧불이 랜턴", glyph: "🏮", note: "유리병 가득 반딧불이 빛이 찬 랜턴."),
        Item(id: .paperMoonShard, name: "종이달 조각", glyph: "🌙", note: "잘린 종이달의 가장자리 조각."),

        Item(id: .windKey, name: "태엽 열쇠", glyph: "🔧", note: "손때가 묻어 반들반들한 태엽 열쇠."),
        Item(id: .gear, name: "작은 톱니바퀴", glyph: "⚙️", note: "이빨이 고른 작은 톱니바퀴."),
        Item(id: .clockPart, name: "시계 부품", glyph: "🧰", note: "태엽 열쇠와 톱니를 맞물려 만든 부품.")
    ]
}

/// 아이템 조합 규칙. 순서는 상관없다.
enum ComboCatalog {
    static let all: [Combo] = [
        Combo(
            a: .keyShardOval,
            b: .keyShardTooth,
            result: .brokenKey,
            text: "두 조각을 맞대자 열쇠 모양이 되었다. 하지만 틈이 벌어져 힘을 주면 부러질 것 같다."
        ),
        Combo(
            a: .brokenKey,
            b: .glueBottle,
            result: .mendedKey,
            text: "끈적한 접착제를 틈에 바르자 서서히 굳으며 튼튼한 열쇠가 되었다.",
            flag: Flags.keyMended
        ),
        Combo(
            a: .emptyJar,
            b: .firefly,
            result: .lantern,
            text: "반딧불이를 유리병에 넣자 병이 따뜻한 빛으로 가득 찼다."
        ),
        Combo(
            a: .windKey,
            b: .gear,
            result: .clockPart,
            text: "태엽 열쇠에 작은 톱니를 맞물려 시계 부품을 만들었다."
        )
    ]
}
