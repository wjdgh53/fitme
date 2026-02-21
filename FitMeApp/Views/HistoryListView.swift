import SwiftUI

struct HistoryListView: View {
    let viewModel: HistoryListViewModel
    @State private var selectedPeriod = "month"
    @State private var hasAnimatedHistoryList = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    periodChips
                    
                    if displayedSessions.isEmpty {
                        emptyState
                    } else {
                        monthHeader
                        historyList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
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
                    .font(.system(size: 56, weight: .black))
                    .foregroundColor(AppTheme.title)
                Text(viewModel.data.subtitle)
                    .font(AppFonts.plusJakarta(17, weight: .bold))
                    .foregroundColor(AppTheme.muted.opacity(0.7))
            }
            Spacer()
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.elevatedSurface.opacity(0.88))
                .frame(width: 58, height: 58)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.cardBorderGold.opacity(0.35), lineWidth: 1))
                .overlay(MaterialSymbol(name: "filter_list", size: 22).foregroundColor(AppTheme.muted.opacity(0.55)))
        }
        .motionEntry(index: 0)
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
        .motionEntry(index: 1)
    }

    private func chip(title: String, period: String) -> some View {
        let isActive = selectedPeriod == period
        return Button {
            selectedPeriod = period
        } label: {
            Text(title)
                .font(AppFonts.nunito(18, weight: .black))
                .foregroundColor(isActive ? Color.white : AppTheme.muted.opacity(0.7))
                .frame(minWidth: 116, minHeight: 56)
                .background(isActive ? AppTheme.primaryButton : AppTheme.elevatedSurface.opacity(0.8))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.cardBorderGold.opacity(0.3), lineWidth: 1))
                .shadow(color: AppTheme.primaryButton.opacity(isActive ? 0.2 : 0), radius: 8, x: 0, y: 4)
        }
    }

    private var monthHeader: some View {
        HStack {
            Text(displayMonthText)
                .font(AppFonts.plusJakarta(18, weight: .bold))
                .foregroundColor(AppTheme.muted.opacity(0.75))
                .tracking(1.4)
            Spacer()
            Text("\(displayedSessions.count) Workouts")
                .font(AppFonts.plusJakarta(16, weight: .bold))
                .foregroundColor(AppTheme.primaryButton)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.elevatedSurface.opacity(0.8))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.cardBorderGold.opacity(0.3), lineWidth: 1))
        }
        .padding(.top, 8)
        .motionEntry(index: 2)
    }

    private var historyList: some View {
        VStack(spacing: 16) {
            ForEach(Array(displayedSessions.enumerated()), id: \.element.id) { index, session in
                Button(action: { viewModel.onSelectDetail(session.id) }) {
                    historyRow(session: session, isAccent: session.source != .fitme)
                }
                .buttonStyle(.plain)
                .motionPressable(haptic: false)
                .motionEntry(index: min(index + 3, 10), enabled: !hasAnimatedHistoryList && index < 8)
                .onAppear {
                    if index == min(displayedSessions.count - 1, 7) {
                        hasAnimatedHistoryList = true
                    }
                }
            }
        }
    }

    private var missionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goal History")
                    .font(AppFonts.nunito(16, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("\(viewModel.data.completedMissions.count)")
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: "#34D399"))
            }
            VStack(spacing: 12) {
                ForEach(viewModel.data.completedMissions) { mission in
                    missionHistoryRow(mission: mission)
                }
            }
        }
        .padding(.top, 6)
    }

    private func missionHistoryRow(mission: Mission) -> some View {
        let tint: String
        let iconName: String
        switch mission.type {
        case .calories:
            tint = "#FB923C"
            iconName = "local_fire_department"
        case .minutes:
            tint = "#60A5FA"
            iconName = "timer"
        case .sessions:
            tint = "#34D399"
            iconName = "fitness_center"
        }

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: tint).opacity(0.12))
                    .frame(width: 44, height: 44)
                MaterialSymbol(name: iconName, size: 20)
                    .foregroundColor(Color(hex: tint))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(missionTitle(mission.type))
                    .font(AppFonts.nunito(15, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text("Completed • \(mission.targetValue) \(missionUnit(mission.type))")
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: tint))
            }
            Spacer()
            Text("+10 pts")
                .font(AppFonts.nunito(12, weight: .black))
                .foregroundColor(Color(hex: tint))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: tint).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
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

        let isAppleHealth = session.source == .appleHealth
        let markerColor = isAppleHealth ? Color(hex: "#66C97A") : AppTheme.accentGold
        
        return HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.elevatedSurface)
                    .frame(width: 78, height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.border.opacity(0.22), lineWidth: 1)
                    )

                VStack(spacing: 1) {
                    Text(month)
                        .font(AppFonts.plusJakarta(14, weight: .bold))
                        .foregroundColor(AppTheme.muted.opacity(0.65))
                        .textCase(.uppercase)
                    Text(day)
                        .font(AppFonts.quicksand(38, weight: .black))
                        .foregroundColor(markerColor)
                }
                .frame(width: 78, height: 88)

                Group {
                    if isAppleHealth {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#66C97A"))
                    } else {
                        MaterialSymbol(name: "pets", size: 17, style: .rounded)
                            .foregroundColor(AppTheme.accentGold)
                    }
                }
                .frame(width: 24, height: 24)
                .offset(x: 8, y: -8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Workout")
                    .font(AppFonts.quicksand(16, weight: .black))
                    .foregroundColor(AppTheme.title)
                Text("\(session.durationMinutes)m • \(session.calories)kcal • \(session.totalExercises) exercises")
                    .font(AppFonts.plusJakarta(13, weight: .medium))
                    .foregroundColor(AppTheme.muted.opacity(0.68))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(AppTheme.elevatedSurface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(isAccent ? AppTheme.success.opacity(0.22) : Color.clear, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 4)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📋")
                .font(.system(size: 48))
            Text("No workout history yet")
                .font(AppFonts.nunito(18, weight: .bold))
                .foregroundColor(AppTheme.title)
            Text("Start a workout to see your history here")
                .font(AppFonts.nunito(14, weight: .medium))
                .foregroundColor(AppTheme.muted.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
    
    private var workoutEmptyState: some View {
        VStack(spacing: 16) {
            Text("🏋️")
                .font(.system(size: 48))
            Text("No workout sessions yet")
                .font(AppFonts.nunito(18, weight: .bold))
                .foregroundColor(AppTheme.title)
            Text("Complete a workout to see it here")
                .font(AppFonts.nunito(14, weight: .medium))
                .foregroundColor(AppTheme.muted.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private var displayedSessions: [SessionSummary] {
        let sorted = viewModel.data.sessions.sorted { $0.date > $1.date }
        switch selectedPeriod {
        case "week":
            return sessions(withinLastDays: 7, from: sorted)
        case "month":
            return sessions(withinLastDays: 30, from: sorted)
        default:
            return sorted
        }
    }

    private func sessions(withinLastDays days: Int, from sessions: [SessionSummary]) -> [SessionSummary] {
        guard let threshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return sessions
        }
        return sessions.filter { session in
            guard let date = sessionDate(from: session.date) else { return false }
            return date >= threshold
        }
    }

    private var displayMonthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if let date = displayedSessions.compactMap({ sessionDate(from: $0.date) }).first {
            return formatter.string(from: date)
        }
        return formatter.string(from: Date())
    }

    private func sessionDate(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
    
    private func missionTitle(_ type: MissionType) -> String {
        switch type {
        case .calories: return "Calorie Goal"
        case .minutes: return "Active Minutes"
        case .sessions: return "Workout Sessions"
        }
    }
    
    private func missionUnit(_ type: MissionType) -> String {
        switch type {
        case .calories: return "kcal"
        case .minutes: return "min"
        case .sessions: return "sessions"
        }
    }
}
