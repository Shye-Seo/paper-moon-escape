import Foundation

// MARK: - 공통

/// 엔딩 뒤에 열리는 다락방 놀이방의 두 가지 놀이.
public enum MiniGameID: String, Codable, CaseIterable, Hashable, Sendable {
    case memoryDrawer
    case origamiChallenge

    public var title: String {
        switch self {
        case .memoryDrawer: return "다락방 기억의 서랍"
        case .origamiChallenge: return "달빛 종이접기 연쇄 챌린지"
        }
    }

    public var shortSubtitle: String {
        switch self {
        case .memoryDrawer: return "뒤집은 카드에서 짝을 찾는다"
        case .origamiChallenge: return "도안을 외워 연달아 접는다"
        }
    }

    public var glyph: String {
        switch self {
        case .memoryDrawer: return "🗄"
        case .origamiChallenge: return "🪷"
        }
    }
}

/// 놀이방 난이도. 기억의 서랍은 짝 수, 종이접기는 도안 수와 실수 허용량이 달라진다.
public enum MiniGameDifficulty: String, Codable, CaseIterable, Hashable, Sendable {
    case easy
    case normal
    case hard

    public var title: String {
        switch self {
        case .easy: return "포근한 오후"
        case .normal: return "비 오는 저녁"
        case .hard: return "달이 기우는 밤"
        }
    }

    /// 기억의 서랍: 서로 맞출 짝(카드 2장) 수.
    public var memoryPairs: Int {
        switch self {
        case .easy: return 4
        case .normal: return 6
        case .hard: return 8
        }
    }

    /// 종이접기 연쇄: 이어서 접어야 하는 도안 수.
    public var chainLength: Int {
        switch self {
        case .easy: return 3
        case .normal: return 5
        case .hard: return 7
        }
    }

    /// 종이접기 연쇄: 허용되는 실수 횟수.
    public var mistakeBudget: Int {
        switch self {
        case .easy: return 3
        case .normal: return 2
        case .hard: return 1
        }
    }

    public var cardCount: Int { memoryPairs * 2 }
}

/// 기억의 서랍 카드 그림. 본편 주머니에 들어오는 물건과 같은 이름·글리프를 쓴다.
public struct MemoryFace: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let glyph: String
    public let tint: MiniGameTint

    public init(id: String, name: String, glyph: String, tint: MiniGameTint) {
        self.id = id
        self.name = name
        self.glyph = glyph
        self.tint = tint
    }
}

/// 화면 색으로 옮기는 이름만 든 팔레트 토큰. Core는 색을 모른다.
public enum MiniGameTint: String, Codable, CaseIterable, Hashable, Sendable {
    case butter
    case rose
    case sage
    case dusk
    case mauve
    case wood
    case candle
    case cloud
}

extension MemoryFace {
    /// 본편에서 만진 것들로만 짠 카드 덱. 난이도가 올라가면 앞에서부터 더 쓴다.
    public static let deck: [MemoryFace] = [
        MemoryFace(id: "crane", name: "접힌 종이학", glyph: "🕊", tint: .cloud),
        MemoryFace(id: "stamp", name: "옛날 우표", glyph: "🏷", tint: .butter),
        MemoryFace(id: "key", name: "이어 붙인 열쇠", glyph: "🔐", tint: .wood),
        MemoryFace(id: "moonLamp", name: "켜진 종이달 등불", glyph: "🌙", tint: .candle),
        MemoryFace(id: "oilLamp", name: "기름등잔", glyph: "🪔", tint: .rose),
        MemoryFace(id: "boat", name: "접은 종이배", glyph: "⛵", tint: .sage),
        MemoryFace(id: "gear", name: "작은 톱니바퀴", glyph: "⚙️", tint: .dusk),
        MemoryFace(id: "lantern", name: "반딧불이 랜턴", glyph: "🏮", tint: .mauve)
    ]

    /// 난이도에 맞는 그림만 골라 낸다.
    public static func deck(for difficulty: MiniGameDifficulty) -> [MemoryFace] {
        Array(deck.prefix(difficulty.memoryPairs))
    }
}

/// 한 장 뒤집은 결과.
public enum MemoryFlip: Equatable, Sendable {
    /// 아무 일도 일어나지 않았다(이미 짝이 맞았거나, 두 장이 열려 있거나).
    case ignored
    /// 첫 장이 열렸다.
    case revealed(index: Int)
    /// 두 장이 같은 그림이라 짝이 맞았다.
    case matched(face: MemoryFace, moves: Int)
    /// 두 장이 달라서 잠시 뒤에 다시 뒤집혀야 한다.
    case mismatched(first: Int, second: Int, moves: Int)
    /// 이미 열려 있는 카드를 다시 눌렀다.
    case alreadyFaceUp(index: Int)
}

