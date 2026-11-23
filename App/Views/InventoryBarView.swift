import SwiftUI
import PaperMoonCore

/// 화면 아래 주머니. 아이템을 고르면 씬에 쓰거나, 다른 아이템을 눌러 합친다.
struct InventoryBarView: View {
    @ObservedObject var store: GameStore
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("주머니")
                    .font(.cartoon(12, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text("\(store.inventory.count)개")
                    .font(.cartoon(11, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)

                Spacer()

                Text(store.selected.map { "\(store.itemName($0)) 선택됨" }
                     ?? "물건을 고른 뒤 씬에 쓰거나 다른 물건과 합치세요")
                    .font(.cartoon(11, weight: .semibold))
                    .foregroundStyle(store.selected == nil ? Palette.inkSoft.opacity(0.8) : Palette.coral)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    if store.inventory.isEmpty {
                        Text("아직 주머니가 비어 있다.")
                            .font(.cartoon(12, weight: .semibold))
                            .foregroundStyle(Palette.inkSoft.opacity(0.7))
                            .padding(.vertical, compact ? 12 : 18)
                            .padding(.leading, 4)
                    }

                    ForEach(store.inventory) { item in
                        itemCell(item)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }
            .frame(height: compact ? 64 : 76)
        }
        .padding(.top, compact ? 2 : 6)
        .padding(.bottom, 2)
    }

    private func itemCell(_ item: Item) -> some View {
        let isSelected = store.selected == item.id

        return Button {
            store.tapItem(item)
        } label: {
            VStack(spacing: 2) {
                Text(verbatim: item.glyph)
                    .font(.system(size: compact ? 20 : 24))
                    .frame(width: compact ? 38 : 44, height: compact ? 38 : 44)
                    .background(
                        Circle().fill(isSelected ? Palette.mustard : Palette.cream)
                    )
                    .overlay(
                        Circle().stroke(Palette.ink, lineWidth: isSelected ? 3.5 : 2.5)
                    )
                Text(verbatim: item.name)
                    .font(.cartoon(9.5, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .frame(width: 58)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Palette.mustard.opacity(0.28) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.06 : 1.0)
            .offset(y: isSelected ? -3 : 0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)
        .accessibilityLabel(Text(verbatim: item.name))
        .accessibilityHint(Text(verbatim: item.note))
    }
}
