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
                        recommended
                        quickStats
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            startWorkoutArea
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: viewModel.data.profileImageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

                    Circle()
                        .fill(AppColors.mint)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }

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
                    if index < viewModel.data.weeklyGoals.count {
                        let goal = viewModel.data.weeklyGoals[index]
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(hex: goal.colorHex).opacity(0.1))
                                    .frame(width: 40, height: 40)
                                MaterialSymbol(name: goal.icon, size: 20)
                                    .foregroundColor(Color(hex: goal.colorHex))
                            }
                            VStack(spacing: 0) {
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text(goal.value)
                                        .font(AppFonts.quicksand(20, weight: .black))
                                        .foregroundColor(AppColors.textMain)
                                    Text(goal.valueSuffix)
                                        .font(AppFonts.quicksand(12, weight: .semibold))
                                        .foregroundColor(Color(hex: "#888888"))
                                }
                                Text(goal.title.uppercased())
                                    .font(AppFonts.quicksand(10, weight: .bold))
                                    .foregroundColor(Color(hex: "#888888"))
                            }
                            Spacer(minLength: 0)
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(AppColors.cream)
                                    .frame(height: 4)
                                Rectangle()
                                    .fill(Color(hex: goal.colorHex))
                                    .frame(width: 60 * goal.progress, height: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#FFE4C4"), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                    } else {
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
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onOpenWeeklyGoals()
        }
    }

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements 🏆")
                .font(AppFonts.quicksand(18, weight: .heavy))
                .foregroundColor(AppColors.textMain)

            HStack(spacing: 16) {
                ForEach(viewModel.data.achievements.indices, id: \.self) { index in
                    let item = viewModel.data.achievements[index]
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                                MaterialSymbol(name: item.icon, size: 18)
                                    .foregroundColor(Color(hex: item.colorHex))
                            }
                            Text(item.title)
                                .font(AppFonts.quicksand(12, weight: .bold))
                                .foregroundColor(AppColors.textMain.opacity(0.7))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.value)
                                .font(AppFonts.quicksand(28, weight: .black))
                                .foregroundColor(Color(hex: item.colorHex))
                            if !item.subtitle.isEmpty {
                                Text(item.subtitle)
                                    .font(AppFonts.quicksand(10, weight: .bold))
                                    .foregroundColor(AppColors.textMain.opacity(0.5))
                            } else {
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.white.opacity(0.5))
                                    .frame(height: 10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 999).fill(Color(hex: item.colorHex)).frame(width: 70, height: 10)
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.white.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
                    .background(Color(hex: item.backgroundHex).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        MaterialSymbol(name: item.icon, size: 80)
                            .foregroundColor(Color.black.opacity(0.06))
                            .rotationEffect(.degrees(12))
                            .offset(x: 32, y: 32),
                        alignment: .bottomTrailing
                    )
                }
            }
        }
    }

    private var recommended: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended ✨")
                .font(AppFonts.quicksand(18, weight: .heavy))
                .foregroundColor(AppColors.textMain)

            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(AppColors.cream, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.data.recommended.badge)
                        .font(AppFonts.quicksand(10, weight: .heavy))
                        .foregroundColor(Color(hex: "#F59E0B"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#FCD34D").opacity(0.3))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: "#FCD34D").opacity(0.1), lineWidth: 1))

                    Text(viewModel.data.recommended.title)
                        .font(AppFonts.quicksand(24, weight: .black))
                        .foregroundColor(AppColors.textMain)

                    Text(viewModel.data.recommended.subtitle)
                        .font(AppFonts.quicksand(14, weight: .semibold))
                        .foregroundColor(Color(hex: "#888888"))

                    HStack(spacing: 6) {
                        MaterialSymbol(name: "play_circle", size: 18)
                        Text(viewModel.data.recommended.cta)
                            .font(AppFonts.quicksand(14, weight: .bold))
                    }
                    .foregroundColor(AppColors.peach)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.peach.opacity(0.05))
                    .clipShape(Capsule())
                }
                .padding(20)
                .padding(.trailing, 80)

                Circle()
                    .fill(AppColors.peach)
                    .frame(width: 144, height: 144)
                    .opacity(0.9)
                    .offset(x: 50, y: -30)
            }
            .onTapGesture {
                viewModel.onOpenExerciseDetail()
            }
        }
    }

    private var quickStats: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.data.quickStats.indices, id: \.self) { index in
                    let stat = viewModel.data.quickStats[index]
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(hex: stat.colorHex).opacity(0.1))
                                .frame(width: 40, height: 40)
                            MaterialSymbol(name: stat.icon, size: 20)
                                .foregroundColor(Color(hex: stat.colorHex))
                        }
                        Text(stat.title.uppercased())
                            .font(AppFonts.quicksand(10, weight: .bold))
                            .foregroundColor(Color(hex: "#888888"))
                        Text(stat.value)
                            .font(AppFonts.quicksand(20, weight: .black))
                            .foregroundColor(AppColors.textMain)
                    }
                    .padding(16)
                    .frame(width: 140)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#FFE4C4"), lineWidth: 2))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.bottom, 12)
        .onTapGesture {
            viewModel.onOpenLibrary()
        }
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