/// 「다락방 기억의 서랍」 — 뒤집은 카드에서 짝을 맞추는 놀이.
///
/// 서랍 칸을 하나씩 열어 본다는 설정이라, 짝이 맞으면 서랍이 딸깍 하고 닫힌다.
/// `moves`는 두 장을 고른 횟수다. 짝 수만큼이면 완벽한 기록이다.
public struct MemoryDrawerGame: Equatable, Sendable {
    public let difficulty: MiniGameDifficulty
    /// 카드 순서대로의 그림. 같은 그림이 두 번씩 들어 있다.
    public private(set) var faces: [MemoryFace]
    /// 지금 앞면이 보이는 카드(짝이 아직 안 맞은 것만).
    public private(set) var faceUp: [Int]
    /// 짝이 맞아 서랍이 닫힌 카드.
    public private(set) var matched: Set<Int>
    /// 두 장을 고른 횟수.
    public private(set) var moves: Int

    public init(difficulty: MiniGameDifficulty, deck: [MemoryFace]? = nil) {
        self.difficulty = difficulty
        let source = deck ?? MemoryFace.deck(for: difficulty)
        var cards: [MemoryFace] = []
        for face in source.prefix(difficulty.memoryPairs) {
            cards.append(face)
            cards.append(face)
        }
        self.faces = cards.shuffled()
        self.faceUp = []
        self.matched = []
        self.moves = 0
    }

    /// 테스트·미리보기용: 카드 순서를 그대로 쓰는 판.
    public init(difficulty: MiniGameDifficulty, ordered faces: [MemoryFace]) {
        self.difficulty = difficulty
        self.faces = faces
        self.faceUp = []
        self.matched = []
        self.moves = 0
    }

    public var cardCount: Int { faces.count }

    public var pairCount: Int { faces.count / 2 }

    public var isFinished: Bool {
        !faces.isEmpty && matched.count == faces.count
    }

    /// 완벽한 기록. 이만큼이면 별 세 개다.
    public var perfectMoves: Int { pairCount }

    public var stars: Int {
        guard isFinished else { return 0 }
        if moves <= perfectMoves + 2 { return 3 }
        if moves <= perfectMoves + 6 { return 2 }
        return 1
    }

    public func face(at index: Int) -> MemoryFace? {
        guard index >= 0 && index < faces.count else { return nil }
        return faces[index]
    }

    public func isFaceUp(_ index: Int) -> Bool {
        faceUp.contains(index)
    }

    public func isMatched(_ index: Int) -> Bool {
        matched.contains(index)
    }

    /// 두 장이 열려 있고 아직 뒤집을 차례인지. 화면은 이동안 세 번째 카드를 막는다.
    public var needsResolve: Bool { faceUp.count >= 2 }

    /// 카드 한 장을 뒤집는다.
    @discardableResult
    public mutating func flip(_ index: Int) -> MemoryFlip {
        guard index >= 0 && index < faces.count else { return .ignored }
        if matched.contains(index) { return .ignored }
        if faceUp.contains(index) { return .alreadyFaceUp(index: index) }
        if faceUp.count >= 2 { return .ignored }
        if faceUp.isEmpty {
            faceUp = [index]
            return .revealed(index: index)
        }
        let first = faceUp[0]
        faceUp.append(index)
        moves += 1
        if faces[first].id == faces[index].id {
            let face = faces[first]
            matched.insert(first)
            matched.insert(index)
            faceUp = []
            return .matched(face: face, moves: moves)
        }
        return .mismatched(first: first, second: index, moves: moves)
    }

    /// 어긋난 두 장을 다시 뒤집는다. 실제로 뒤집혔으면 true.
    @discardableResult
    public mutating func resolveMismatch() -> Bool {
        guard faceUp.count >= 2 else { return false }
        faceUp = []
        return true
    }

    /// 서랍을 다시 닫고 새로 시작한다.
    public mutating func shuffleAgain() {
        faces = faces.shuffled()
        faceUp = []
        matched = []
        moves = 0
    }
}

// MARK: - 종이접기 연쇄

/// 본편 종이접기와 같은 네 가지 손동작. 기호도 본편 퍼즐과 같다.
public enum OrigamiFold: Int, Codable, CaseIterable, Hashable, Sendable {
    case corners = 0
    case press = 1
    case foldDown = 2
    case open = 3

