import SwiftUI

struct LibraryView: View {
    let viewModel: LibraryViewModel
    @State private var searchText = ""

    private var filteredItems: [LibraryItemData] {
        if searchText.isEmpty {
            return viewModel.data.items
        }
        return viewModel.data.items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    searchBar
                    categoryChips
                    countRow
                    listItems
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 140)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#F3E8DE"), lineWidth: 2))
                    .overlay(MaterialSymbol(name: "arrow_back_ios_new", size: 22).foregroundColor(Color(hex: "#3D3D3D")))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 3)
            }
            Spacer()
            Text(viewModel.data.title)
                .font(AppFonts.quicksand(24, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            MaterialSymbol(name: "search", size: 24)
                .foregroundColor(Color(hex: "#FF8577"))
            TextField(viewModel.data.searchPlaceholder, text: $searchText)
                .font(AppFonts.nunito(18, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
                .tint(Color(hex: "#FF8577"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#F3E8DE"), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 4)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.data.categoryChips.indices, id: \.self) { index in
                    let title = viewModel.data.categoryChips[index]
                    Text(title)
                        .font(AppFonts.nunito(15, weight: .bold))
                        .foregroundColor(index == 0 ? .white : Color(hex: "#9CA3AF"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(index == 0 ? Color(hex: "#FF8577") : Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "#F3E8DE"), lineWidth: 2))
                }
            }
        }
    }

    private var countRow: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "#6EE7B7").opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(MaterialSymbol(name: "fitness_center", size: 14).foregroundColor(Color(hex: "#6EE7B7")))
                Text(viewModel.data.countText)
                    .font(AppFonts.nunito(13, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            Spacer()
            HStack(spacing: 4) {
                MaterialSymbol(name: "sort", size: 18)
                Text("최근순")
            }
            .font(AppFonts.nunito(13, weight: .heavy))
            .foregroundColor(Color(hex: "#FF8577"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: "#FF8577").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var listItems: some View {
        VStack(spacing: 16) {
            ForEach(filteredItems.indices, id: \.self) { index in
                let item = filteredItems[index]
                HStack(spacing: 14) {
                    AsyncImage(url: item.imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(hex: "#F5F3FF")
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white, lineWidth: 2))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(AppFonts.quicksand(17, weight: .bold))
                            .foregroundColor(Color(hex: "#3D3D3D"))
                        HStack(spacing: 6) {
                            Text(item.subtitle)
                                .font(AppFonts.nunito(11, weight: .bold))
                                .foregroundColor(Color(hex: "#FF8577"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#FF8577").opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "#FCD34D"))
                                    .frame(width: 6, height: 6)
                                Text(item.equipment)
                                    .font(AppFonts.nunito(12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                            }
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(Color(hex: "#FFF8F0"))
                        .frame(width: 40, height: 40)
                        .overlay(MaterialSymbol(name: "arrow_forward_ios", size: 16).foregroundColor(Color(hex: "#FF8577")))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color(hex: "#FF8577").opacity(0.15), radius: 12, x: 0, y: 6)
                .onTapGesture { viewModel.onSelectItem() }
            }
        }
    }
}
