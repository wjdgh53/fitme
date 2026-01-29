import SwiftUI

struct HistoryListView: View {
    let viewModel: HistoryListViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    periodChips
                    monthHeader
                    historyList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 140)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.data.title)
                    .font(AppFonts.nunito(28, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text(viewModel.data.subtitle)
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: "#8B8B8B"))
            }
            Spacer()
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(hex: "#FFE4D6"), lineWidth: 1))
                .overlay(MaterialSymbol(name: "filter_list", size: 22).foregroundColor(Color(hex: "#8B8B8B")))
        }
        .padding(.top, 18)
    }

    private var periodChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip(title: "1주", isActive: false)
                chip(title: "1개월", isActive: true)
                chip(title: "3개월", isActive: false)
                chip(title: "전체", isActive: false)
            }
        }
        .padding(.bottom, 6)
    }

    private func chip(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(AppFonts.nunito(13, weight: .bold))
            .foregroundColor(isActive ? .white : Color(hex: "#8B8B8B"))
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(isActive ? Color(hex: "#FF8577") : Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(hex: "#FFE4D6"), lineWidth: 1))
            .shadow(color: Color(hex: "#FF8577").opacity(isActive ? 0.3 : 0), radius: 8, x: 0, y: 4)
    }

    private var monthHeader: some View {
        HStack {
            Text("October 2023")
                .font(AppFonts.nunito(12, weight: .heavy))
                .foregroundColor(Color(hex: "#8B8B8B"))
                .tracking(1)
            Spacer()
            Text("18 Workouts")
                .font(AppFonts.nunito(10, weight: .bold))
                .foregroundColor(Color(hex: "#FF8577"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "#FFE4D6"), lineWidth: 1))
        }
        .padding(.top, 8)
    }

    private var historyList: some View {
        VStack(spacing: 14) {
            ForEach(viewModel.data.records.indices, id: \.self) { index in
                let item = viewModel.data.records[index]
                historyRow(item: item, isAccent: index == 2 || index == 4)
                    .onTapGesture { viewModel.onSelectDetail() }
            }
        }
    }

    private func historyRow(item: HistoryListItemMock, isAccent: Bool) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(item.dateMonth)
                    .font(AppFonts.nunito(10, weight: .heavy))
                    .foregroundColor(Color(hex: "#8B8B8B"))
                    .textCase(.uppercase)
                Text(item.dateDay)
                    .font(AppFonts.nunito(20, weight: .black))
                    .foregroundColor(isAccent ? Color(hex: "#74D680") : Color(hex: "#FF8577"))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(AppFonts.nunito(16, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text(item.meta)
                    .font(AppFonts.nunito(13, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B8B8B"))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(isAccent ? Color(hex: "#74D680").opacity(0.2) : Color.white, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "#74D680").opacity(isAccent ? 0.04 : 0))
        )
    }
}
