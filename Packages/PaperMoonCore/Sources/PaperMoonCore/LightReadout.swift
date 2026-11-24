import Foundation

/// 빛 투과 퍼즐의 지금 정렬 상태.
///
/// 조각이 한 칸이라도 어긋나 있으면 종이 너머의 글씨는 **흐릿하게만** 보인다.
/// 화면은 `blurRadius`만큼 흐리게 그리고, `partialCode`로 앞부분만 살짝 보여 준다.
/// 모든 조각이 제자리에 있어야 `isCrisp`가 참이 되고, 그때 비로소 확인할 수 있다.
public struct LightReadout: Equatable, Sendable {
    /// 제자리에 놓인 조각 수.
    public let correct: Int
    /// 조각 전체 수.
    public let total: Int
    /// 지금 칸에 놓인 조각 수(빈 칸은 세지 않는다).
    public let filled: Int
    /// 0(모두 어긋남) ~ 1(완전히 맞음).
    public let clarity: Double
    /// 완전히 맞아 글씨가 또렷한지.
    public let isCrisp: Bool
    /// 지금 보이는 만큼만 남긴 암호. 흐릿할수록 뒤가 점으로 지워진다.
    public let partialCode: String
    /// 화면에 그대로 넣을 흐림 반경(0~5.5).
    public let blurRadius: Double

    public init(
        correct: Int,
        total: Int,
        filled: Int,
        clarity: Double,
        isCrisp: Bool,
        partialCode: String,
        blurRadius: Double
    ) {
        self.correct = correct
        self.total = total
        self.filled = filled
        self.clarity = clarity
        self.isCrisp = isCrisp
        self.partialCode = partialCode
        self.blurRadius = blurRadius
    }

    /// 어긋난 조각 수.
    public var wrong: Int { max(0, filled - correct) }

    public var clarityText: String {
        "\(correct) / \(total) 조각이 제자리"
    }
}

extension Puzzle {
    /// 빛 투과 퍼즐에서 지금 놓인 순서가 얼마나 또렷한 글씨를 만드는지 계산한다.
    /// 다른 종류의 퍼즐에 부르면 "아무것도 안 보이는" 값이 나온다.
    public func lightReadout(for answer: [Int]) -> LightReadout {
        let total = solution.count
        guard kind == .lightReveal, total > 0 else {
            return LightReadout(
                correct: 0,
                total: max(total, 0),
                filled: answer.count,
                clarity: 0,
                isCrisp: false,
                partialCode: "",
                blurRadius: 5.5
            )
        }
        var correct = 0
        for index in 0..<total where index < answer.count && answer[index] == solution[index] {
            correct += 1
        }
        let filled = min(answer.count, total)
        let clarity = Double(correct) / Double(total)
        let code = revealedCode ?? "빛이 종이를 통과해 글씨를 비췄다."
        return LightReadout(
            correct: correct,
            total: total,
            filled: filled,
            clarity: clarity,
            isCrisp: correct == total,
            partialCode: Puzzle.masked(code, clarity: clarity),
            blurRadius: (1 - clarity) * 5.5
        )
    }

    /// 암호의 앞부분만 남기고 뒤를 점으로 지운다. 띄어쓰기는 그대로 둔다.
    static func masked(_ text: String, clarity: Double) -> String {
        let characters = Array(text)
        guard !characters.isEmpty else { return text }
        if clarity >= 1 { return text }
        let visible = Int((clarity * Double(characters.count)).rounded(.down))
        var out = ""
        var shown = 0
        for character in characters {
            if character == " " {
                out.append(character)
                continue
            }
            if shown < visible {
                out.append(character)
                shown += 1
            } else {
                out.append("·")
            }
        }
        return out
    }
}
