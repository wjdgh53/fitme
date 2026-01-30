import SwiftUI

struct HistoryDetailView: View {
    let viewModel: HistoryDetailViewModel
    @State private var isEditMenuPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    summaryGrid
                    aiNote
                    exerciseSection
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 160)
            }
        }
    }
    
    private var dateTitle: String {
        guard let session = viewModel.data.session else { return "Workout" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: session.date) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return session.date
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(MaterialSymbol(name: "arrow_back_ios_new", size: 20).foregroundColor(Color(hex: "#3D3D3D")))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            Spacer()
            Text(dateTitle)
                .font(AppFonts.nunito(20, weight: .heavy))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Button(action: { isEditMenuPresented = true }) {
                Text("Edit")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#FF8577"))
                    .clipShape(Capsule())
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
            summaryCard(title: "Time", value: "\(viewModel.data.session?.durationMinutes ?? 0)", unit: "m", icon: "timer", color: "#60A5FA")
            summaryCard(title: "Calories", value: "\(viewModel.data.session?.calories ?? 0)", unit: "kcal", icon: "local_fire_department", color: "#6EE7B7")
            summaryCard(title: "Exercises", value: "\(viewModel.data.session?.exercises.count ?? 0)", unit: "", icon: "fitness_center", color: "#A78BFA")
        }
    }

    private func summaryCard(title: String, value: String, unit: String, icon: String, color: String) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(hex: color).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(MaterialSymbol(name: icon, size: 22).foregroundColor(Color(hex: color)))
            Text(title.uppercased())
                .font(AppFonts.nunito(10, weight: .bold))
                .tracking(1)
                .foregroundColor(Color(hex: "#78716C"))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFonts.nunito(20, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.nunito(12, weight: .bold))
                        .foregroundColor(Color(hex: "#78716C"))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private var aiNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: "#FCD34D"))
                .frame(width: 48, height: 48)
                .overlay(MaterialSymbol(name: "sentiment_very_satisfied", size: 28).foregroundColor(.white))
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("FitCoach AI")
                        .font(AppFonts.nunito(12, weight: .black))
                        .foregroundColor(Color(hex: "#FF8577"))
                    MaterialSymbol(name: "auto_awesome", size: 16)
                        .foregroundColor(Color(hex: "#FF8577"))
                }
                Text("Great workout! You crushed it! 🎉")
                    .font(AppFonts.nunito(13, weight: .bold))
                    .foregroundColor(Color(hex: "#78716C"))
                    .lineSpacing(2)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercises")
                    .font(AppFonts.nunito(20, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                if let session = viewModel.data.session {
                    Text("\(session.exercises.count) exercises")
                        .font(AppFonts.nunito(11, weight: .bold))
                        .foregroundColor(Color(hex: "#FF8577"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#FF8577").opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            if let session = viewModel.data.session {
                ForEach(session.exercises.indices, id: \.self) { index in
                    let exercise = session.exercises[index]
                    exerciseCard(
                        title: exercise.exerciseId.replacingOccurrences(of: "_", with: " ").capitalized,
                        badge: index == 0 ? "BEST" : nil,
                        tag: "Exercise",
                        sets: exercise.sets.map { ("\(Int($0.weight))", "\($0.reps)") }
                    )
                }
            }
        }
    }

    private func exerciseCard(title: String, badge: String?, tag: String, sets: [(String, String)]) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#FFF8F0"))
                    .frame(width: 56, height: 56)
                    .overlay(MaterialSymbol(name: "fitness_center", size: 24).foregroundColor(Color(hex: "#FF8577")))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(AppFonts.nunito(18, weight: .bold))
                            .foregroundColor(Color(hex: "#3D3D3D"))
                        if let badge = badge {
                            Text(badge)
                                .font(AppFonts.nunito(9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#FCD34D"))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                    Text(tag)
                        .font(AppFonts.nunito(11, weight: .bold))
                        .foregroundColor(Color(hex: "#A8A29E"))
                }
                Spacer()
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Set")
                    Spacer()
                    Text("Weight")
                    Spacer()
                    Text("Reps")
                    Spacer()
                    Text(" ")
                }
                .font(AppFonts.nunito(11, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))

                ForEach(sets.indices, id: \.self) { index in
                    let set = sets[index]
                    HStack {
                        Text("\(index + 1)")
                            .frame(width: 36)
                        Text("\(set.0) lb")
                            .frame(maxWidth: .infinity)
                        Text(set.1)
                            .frame(maxWidth: .infinity)
                        MaterialSymbol(name: "check_circle", size: 20)
                            .foregroundColor(Color(hex: "#6EE7B7"))
                            .frame(width: 36)
                    }
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                    .padding(.vertical, 8)
                    .background(Color(hex: "#F5F5F4"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.onShare) {
                HStack(spacing: 6) {
                    MaterialSymbol(name: "share", size: 18)
                    Text("Share")
                        .font(AppFonts.nunito(16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#FF8577"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color(hex: "#FF8577").opacity(0.25), radius: 10, x: 0, y: 5)
            }

            Button(action: viewModel.onHome) {
                HStack(spacing: 6) {
                    MaterialSymbol(name: "home", size: 18)
                    Text("Home")
                        .font(AppFonts.nunito(16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#22C55E"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color(hex: "#22C55E").opacity(0.25), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.top, 4)
    }
}
