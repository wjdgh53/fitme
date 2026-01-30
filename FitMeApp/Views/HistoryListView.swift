import SwiftUI

struct HistoryListView: View {
    let viewModel: HistoryListViewModel
    @State private var selectedPeriod = "month"

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    periodChips
                    
                    if viewModel.data.sessions.isEmpty {
                        emptyState
                    } else {
                        monthHeader
                        historyList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 140)
            }
            .refreshable {
                await viewModel.onRefresh()
            }
        }
        .task {
            await viewModel.onRefresh()
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
                chip(title: "1주", period: "week")
                chip(title: "1개월", period: "month")
                chip(title: "전체", period: "all")
            }
        }
        .padding(.bottom, 6)
    }

    private func chip(title: String, period: String) -> some View {
        let isActive = selectedPeriod == period
        return Button {
            selectedPeriod = period
            Task {
                await viewModel.onRefresh()
            }
        } label: {
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
    }

    private var monthHeader: some View {
        HStack {
            Text(currentMonthText)
                .font(AppFonts.nunito(12, weight: .heavy))
                .foregroundColor(Color(hex: "#8B8B8B"))
                .tracking(1)
            Spacer()
            Text("\(viewModel.data.sessions.count) Workouts")
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
    
    private var currentMonthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private var historyList: some View {
        VStack(spacing: 14) {
            ForEach(viewModel.data.sessions) { session in
                historyRow(session: session, isAccent: session.source != .fitme)
                    .onTapGesture { viewModel.onSelectDetail(session.id) }
            }
        }
    }

    private func historyRow(session: SessionSummary, isAccent: Bool) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: session.date) ?? Date()
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let month = monthFormatter.string(from: date)
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        let day = dayFormatter.string(from: date)
        
        return HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(month)
                    .font(AppFonts.nunito(10, weight: .heavy))
                    .foregroundColor(Color(hex: "#8B8B8B"))
                    .textCase(.uppercase)
                Text(day)
                    .font(AppFonts.nunito(20, weight: .black))
                    .foregroundColor(isAccent ? Color(hex: "#74D680") : Color(hex: "#FF8577"))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Workout")
                    .font(AppFonts.nunito(16, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text("\(session.durationMinutes)m • \(session.calories)kcal • \(session.totalExercises) exercises")
                    .font(AppFonts.nunito(13, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B8B8B"))
            }
            Spacer()
            
            if session.source == .appleHealth {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
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
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📋")
                .font(.system(size: 48))
            Text("No workout history yet")
                .font(AppFonts.nunito(18, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Text("Start a workout to see your history here")
                .font(AppFonts.nunito(14, weight: .medium))
                .foregroundColor(Color(hex: "#8B8B8B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}
