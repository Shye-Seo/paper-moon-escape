import Foundation

/// 먼지가 두껍게 앉은 거울·장부. 손으로 문질러 닦으면 아래 글씨가 드러난다.
enum DustCatalog {
    static let all: [DustPanel] = [
        DustPanel(
            id: "tower.mirror",
            room: .towerGears,
            title: "먼지 쌓인 거울",
            prompt: "거울을 문질러 먼지를 닦아 내자",
            revealText: "먼지가 걷히자 거울 대신 유리에 글씨가 새겨져 있었다. '종 아래 홈에 달을 맞추고, 종을 울려라. 홈은 닦은 뒤에 맞춘다.'",
            columns: 10,
            rows: 8,
            threshold: 0.72,
            effects: [
                .flag(Flags.mirrorWiped),
                .react(.momo, "🪞"),
                .say(.narration("닦아 낸 유리에 손자국이 남았다. 이제 종탑의 달 홈을 맞출 수 있겠다."))
            ],
            doneIf: [.flag(Flags.mirrorWiped)]
        ),
        DustPanel(
            id: "cellar.ledger",
            room: .cellarVault,
            title: "금고 장부",
            prompt: "장부의 먼지를 닦아 마지막 장을 읽자",
            revealText: "장부 마지막 장: '지하실을 드나든 사람은 모두 다락방에서 종이학을 접었다. 열두 마리를 모으면 서랍이 열린다.'",
            columns: 9,
            rows: 7,
            threshold: 0.7,
            effects: [
                .flag(Flags.cellarLedgerRead),
                .react(.momo, "📖"),
                .say(.narration("장부 끝에 다락방 서랍 이야기가 적혀 있다. 종이학을 더 모아 볼 만하겠다."))
            ],
            doneIf: [.flag(Flags.cellarLedgerRead)]
        )
    ]
}
