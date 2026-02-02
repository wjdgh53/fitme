import SwiftUI

struct WorkoutPreviewView2: View {
    @ObservedObject var viewModel: WorkoutPreviewViewModel

    var body: some View {
        ZStack {
            Color(hex: "#FFF9F6")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        titleSection
                        coachCard
                        routineList
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomAction
        }
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(MaterialSymbol(name: "arrow_back", size: 20).foregroundColor(Color(hex: "#2D2D2D")))
                    .overlay(Circle().stroke(Color(hex: "#F3F4F6"), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
            Spacer()
            Text("Preview")
                .font(AppFonts.nunito(10, weight: .bold))
                .tracking(2)
                .foregroundColor(Color(hex: "#9CA3AF").opacity(0.6))
            Spacer()
            Button(action: viewModel.onMore) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(MaterialSymbol(name: "more_horiz", size: 20).foregroundColor(Color(hex: "#2D2D2D")))
                    .overlay(Circle().stroke(Color(hex: "#F3F4F6"), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.data.title)
                .font(AppFonts.nunito(30, weight: .heavy))
                .foregroundColor(Color(hex: "#2D2D2D"))
            HStack(spacing: 10) {
                infoChip(icon: "timer", color: "#6EE7B7", text: viewModel.data.duration)
                infoChip(icon: "bolt", color: "#FCD34D", text: viewModel.data.energy)
                infoChip(icon: "local_fire_department", color: "#FF8577", text: viewModel.data.calories)
            }
        }
    }

    private func infoChip(icon: String, color: String, text: String) -> some View {
        HStack(spacing: 6) {
            MaterialSymbol(name: icon, size: 18)
                .foregroundColor(Color(hex: color))
            Text(text)
                .font(AppFonts.nunito(13, weight: .bold))
                .foregroundColor(Color(hex: "#2D2D2D").opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
    }

    private var coachCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#F3F4F6"), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color(hex: "#F3F4F6"))
                    .frame(width: 40, height: 40)
                    .overlay(MaterialSymbol(name: "sentiment_satisfied", size: 22).foregroundColor(Color(hex: "#6EE7B7")))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Coach Says")
                        .font(AppFonts.nunito(11, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                    Text("\"\(viewModel.data.coachNote)\"")
                        .font(AppFonts.nunito(15, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D2D2D"))
                        .lineSpacing(3)
                }
            }
            .padding(16)

            Circle()
                .fill(Color(hex: "#6EE7B7").opacity(0.05))
                .frame(width: 128, height: 128)
                .blur(radius: 12)
                .offset(x: 32, y: -24)
        }
    }

    private var routineList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Routine")
                    .font(AppFonts.nunito(18, weight: .bold))
                Spacer()
                Text("\(viewModel.data.exercises.count) Moves")
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color(hex: "#F3F4F6"), lineWidth: 1))
            }

            VStack(spacing: 10) {
                ForEach(viewModel.data.exercises) { exercise in
                    routineRow(exercise: exercise)
                }
            }
        }
    }

    private func routineRow(exercise: WorkoutPlanExercise) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseId.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(AppFonts.nunito(15, weight: .bold))
                    .foregroundColor(Color(hex: "#2D2D2D"))
                Text("\(exercise.sets.count) sets")
                    .font(AppFonts.nunito(12, weight: .medium))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "#F3F4F6"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "sync", size: 18).foregroundColor(Color(hex: "#9CA3AF")))
                MaterialSymbol(name: "chevron_right", size: 20)
                    .foregroundColor(Color(hex: "#D1D5DB"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(height: 1)
            Button(action: viewModel.onStart) {
                Text("Start Workout")
                    .font(AppFonts.nunito(17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#FF8577"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.95).padding(.bottom, AppLayout.tabBarHeight))
    }
}
