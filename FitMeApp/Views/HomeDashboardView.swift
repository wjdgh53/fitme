import SwiftUI

struct HomeDashboardView: View {
    let viewModel: HomeDashboardViewModel

    var body: some View {
        ZStack {
            AppColors.cream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        weeklyGoals
                        achievements
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .refreshable {
                    await viewModel.onRefresh()
                }
            }
            
            if viewModel.data.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .safeAreaInset(edge: .bottom) {
            startWorkoutArea
        }
        .task {
            await viewModel.onRefresh()
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    if let url = viewModel.data.profileImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(AppColors.peach.opacity(0.3))
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.peach.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(viewModel.data.userName.prefix(1)).uppercased())
                                    .font(AppFonts.quicksand(20, weight: .bold))
                                    .foregroundColor(AppColors.peach)
                            )
                    }

                    Circle()
                        .fill(AppColors.mint)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Hi, \(viewModel.data.userName)! 👋")
                        .font(AppFonts.quicksand(12, weight: .bold))
                        .foregroundColor(Color(hex: "#888888"))
                    Text(viewModel.data.greeting)
                        .font(AppFonts.quicksand(20, weight: .heavy))
                        .foregroundColor(AppColors.textMain)
                }
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColors.cream, lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                MaterialSymbol(name: "notifications", size: 24)
                    .foregroundColor(AppColors.textMain)
                Circle()
                    .fill(AppColors.peach)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    .offset(x: 10, y: -10)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var weeklyGoals: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Goals 🎯")
                .font(AppFonts.quicksand(18, weight: .heavy))
                .foregroundColor(AppColors.textMain)

            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    if index < viewModel.data.missions.count {
                        let mission = viewModel.data.missions[index]
                        missionCard(mission: mission)
                    } else {
                        emptyMissionCard
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onOpenWeeklyGoals()
        }
    }
    
    private func missionCard(mission: Mission) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: mission.colorHex).opacity(0.1))
                    .frame(width: 40, height: 40)
                MaterialSymbol(name: mission.icon, size: 20)
                    .foregroundColor(Color(hex: mission.colorHex))
            }
            VStack(spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(mission.displayValue)
                        .font(AppFonts.quicksand(20, weight: .black))
                        .foregroundColor(AppColors.textMain)
                    Text(mission.valueSuffix)
                        .font(AppFonts.quicksand(12, weight: .semibold))
                        .foregroundColor(Color(hex: "#888888"))
                }
                Text(mission.displayTitle.uppercased())
                    .font(AppFonts.quicksand(10, weight: .bold))
                    .foregroundColor(Color(hex: "#888888"))
            }
            Spacer(minLength: 0)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppColors.cream)
                    .frame(height: 4)
                Rectangle()
                    .fill(Color(hex: mission.colorHex))
                    .frame(width: 60 * mission.progress, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#FFE4C4"), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private var emptyMissionCard: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .overlay(MaterialSymbol(name: "add", size: 18).foregroundColor(Color(hex: "#F59E0B")))
            Text("새 미션을\n받아보세요!")
                .font(AppFonts.quicksand(11, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "#A8A29E"))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#FFE4C4"), style: StrokeStyle(lineWidth: 2, dash: [4, 4])))
    }

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements 🏆")
                .font(AppFonts.quicksand(18, weight: .heavy))
                .foregroundColor(AppColors.textMain)

            HStack(spacing: 16) {
                // Points card
                achievementCard(
                    icon: "stars",
                    title: "Points",
                    value: formatNumber(viewModel.data.totalPoints),
                    subtitle: "Top 10% this week!",
                    colorHex: "#34D399",
                    backgroundHex: "#D1FAE5"
                )
                
                // Rank card
                achievementCard(
                    icon: "emoji_events",
                    title: "League",
                    value: viewModel.data.rank,
                    subtitle: "",
                    colorHex: "#F59E0B",
                    backgroundHex: "#FEF3C7"
                )
            }
        }
    }
    
    private func achievementCard(icon: String, title: String, value: String, subtitle: String, colorHex: String, backgroundHex: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                    MaterialSymbol(name: icon, size: 18)
                        .foregroundColor(Color(hex: colorHex))
                }
                Text(title)
                    .font(AppFonts.quicksand(12, weight: .bold))
                    .foregroundColor(AppColors.textMain.opacity(0.7))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(AppFonts.quicksand(28, weight: .black))
                    .foregroundColor(Color(hex: colorHex))
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFonts.quicksand(10, weight: .bold))
                        .foregroundColor(AppColors.textMain.opacity(0.5))
                } else {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999).fill(Color(hex: colorHex)).frame(width: 70, height: 10)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(Color(hex: backgroundHex).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            MaterialSymbol(name: icon, size: 80)
                .foregroundColor(Color.black.opacity(0.06))
                .rotationEffect(.degrees(12))
                .offset(x: 32, y: 32),
            alignment: .bottomTrailing
        )
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private var startWorkoutArea: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(height: 1)
            Button(action: viewModel.onStartWorkout) {
                HStack(spacing: 8) {
                    MaterialSymbol(name: "play_arrow", size: 24)
                    Text("Start Workout")
                        .font(AppFonts.quicksand(16, weight: .heavy))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.peach)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppColors.peachDark.opacity(0.25), lineWidth: 2))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
}