    public var label: String {
        switch self {
        case .corners: return "네 귀 모으기"
        case .press: return "가운데 누르기"
        case .foldDown: return "아래로 접기"
        case .open: return "모양 펴기"
        }
    }

    public var symbol: String {
        switch self {
        case .corners: return "🔻"
        case .press: return "🔶"
        case .foldDown: return "🔹"
        case .open: return "🌙"
        }
    }
}

/// 접어서 만들 도안. 네 손동작의 순서가 다르다.
public struct OrigamiDesign: Identifiable, Equatable, Hashable, Sendable {
    public let name: String
    public let glyph: String
    public let steps: [OrigamiFold]

    public var id: String { name }

    public init(name: String, glyph: String, steps: [OrigamiFold]) {
        self.name = name
        self.glyph = glyph
        self.steps = steps
    }

    public static let all: [OrigamiDesign] = [
        OrigamiDesign(name: "종이배", glyph: "⛵", steps: [.foldDown, .press, .corners, .open]),
        OrigamiDesign(name: "종이학", glyph: "🕊", steps: [.corners, .open, .foldDown, .press]),
        OrigamiDesign(name: "종이달", glyph: "🌙", steps: [.press, .foldDown, .corners, .open]),
        OrigamiDesign(name: "종이별", glyph: "⭐", steps: [.open, .corners, .press, .foldDown])
    ]
}

/// 한 번 접은 결과.
public enum ChallengeFold: Equatable, Sendable {
    case ignored
    /// 제대로 접혔다. `remaining`은 이 도안에서 더 접어야 할 횟수.
    case accepted(placed: Int, remaining: Int)
    /// 잘못 접혀 이 도안이 처음으로 풀렸다.
    case unfolded(mistakesLeft: Int)
    /// 도안 하나를 완성했다.
    case designCompleted(completed: Int, next: OrigamiDesign?)
    /// 실수를 다 써서(또는 도안을 모두 완성해서) 끝났다.
    case finished(completed: Int, cleared: Bool)
}

/// 「달빛 종이접기 연쇄 챌린지」 — 제시된 도안을 실수 허용량 안에서 연달아 접는다.
///
/// 도안의 순서는 잠깐 보여 준 뒤 사라진다. 화면(UI)은 `currentDesign`을
/// 1.6초쯤 보여 주고 접기를 받는다. 잘못 접으면 그 도안은 처음부터 풀리고
/// 실수가 하나 줄어든다. 실수를 다 쓰면 그 자리에서 끝난다.
public struct OrigamiChallenge: Equatable, Sendable {
    public let difficulty: MiniGameDifficulty
    public private(set) var designs: [OrigamiDesign]
    public private(set) var index: Int
    public private(set) var placed: [OrigamiFold]
    public private(set) var mistakesLeft: Int
    public private(set) var completed: Int
    public private(set) var isOver: Bool

    public init(difficulty: MiniGameDifficulty, designs: [OrigamiDesign]? = nil) {
        self.difficulty = difficulty
        let pool = designs ?? OrigamiDesign.all
        var chain: [OrigamiDesign] = []
        let length = max(1, difficulty.chainLength)
        var cursor = 0
        while chain.count < length {
            chain.append(pool[cursor % pool.count])
            cursor += 1
        }
        self.designs = chain
        self.index = 0
        self.placed = []
        self.mistakesLeft = difficulty.mistakeBudget
        self.completed = 0
        self.isOver = false
    }

    public var chainLength: Int { designs.count }

    public var currentDesign: OrigamiDesign? {
        guard !isOver && index < designs.count else { return nil }
        return designs[index]
    }

    public var currentStep: OrigamiFold? {
        guard let design = currentDesign, placed.count < design.steps.count else { return nil }
        return design.steps[placed.count]
    }

    /// 지금 접어야 할 순서(이미 접은 것은 제외).
    public var remainingSteps: [OrigamiFold] {
        guard let design = currentDesign, placed.count < design.steps.count else { return [] }
        return Array(design.steps.dropFirst(placed.count))
    }

    public var stars: Int {
        if isOver && completed == chainLength && mistakesLeft == difficulty.mistakeBudget {
            return 3
        }
        if completed == chainLength { return 2 }
        if completed >= max(1, chainLength / 2) { return 1 }
        return 0
    }

