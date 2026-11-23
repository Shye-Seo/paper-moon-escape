import Foundation

/// 세 스테이지를 하나의 세계로 묶는 조립 지점.
public enum PaperMoonWorld {
    public static func build() -> World {
        World(
            stages: [AtticStage.stage, GreenhouseStage.stage, ClocktowerStage.stage],
            rooms: AtticStage.rooms + GreenhouseStage.rooms + ClocktowerStage.rooms,
            items: ItemCatalog.all,
            hotspots: AtticStage.hotspots + GreenhouseStage.hotspots + ClocktowerStage.hotspots,
            puzzles: [AtticStage.puzzle, GreenhouseStage.puzzle, ClocktowerStage.puzzle],
            combos: ComboCatalog.all,
            hints: AtticStage.hints + GreenhouseStage.hints + ClocktowerStage.hints
        )
    }
}
