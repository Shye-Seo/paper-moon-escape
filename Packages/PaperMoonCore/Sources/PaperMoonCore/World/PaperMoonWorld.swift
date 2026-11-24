import Foundation

/// 본편 세 장면과 보너스 지하실을 하나의 세계로 묶는 조립 지점.
public enum PaperMoonWorld {
    public static func build() -> World {
        World(
            stages: [
                AtticStage.stage,
                GreenhouseStage.stage,
                ClocktowerStage.stage,
                CellarStage.stage
            ],
            rooms: AtticStage.rooms
                + GreenhouseStage.rooms
                + ClocktowerStage.rooms
                + CellarStage.rooms,
            items: ItemCatalog.all,
            hotspots: AtticStage.hotspots
                + GreenhouseStage.hotspots
                + ClocktowerStage.hotspots
                + CellarStage.hotspots,
            puzzles: [
                AtticStage.puzzle,
                AtticStage.origamiPuzzle,
                GreenhouseStage.puzzle,
                GreenhouseStage.lightPuzzle,
                ClocktowerStage.puzzle,
                CellarStage.boatPuzzle,
                CellarStage.vaultPuzzle
            ],
            combos: ComboCatalog.all,
            hints: AtticStage.hints
                + GreenhouseStage.hints
                + ClocktowerStage.hints
                + CellarStage.hints,
            collectibles: ScrapbookCatalog.all,
            dustPanels: DustCatalog.all,
            searchSpots: AtticStage.searchSpots
                + GreenhouseStage.searchSpots
                + ClocktowerStage.searchSpots
                + CellarStage.searchSpots,
            secretGift: .paperMoon
        )
    }
}