    /// 한 번 접는다.
    @discardableResult
    public mutating func fold(_ fold: OrigamiFold) -> ChallengeFold {
        guard !isOver, let design = currentDesign else { return .ignored }
        guard placed.count < design.steps.count else { return .ignored }
        if design.steps[placed.count] == fold {
            placed.append(fold)
            let remaining = design.steps.count - placed.count
            if remaining > 0 {
                return .accepted(placed: placed.count, remaining: remaining)
            }
            completed += 1
            index += 1
            placed = []
            if index >= designs.count {
                isOver = true
                return .finished(completed: completed, cleared: true)
            }
            return .designCompleted(completed: completed, next: designs[index])
        }
        // 잘못 접으면 이 도안은 처음부터 다시. 실수가 하나 줄어든다.
        placed = []
        mistakesLeft -= 1
        if mistakesLeft <= 0 {
            mistakesLeft = 0
            isOver = true
            return .finished(completed: completed, cleared: false)
        }
        return .unfolded(mistakesLeft: mistakesLeft)
    }
}

// MARK: - 기록

/// 한 난이도의 최고 기록. 저장 파일에 그대로 남는다.
public struct MiniGameRecord: Codable, Equatable, Sendable {
    public var plays: Int
    public var stars: Int
    /// 기억의 서랍: 가장 적게 움직인 기록.
    public var bestMoves: Int?
    /// 종이접기 연쇄: 한 번에 가장 많이 완성한 도안 수.
    public var bestChain: Int?
    /// 가장 빨랐던 시간(초).
    public var bestSeconds: Double?
    public var lastPlayedAt: Date?

    public init(
        plays: Int = 0,
        stars: Int = 0,
        bestMoves: Int? = nil,
        bestChain: Int? = nil,
        bestSeconds: Double? = nil,
        lastPlayedAt: Date? = nil
    ) {
        self.plays = plays
        self.stars = stars
        self.bestMoves = bestMoves
        self.bestChain = bestChain
        self.bestSeconds = bestSeconds
        self.lastPlayedAt = lastPlayedAt
    }

    public var hasRecord: Bool { plays > 0 }
}

/// 놀이방 두 놀이의 난이도별 기록 묶음. 키는 "memoryDrawer.easy" 꼴이다.
public struct MiniGameRecords: Codable, Equatable, Sendable {
    public private(set) var entries: [String: MiniGameRecord]

    public init(entries: [String: MiniGameRecord] = [:]) {
        self.entries = entries
    }

    public static func key(_ id: MiniGameID, _ difficulty: MiniGameDifficulty) -> String {
        "\(id.rawValue).\(difficulty.rawValue)"
    }

    public func record(for id: MiniGameID, difficulty: MiniGameDifficulty) -> MiniGameRecord? {
        entries[MiniGameRecords.key(id, difficulty)]
    }

    public func stars(for id: MiniGameID) -> Int {
        MiniGameDifficulty.allCases.reduce(0) { partial, difficulty in
            partial + (record(for: id, difficulty: difficulty)?.stars ?? 0)
        }
    }

    public var totalStars: Int {
        MiniGameID.allCases.reduce(0) { $0 + stars(for: $1) }
    }

    /// 기억의 서랍 한 판의 결과를 남긴다. 갱신된 기록을 돌려준다.
    @discardableResult
    public mutating func submitMemory(
        difficulty: MiniGameDifficulty,
        moves: Int,
        seconds: Double,
        stars: Int,
        at date: Date = Date()
    ) -> MiniGameRecord {
        let key = MiniGameRecords.key(.memoryDrawer, difficulty)
        var record = entries[key] ?? MiniGameRecord()
        record.plays += 1
        if stars > record.stars { record.stars = stars }
        if let best = record.bestMoves {
            if moves < best { record.bestMoves = moves }
        } else {
            record.bestMoves = moves
        }
        if let best = record.bestSeconds {
            if seconds < best { record.bestSeconds = seconds }
        } else {
            record.bestSeconds = seconds
        }
        record.lastPlayedAt = date
        entries[key] = record
        return record
    }

    /// 종이접기 연쇄 한 판의 결과를 남긴다.
    @discardableResult
    public mutating func submitChallenge(
        difficulty: MiniGameDifficulty,
        completed: Int,
        seconds: Double,
        stars: Int,
        at date: Date = Date()
    ) -> MiniGameRecord {
        let key = MiniGameRecords.key(.origamiChallenge, difficulty)
        var record = entries[key] ?? MiniGameRecord()
        record.plays += 1
        if stars > record.stars { record.stars = stars }
        if let best = record.bestChain {
            if completed > best { record.bestChain = completed }
        } else {
            record.bestChain = completed
        }
        if let best = record.bestSeconds {
            if seconds < best { record.bestSeconds = seconds }
        } else {
            record.bestSeconds = seconds
        }
        record.lastPlayedAt = date
        entries[key] = record
        return record
    }
}
