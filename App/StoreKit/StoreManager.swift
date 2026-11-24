import Foundation
import StoreKit
import PaperMoonCore

/// StoreKit 2로 세 상품을 사고, 산 것만 `Entitlements`로 바꿔 게임에 넘긴다.
///
/// Xcode 없이도 화면을 확인할 수 있도록 `UsersDefaults` 기반의 개발용 잠금해제 토글을 함께 둔다.
/// 실제 배포에서는 토글을 끄고 `Products.storekit`(테스트) 또는 App Store Connect 상품을 쓴다.
final class StoreManager: ObservableObject {
    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case failed(String)
        case restored

        var isBusy: Bool {
            self == .loading || self == .purchasing
        }
    }

    static let devUnlockKey = "paperMoon.devUnlock.v1"

    @Published private(set) var entitlements: Entitlements = .trial
    @Published private(set) var storeProducts: [Product] = []
    @Published private(set) var state: PurchaseState = .idle
    @Published private(set) var productsLoaded = false
    @Published private(set) var isDevUnlocked = false

    private var updatesTask: Task<Void, Never>?

    init() {
        isDevUnlocked = UserDefaults.standard.bool(forKey: StoreManager.devUnlockKey)
        if isDevUnlocked {
            entitlements = .full
        }
    }

    // MARK: - 시작과 갱신

    @MainActor
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(update)
            }
        }
        Task { await refresh() }
    }

    @MainActor
    func refresh() async {
        state = .loading
        await loadProducts()
        await refreshEntitlements()
        if state == .loading {
            state = .idle
        }
    }

    @MainActor
    func loadProducts() async {
        do {
            let ids = StoreProduct.allCases.map { $0.rawValue }
            storeProducts = try await Product.products(for: ids)
            productsLoaded = true
        } catch {
            storeProducts = []
            productsLoaded = false
        }
    }

    @MainActor
    func refreshEntitlements() async {
        var purchased = Entitlements()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if let product = StoreProduct(rawValue: transaction.productID) {
                purchased.apply(product)
            }
        }
        if isDevUnlocked {
            purchased = .full
        }
        entitlements = purchased
    }

    // MARK: - 구매

    func product(for id: StoreProduct) -> Product? {
        storeProducts.first { $0.id == id.rawValue }
    }

    /// App Store 가격이 준비되면 그 값을, 아니면 상품표의 원화 가격을 보여 준다.
    func displayPrice(for id: StoreProduct) -> String {
        product(for: id)?.displayPrice ?? id.priceText
    }

    func owns(_ id: StoreProduct) -> Bool {
        entitlements.has(id)
    }

    @MainActor
    @discardableResult
    func purchase(_ id: StoreProduct) async -> Bool {
        guard let product = product(for: id) else {
            state = .failed("상품 정보를 아직 불러오지 못했다. 잠시 뒤 다시 시도해 주세요.")
            return false
        }
        state = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    state = .failed("영수증을 확인하지 못했다.")
                    return false
                }
                await transaction.finish()
                var updated = entitlements
                updated.apply(id)
                entitlements = updated
                state = .idle
                return true
            case .userCancelled:
                state = .idle
                return false
            case .pending:
                state = .failed("구매가 승인 대기 중이다. 승인되면 자동으로 열린다.")
                return false
            @unknown default:
                state = .idle
                return false
            }
        } catch {
            state = .failed("구매에 실패했다: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    func restore() async {
        state = .loading
        do {
            try await AppStore.sync()
        } catch {
            state = .failed("복원에 실패했다: \(error.localizedDescription)")
            return
        }
        await refreshEntitlements()
        state = entitlements.isEmpty ? .failed("복원할 구매가 없다.") : .restored
    }

    @MainActor
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if let product = StoreProduct(rawValue: transaction.productID) {
            var updated = entitlements
            updated.apply(product)
            entitlements = updated
        }
        await transaction.finish()
    }

    // MARK: - 개발용

    /// 실제 결제 없이 모든 잠금을 열어 보는 토글. 앱을 지우면 함께 사라진다.
    @MainActor
    func setDevUnlock(_ on: Bool) {
        isDevUnlocked = on
        UserDefaults.standard.set(on, forKey: StoreManager.devUnlockKey)
        Task { await refreshEntitlements() }
        if on {
            entitlements = .full
        }
    }

    @MainActor
    func clearFailure() {
        if case .failed = state {
            state = .idle
        }
    }

    var statusText: String {
        switch state {
        case .idle:
            return entitlements.summaryText
        case .loading:
            return "상품 정보를 불러오는 중…"
        case .purchasing:
            return "구매를 확인하는 중…"
        case .failed(let message):
            return message
        case .restored:
            return "구매를 복원했다 · \(entitlements.summaryText)"
        }
    }
}
