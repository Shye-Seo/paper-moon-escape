import Foundation

/// 앱 안에서 파는 세 가지. 식별자는 `Products.storekit`과 `StoreManager`가 함께 쓴다.
public enum StoreProduct: String, Codable, CaseIterable, Hashable, Sendable {
    /// 1장면 무료 체험 뒤 2·3장면을 연다.
    case fullUnlock = "com.quoguri.papermooneescape.fullunlock"
    /// 본편을 깬 뒤 즐기는 「비밀 다락방 지하실」 4장면.
    case cellarChapter = "com.quoguri.papermooneescape.cellarchapter"
    /// 힌트를 횟수 제한 없이 본다.
    case hintPass = "com.quoguri.papermooneescape.hintspass"

    public var title: String {
        switch self {
        case .fullUnlock: return "본편 전체 잠금해제"
        case .cellarChapter: return "비밀 다락방 지하실"
        case .hintPass: return "힌트 무제한 패스"
        }
    }

    public var priceWon: Int {
        switch self {
        case .fullUnlock: return 4900
        case .cellarChapter: return 2900
        case .hintPass: return 1500
        }
    }

    public var priceText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: priceWon)) ?? "\(priceWon)"
        return "₩\(number)"
    }

    public var glyph: String {
        switch self {
        case .fullUnlock: return "🌙"
        case .cellarChapter: return "🗝"
        case .hintPass: return "💡"
        }
    }

    public var summary: String {
        switch self {
        case .fullUnlock:
            return "1장면은 무료. 2장면 거꾸로 자라는 온실과 3장면 태엽 시계탑, 그리고 엔딩까지."
        case .cellarChapter:
            return "본편을 깐 뒤 열리는 보너스 4장면. 지하실 세 방과 새로운 퍼즐, 지하실 엔딩."
        case .hintPass:
            return "힌트 1·2단계를 횟수 제한 없이. 막힐 때마다 바로 물어볼 수 있다."
        }
    }

    public var requirementText: String {
        switch self {
        case .fullUnlock: return "2·3장면을 플레이하려면 필요하다"
        case .cellarChapter: return "본편 클리어 후 열린다"
        case .hintPass: return "무료 힌트 3회를 다 쓴 뒤에도 계속 볼 수 있다"
        }
    }

    /// 이 상품이 열어 주는 잠금. 화면과 엔진이 같은 이름을 쓴다.
    public var entitlementKey: String {
        switch self {
        case .fullUnlock: return "fullUnlock"
        case .cellarChapter: return "cellarChapter"
        case .hintPass: return "hintPass"
        }
    }
}

/// 구매로 열린 것들. 저장 파일에는 넣지 않고, 실행할 때 StoreKit(또는 개발용 토글)에서 채운다.
public struct Entitlements: Equatable, Sendable {
    public var fullUnlock: Bool
    public var cellarChapter: Bool
    public var hintPass: Bool

    public init(fullUnlock: Bool = false, cellarChapter: Bool = false, hintPass: Bool = false) {
        self.fullUnlock = fullUnlock
        self.cellarChapter = cellarChapter
        self.hintPass = hintPass
    }

    /// 아무것도 사지 않은 상태. 1장면만 열린다.
    public static let trial = Entitlements()

    /// 테스트와 개발 기본값. 모든 장면과 힌트가 열린 상태다.
    public static let full = Entitlements(fullUnlock: true, cellarChapter: true, hintPass: true)

    /// 패스 없이 볼 수 있는 힌트 횟수.
    public static let freeHintAllowance: Int = 3

    public func has(_ product: StoreProduct) -> Bool {
        switch product {
        case .fullUnlock: return fullUnlock
        case .cellarChapter: return cellarChapter && fullUnlock
        case .hintPass: return hintPass
        }
    }

    public mutating func apply(_ product: StoreProduct) {
        switch product {
        case .fullUnlock: fullUnlock = true
        case .cellarChapter: cellarChapter = true
        case .hintPass: hintPass = true
        }
    }

    public var purchasedProducts: [StoreProduct] {
        StoreProduct.allCases.filter { has($0) }
    }

    public var isEmpty: Bool { purchasedProducts.isEmpty }

    /// 화면에 보여 줄 한 줄 요약.
    public var summaryText: String {
        let purchased = purchasedProducts
        if purchased.isEmpty { return "무료 체험 중 · 1장면" }
        if purchased.count == StoreProduct.allCases.count { return "모든 상품 구매 완료" }
        return purchased.map { $0.title }.joined(separator: " · ")
    }
}
