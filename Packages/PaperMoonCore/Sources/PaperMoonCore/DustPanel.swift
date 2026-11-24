import Foundation

/// 먼지 쌓인 거울·유리·명판 하나. 지점에서 이 패널을 열면 화면이 먼지로 덮이고,
/// 문지르거나 흔들어 닦으면 아래 `revealText`가 드러난다.
public struct DustPanel: Identifiable, Equatable, Sendable {
    public let id: String
    public let room: RoomID
    public let title: String
    public let prompt: String
    public let revealText: String
    public let columns: Int
    public let rows: Int
    /// 다 닦였다고 볼 먼지 제거 비율(0...1).
    public let threshold: Double
    /// 다 닦은 뒤에 일어나는 일. 플래그·대사·아이템 모두 가능하다.
    public let effects: [Effect]
    /// 이미 닦아 낸 판인지 확인하는 조건.
    public let doneIf: [Requirement]

    public init(
        id: String,
        room: RoomID,
        title: String,
        prompt: String,
        revealText: String,
        columns: Int = 10,
        rows: Int = 8,
        threshold: Double = 0.72,
        effects: [Effect],
        doneIf: [Requirement] = []
    ) {
        self.id = id
        self.room = room
        self.title = title
        self.prompt = prompt
        self.revealText = revealText
        self.columns = columns
        self.rows = rows
        self.threshold = threshold
        self.effects = effects
        self.doneIf = doneIf
    }
}

/// 손가락으로 문지르는 먼지 닦기 판. 순수한 값이라 테스트가 그대로 돌려 볼 수 있다.
///
/// 시뮬레이터나 손을 쓰기 어려운 환경에서는 화면의 '대신 닦아 주기' 버튼이
/// `wipeAll()`을 부르고, 기기를 흔들면 `shake()`가 같은 일을 조금씩 한다.
public struct DustWipePuzzle: Equatable, Sendable {
    public let columns: Int
    public let rows: Int
    public let threshold: Double
    public let revealText: String
    /// 칸마다 남은 먼지(1 = 새것, 0 = 닦임).
    public private(set) var dirt: [Double]

    public init(
        columns: Int = 10,
        rows: Int = 8,
        threshold: Double = 0.72,
        revealText: String = ""
    ) {
        self.columns = max(2, columns)
        self.rows = max(2, rows)
        self.threshold = threshold
        self.revealText = revealText
        self.dirt = Array(repeating: 1.0, count: self.columns * self.rows)
    }

    public init(panel: DustPanel) {
        self.init(
            columns: panel.columns,
            rows: panel.rows,
            threshold: panel.threshold,
            revealText: panel.revealText
        )
    }

    public var cellCount: Int { columns * rows }

    /// 닦인 비율(0...1). 1에 가까울수록 깨끗하다.
    public var clearedRatio: Double {
        guard !dirt.isEmpty else { return 1 }
        let total = dirt.reduce(0, +)
        return 1 - total / Double(dirt.count)
    }

    public var isCleared: Bool { clearedRatio >= threshold }

    /// 깨끗해진 칸의 비율을 백분율 정수로. 화면 게이지에 쓴다.
    public var percent: Int { Int((clearedRatio * 100).rounded()) }

    public func dust(column: Int, row: Int) -> Double {
        guard column >= 0, column < columns, row >= 0, row < rows else { return 0 }
        return dirt[row * columns + column]
    }

    /// 정규화 좌표(0...1)를 문지른다. 닦였으면 true.
    @discardableResult
    public mutating func wipe(at point: ScenePoint, radius: Double = 0.12) -> Bool {
        guard !isCleared else { return true }
        let reach = max(0.01, radius)
        for row in 0..<rows {
            for column in 0..<columns {
                let centerX = (Double(column) + 0.5) / Double(columns)
                let centerY = (Double(row) + 0.5) / Double(rows)
                let dx = centerX - point.x
                let dy = centerY - point.y
                let distance = (dx * dx + dy * dy).squareRoot()
                guard distance <= reach else { continue }
                let strength = 0.88 * (1 - distance / reach)
                let index = row * columns + column
                dirt[index] = max(0, dirt[index] - strength)
            }
        }
        return isCleared
    }

    /// 기기를 흔들었을 때의 한 번의 타격. 문지르기보다 약하게 전체를 턴다.
    @discardableResult
    public mutating func shake(strength: Double = 1.0) -> Bool {
        guard !isCleared else { return true }
        let amount = 0.09 * max(0.1, strength)
        for index in dirt.indices {
            dirt[index] = max(0, dirt[index] - amount)
        }
        return isCleared
    }

    /// 손을 쓸 수 없을 때의 대안. 한 번에 전부 닦는다.
    @discardableResult
    public mutating func wipeAll() -> Bool {
        for index in dirt.indices {
            dirt[index] = 0
        }
        return true
    }
}
