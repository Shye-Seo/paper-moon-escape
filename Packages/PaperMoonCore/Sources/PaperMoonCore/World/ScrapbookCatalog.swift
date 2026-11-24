import Foundation

/// 본편 9개 방 곳곳에 숨겨 둔 수집품 목록.
/// 종이학 12마리를 다 모으면 엔딩 뒤 다락방 비밀 서랍이 열리고,
/// 옛날 우표 3장은 모으지 않아도 손해가 없는 곁다리 기록이다.
enum ScrapbookCatalog {
    static let all: [Collectible] = [
        // ── 1장면 · 삐걱이는 장난감 다락방
        Collectible(
            id: .craneAtticLanding,
            room: .atticLanding,
            label: "창틀의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.42, 0.14),
            memory: "창틀에 걸린 종이학. 접힌 날개 안쪽에 '오늘은 비가 와서 좋다'라고 연필로 적혀 있었다."
        ),
        Collectible(
            id: .craneAtticLadder,
            room: .atticLanding,
            label: "사다리 밑의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.06, 0.26),
            memory: "사다리 발치에 떨어진 종이학. 다리 하나가 바깥으로 삐죽 나와 있다. 급하게 접은 것 같다."
        ),
        Collectible(
            id: .stampAttic,
            room: .atticLanding,
            label: "옛날 우표 한 장",
            glyph: "🏷",
            position: ScenePoint(0.92, 0.80),
            memory: "바닥 틈에 끼어 있던 우표. 종이달이 인쇄된, 아주 오래된 다락방 우표다."
        ),
        Collectible(
            id: .craneToyCloset,
            room: .atticToyCloset,
            label: "벽 그림 뒤의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.30, 0.12),
            memory: "벽 그림 뒤에 숨은 종이학. 누군가 이 방에서 처음 접은 종이학인지 날개가 투박하다."
        ),
        Collectible(
            id: .craneToyShelf,
            room: .atticToyCloset,
            label: "선반 끝의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.94, 0.28),
            memory: "장난감 선반 끝에 앉은 종이학. 태엽 인형들을 바라보는 방향으로 고개가 접혀 있다."
        ),
        Collectible(
            id: .craneMoonWindow,
            room: .atticMoonWindow,
            label: "커튼 사이의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.14, 0.56),
            memory: "커튼 사이에 끼어 있던 종이학. 달빛에 비치면 날개가 반투명하게 빛난다."
        ),

        // ── 2장면 · 거꾸로 자라는 온실
        Collectible(
            id: .craneVines,
            room: .greenhouseVines,
            label: "덩굴에 걸린 종이학",
            glyph: "🕊",
            position: ScenePoint(0.06, 0.34),
            memory: "덩굴에 매달린 종이학. 물을 머금어 날개가 조금 불었다. 말리면 다시 접을 수 있을 것 같다."
        ),
        Collectible(
            id: .stampGreenhouse,
            room: .greenhouseVines,
            label: "표지판 뒤의 우표",
            glyph: "🏷",
            position: ScenePoint(0.52, 0.92),
            memory: "표지판 못에 붙어 있던 우표. 개구리 그림이 인쇄되어 있다."
        ),
        Collectible(
            id: .cranePond,
            room: .greenhousePond,
            label: "수련잎 위의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.36, 0.14),
            memory: "수련잎 위에 앉은 종이학. 물에 젖지 않으려고 잎 가운데에 정확히 놓여 있다."
        ),
        Collectible(
            id: .craneFirefly,
            room: .greenhousePond,
            label: "반딧불이 곁의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.88, 0.12),
            memory: "반딧불이가 앉았던 종이학. 어두운 방에서 아주 약하게 빛을 머금고 있다."
        ),
        Collectible(
            id: .craneGlass,
            room: .greenhouseGlass,
            label: "유리방 구석의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.44, 0.86),
            memory: "거꾸로 자라는 나무 아래의 종이학. 뿌리 쪽을 향해 날개를 펴고 있다."
        ),

        // ── 3장면 · 태엽 시계탑 꼭대기
        Collectible(
            id: .craneStairs,
            room: .towerStairs,
            label: "계단 손잡이의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.14, 0.22),
            memory: "나선 계단 난간에 얹힌 종이학. 계단을 오르내릴 때마다 조금씩 자리를 바꾼다."
        ),
        Collectible(
            id: .stampTower,
            room: .towerStairs,
            label: "상자 밑의 우표",
            glyph: "🏷",
            position: ScenePoint(0.58, 0.88),
            memory: "나무 상자 밑에서 나온 우표. 톱니바퀴가 인쇄된, 시계탑에서만 쓰던 우표다."
        ),
        Collectible(
            id: .craneGears,
            room: .towerGears,
            label: "톱니 사이의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.66, 0.18),
            memory: "톱니 사이에 끼어 있던 종이학. 톱니가 돌 때마다 날개가 살짝 떨린다."
        ),
        Collectible(
            id: .craneBelfry,
            room: .towerBelfry,
            label: "종 아래의 종이학",
            glyph: "🕊",
            position: ScenePoint(0.86, 0.74),
            memory: "종이 종 아래에 놓인 마지막 종이학. 열두 마리 중 가장 크고, 접힌 자리가 정갈하다."
        )
    ]

    static func cranes(in room: RoomID) -> [Collectible] {
        all.filter { $0.room == room && $0.kind == .crane }
    }
}
