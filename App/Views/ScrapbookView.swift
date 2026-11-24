import SwiftUI
import PaperMoonCore

/// 다락방 스크랩북. 숨은 종이학과 옛날 우표를 모은 만큼 채워진다.
struct ScrapbookView: View {
    @ObservedObject var store: GameStore
    let onClose: () -> Void

    private var cranes: [GameStore.ScrapbookEntry] {
        store.scrapbookEntries.filter { $0.collectible.kind == .crane }
    }

    private var stamps: [GameStore.ScrapbookEntry] {
        store.scrapbookEntries.filter { $0.collectible.kind == .stamp }
    }

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 10)]

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 8) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        progressCard

                        Text("접힌 종이학")
                            .font(.cozy(15, weight: .bold))
                            .foregroundStyle(Palette.line)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(cranes) { entry in
                                craneCell(entry)
                            }
                        }

                        Text("옛날 우표")
                            .font(.cozy(15, weight: .bold))
                            .foregroundStyle(Palette.line)
                            .padding(.top, 4)
                        VStack(spacing: 8) {
                            ForEach(stamps) { entry in
                                stampRow(entry)
                            }
                        }

                        Text("종이학 12마리를 다 모으면 엔딩 뒤에 다락방 비밀 서랍이 열린다. 우표는 모으지 않아도 손해가 없다.")
                            .font(.cozy(11, weight: .semibold))
                            .foregroundStyle(Palette.lineSoft.opacity(0.85))
                            .padding(.top, 4)

                        if store.canOpenSecretDrawer {
                            Button(store.hasOpenedSecretDrawer ? "비밀 서랍 다시 보기" : "비밀 서랍 열기") {
                                store.openSecretDrawer()
                                onClose()
                            }
                            .buttonStyle(CozyButtonStyle(fill: Palette.butter))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundIconButton(systemName: "chevron.left", accessibility: "스크랩북 닫기") {
                onClose()
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("다락방 스크랩북")
                    .font(.cozy(17, weight: .bold))
                Text("숨은 종이학 \(store.craneCount) / \(store.craneGoal) · 옛날 우표 \(store.stampCount)장")
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var progressCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Palette.cloud, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(store.craneCount) / CGFloat(max(store.craneGoal, 1)))
                    .stroke(Palette.butter, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(store.craneCount)")
                    .font(.cozy(18, weight: .bold))
                    .foregroundStyle(Palette.line)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 3) {
                Text(store.canOpenSecretDrawer ? "열두 마리를 다 모았다" : "종이학을 모으는 중")
                    .font(.cozy(14, weight: .semibold))
                    .foregroundStyle(Palette.line)
                Text(store.canOpenSecretDrawer
                     ? "엔딩 뒤에 다락방 서랍을 열어 볼 수 있다."
                     : "본편 9개 방 구석구석을 살펴보자. 방마다 한두 마리가 숨어 있다.")
                    .font(.cozy(11, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .paperCard(fill: Palette.cream)
    }

    private func craneCell(_ entry: GameStore.ScrapbookEntry) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(entry.collected ? Palette.butter.opacity(0.45) : Palette.cloud)
                    .frame(width: 46, height: 46)
                Circle()
                    .stroke(Palette.lineSoft.opacity(0.4), lineWidth: 1)
                    .frame(width: 46, height: 46)
                Text(verbatim: entry.collected ? entry.collectible.glyph : "?")
                    .font(.system(size: entry.collected ? 22 : 18))
                    .foregroundStyle(entry.collected ? Palette.line : Palette.lineSoft.opacity(0.6))
            }
            Text(verbatim: entry.collected ? entry.collectible.label : "아직 못 찾음")
                .font(.cozy(10, weight: .semibold))
                .foregroundStyle(entry.collected ? Palette.line : Palette.lineSoft.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(verbatim: entry.collected ? entry.collectible.memory : "본편 어딘가에 접힌 채 숨어 있다.")
                .font(.cozy(9, weight: .semibold))
                .foregroundStyle(Palette.lineSoft.opacity(entry.collected ? 0.9 : 0.55))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .frame(minHeight: 44, alignment: .top)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(entry.collected ? Palette.cream : Palette.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.lineSoft.opacity(0.35), lineWidth: 1)
        )
    }

    private func stampRow(_ entry: GameStore.ScrapbookEntry) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: entry.collected ? entry.collectible.glyph : "?")
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(Circle().fill(entry.collected ? Palette.rose.opacity(0.3) : Palette.cloud))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.collected ? entry.collectible.label : "아직 못 찾은 우표")
                    .font(.cozy(12, weight: .semibold))
                    .foregroundStyle(Palette.line)
                Text(verbatim: entry.collected ? entry.collectible.memory : "찾지 못해도 이야기는 그대로 흘러간다.")
                    .font(.cozy(10, weight: .semibold))
                    .foregroundStyle(Palette.lineSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.paper)
        )
    }
}
