import SwiftUI

struct HistoryDetailView: View {
    @ObservedObject var viewModel: HistoryDetailViewModel
    @State private var isEditMenuPresented = false

    var body: some View {
        ZStack {
            AppTheme.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    summaryGrid
                    coachBubble
                    exercisesHeader
                    exerciseCards
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, AppLayout.tabBarHeight + 28)
            }
        }
    }

    private var session: SessionDetail? {
        viewModel.data.session
    }

    private var dateTitle: String {
        guard let session else { return "Workout" }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: session.date) else { return session.date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(AppTheme.elevatedSurface.opacity(0.95))
                    .frame(width: 50, height: 50)
                    .overlay(
                        MaterialSymbol(name: "arrow_back_ios_new", size: 20)
                            .foregroundColor(AppTheme.title)
                    )
                    .overlay(Circle().stroke(AppTheme.border.opacity(0.3), lineWidth: 1))
            }

            Spacer()

            Text(dateTitle)
                .font(AppFonts.plusJakarta(20, weight: .bold))
                .foregroundColor(AppTheme.title)

            Spacer()

            Button(action: { isEditMenuPresented = true }) {
                Text("Edit")
                    .font(AppFonts.plusJakarta(16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.primaryButton)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.primaryButtonPressed.opacity(0.6), lineWidth: 1))
            }
            .confirmationDialog("Edit Workout", isPresented: $isEditMenuPresented) {
                Button("Delete Workout", role: .destructive, action: viewModel.onDelete)
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(.top, 6)
    }

    private var summaryGrid: some View {
        HStack(spacing: 12) {
            summaryCard(title: "TIME",
                        value: "\(session?.durationMinutes ?? 0)",
                        unit: "m",
                        icon: "timer",
                        iconTint: Color(hex: "#7EB2FF"))
            summaryCard(title: "CALORIES",
                        value: "\(session?.calories ?? 0)",
                        unit: "kcal",
                        icon: "local_fire_department",
                        iconTint: Color(hex: "#74D9B0"))
            summaryCard(title: "EXERCISES",
                        value: "\(session?.exercises.count ?? 0)",
                        unit: "",
                        icon: "fitness_center",
                        iconTint: Color(hex: "#B6A0F2"))
        }
    }

    private func summaryCard(title: String, value: String, unit: String, icon: String, iconTint: Color) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(iconTint.opacity(0.22))
                .frame(width: 44, height: 44)
                .overlay(
                    MaterialSymbol(name: icon, size: 20)
                        .foregroundColor(iconTint)
                )

            Text(title)
                .font(AppFonts.plusJakarta(10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.muted.opacity(0.72))

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFonts.quicksand(36, weight: .black))
                    .foregroundColor(AppTheme.title)
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.plusJakarta(12, weight: .bold))
                        .foregroundColor(AppTheme.muted.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 154)
        .padding(.vertical, 2)
        .background(AppTheme.elevatedSurface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.border.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private var coachBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppTheme.primaryButton)
                .frame(width: 52, height: 52)
                .overlay(
                    MaterialSymbol(name: "mood", size: 24, style: .rounded)
                        .foregroundColor(.white)
                )
                .overlay(Circle().stroke(AppTheme.elevatedSurface, lineWidth: 3))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("FitCoach AI")
                        .font(AppFonts.plusJakarta(16, weight: .bold))
                        .foregroundColor(AppTheme.primaryButton)
                    MaterialSymbol(name: "auto_awesome", size: 16)
                        .foregroundColor(AppTheme.primaryButton)
                }
                Text("Great workout! You crushed it!")
                    .font(AppFonts.plusJakarta(16, weight: .bold))
                    .foregroundColor(AppTheme.subtitle)
                    .lineLimit(2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.elevatedSurface.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.top, 2)
    }

    private var exercisesHeader: some View {
        HStack {
            Text("Exercises")
                .font(AppFonts.quicksand(38, weight: .black))
                .foregroundColor(AppTheme.title)

            Spacer()

            Text("\(session?.exercises.count ?? 0) exercises")
                .font(AppFonts.plusJakarta(15, weight: .bold))
                .foregroundColor(AppTheme.primaryButton)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.elevatedSurface.opacity(0.8))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.border.opacity(0.22), lineWidth: 1))
        }
        .padding(.top, 6)
    }

    private var exerciseCards: some View {
        VStack(spacing: 12) {
            if let session {
                ForEach(session.exercises.indices, id: \.self) { index in
                    exerciseCard(exercise: session.exercises[index])
                }
            } else {
                emptyStateCard
            }
        }
    }

    private func exerciseCard(exercise: SessionExercise) -> some View {
        let setColumnWidth: CGFloat = 52
        let repsColumnWidth: CGFloat = 72

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        MaterialSymbol(name: "pets", size: 14, style: .rounded)
                            .foregroundColor(AppTheme.accentGold)
                        Text(exerciseDisplayName(exercise.exerciseId))
                            .font(AppFonts.quicksand(28, weight: .black))
                            .foregroundColor(AppTheme.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Text("Exercise")
                        .font(AppFonts.plusJakarta(12, weight: .bold))
                        .foregroundColor(AppTheme.muted.opacity(0.6))
                }
                Spacer()
            }

            HStack(spacing: 0) {
                Text("Set")
                    .frame(width: setColumnWidth, alignment: .center)
                Rectangle()
                    .fill(AppTheme.cardBorderGold.opacity(0.45))
                    .frame(width: 1, height: 18)
                Text("Weight")
                    .frame(maxWidth: .infinity, alignment: .center)
                Rectangle()
                    .fill(AppTheme.cardBorderGold.opacity(0.45))
                    .frame(width: 1, height: 18)
                Text("Reps")
                    .frame(width: repsColumnWidth, alignment: .center)
            }
            .font(AppFonts.plusJakarta(13, weight: .bold))
            .foregroundColor(AppTheme.muted.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(AppTheme.cardGold.opacity(0.34))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.cardBorderGold.opacity(0.52), lineWidth: 1)
            )

            if exercise.sets.isEmpty {
                Text("No set data")
                    .font(AppFonts.plusJakarta(14, weight: .medium))
                    .foregroundColor(AppTheme.muted.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.elevatedSurface.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { idx, set in
                        HStack(spacing: 0) {
                            Text("\(idx + 1)")
                                .frame(width: setColumnWidth, alignment: .center)
                            Rectangle()
                                .fill(AppTheme.cardBorderGold.opacity(0.32))
                                .frame(width: 1, height: 18)
                            Text("\(formatWeight(set.weight)) lb")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Rectangle()
                                .fill(AppTheme.cardBorderGold.opacity(0.32))
                                .frame(width: 1, height: 18)
                            Text("\(set.reps)")
                                .frame(width: repsColumnWidth, alignment: .center)
                        }
                        .font(AppFonts.plusJakarta(16, weight: .bold))
                        .foregroundColor(AppTheme.title)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(AppTheme.elevatedSurface.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.cardBorderGold.opacity(0.34), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppTheme.elevatedSurface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AppTheme.border.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 4)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            MaterialSymbol(name: "fitness_center", size: 42, style: .rounded)
                .foregroundColor(AppTheme.primaryButton)
            Text("No exercise data")
                .font(AppFonts.plusJakarta(16, weight: .bold))
                .foregroundColor(AppTheme.title)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(AppTheme.elevatedSurface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func exerciseDisplayName(_ raw: String) -> String {
        raw
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
