import SwiftUI
import PaperMoonCore

/// 상점. 세 상품의 실제 잠금과 가격을 보여 주고, 산 것은 바로 게임에 반영한다.
struct ShopView: View {
    @ObservedObject var store: GameStore
    @ObservedObject var shop: StoreManager
    let onClose: () -> Void

    var body: some View {
        ZStack {
            PaperBackground(tint: Palette.paper)

            VStack(spacing: 8) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        if let reason = store.shopReason {
                            promptCard(reason)
                        }

                        ForEach(StoreProduct.allCases, id: \.rawValue) { product in
                            card(product)
                        }

                        HStack(spacing: 10) {
                            Button("구매 복원") {
                                Task {
                                    await shop.restore()
                                    store.applyEntitlements(shop.entitlements)
                                }
                            }
                            .buttonStyle(CozyButtonStyle(fill: Palette.cream))

                            Button("새로 고침") {
                                Task {
                                    await shop.refresh()
                                    store.applyEntitlements(shop.entitlements)
                                }
                            }
                            .buttonStyle(CozyButtonStyle(fill: Palette.cream))
                        }
                        .padding(.top, 4)

                        devCard

                        Text("결제는 App Store 계정으로 이루어지며, 구매 복원으로 다른 기기에서도 되살릴 수 있다.")
                            .font(.cozy(10, weight: .semibold))
                            .foregroundStyle(Palette.lineSoft.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .task {
            shop.start()
            await shop.refresh()
            store.applyEntitlements(shop.entitlements)
        }
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                RoundIconButton(systemName: "chevron.left", accessibility: "상점 닫기") {
                    onClose()
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("종이달 상점")
                        .font(.cozy(18, weight: .bold))
                    Text(shop.statusText)
                        .font(.cozy(11, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                        .lineLimit(2)
                }
                Spacer()
            }
            if shop.state.isBusy {
                ProgressView()
                    .tint(Palette.line)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private func promptCard(_ reason: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(verbatim: "🌙")
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: reason)
                    .font(.cozy(12.5, weight: .semibold))
                    .foregroundStyle(Palette.line)
                    .fixedSize(horizontal: false, vertical: true)
                Text("1장면은 무료로 끝까지 즐길 수 있다. 아래에서 필요한 것만 사면 된다.")
                    .font(.cozy(10.5, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard(fill: Palette.butter.opacity(0.35))
    }

    // MARK: 상품 카드

    private func card(_ product: StoreProduct) -> some View {
        let owned = shop.owns(product)
        let price = shop.displayPrice(for: product)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(verbatim: product.glyph)
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: product.title)
                        .font(.cozy(15, weight: .bold))
                        .foregroundStyle(Palette.line)
                    Text(verbatim: product.requirementText)
                        .font(.cozy(10, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                }
                Spacer(minLength: 4)
                Text(verbatim: owned ? "보유 중" : price)
                    .font(.cozy(13, weight: .bold))
                    .foregroundStyle(Palette.line)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(owned ? Palette.sage.opacity(0.55) : Palette.butter))
            }

            Text(verbatim: product.summary)
                .font(.cozy(12, weight: .semibold))
                .foregroundStyle(Palette.lineSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if owned {
                    Text("이미 열려 있다")
                        .font(.cozy(11, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                } else {
                    Button(shop.state.isBusy ? "처리 중…" : "\(price)에 구매") {
                        Task {
                            await shop.purchase(product)
                            store.applyEntitlements(shop.entitlements)
                        }
                    }
                    .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                    .disabled(shop.state.isBusy)
                }
                Spacer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard(fill: Palette.cream)
    }

    // MARK: 개발용

    private var devCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("개발자 도구")
                .font(.cozy(12, weight: .bold))
                .foregroundStyle(Palette.lineSoft)
            Toggle(isOn: Binding(
                get: { shop.isDevUnlocked },
                set: { on in
                    shop.setDevUnlock(on)
                    store.applyEntitlements(shop.entitlements)
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("결제 없이 모두 열기")
                        .font(.cozy(12, weight: .semibold))
                        .foregroundStyle(Palette.line)
                    Text("시뮬레이터에서 2·3장면과 지하실을 확인할 때 쓴다. 실제 결제 기록은 남지 않는다.")
                        .font(.cozy(10, weight: .semibold))
                        .foregroundStyle(Palette.lineSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Palette.sage)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard(fill: Palette.paper)
    }
}
