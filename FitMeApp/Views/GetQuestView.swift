import SwiftUI

struct GetQuestView: View {
    let viewModel: GetQuestViewModel
    @State private var calories: Int
    @State private var minutes: Int
    @State private var sessions: Int
    @State private var showCalories: Bool = true
    @State private var showMinutes: Bool = true
    @State private var showSessions: Bool = true

    init(viewModel: GetQuestViewModel) {
        self.viewModel = viewModel
        _calories = State(initialValue: viewModel.caloriesDefault)
        _minutes = State(initialValue: viewModel.minutesDefault)
        _sessions = State(initialValue: viewModel.sessionsDefault)
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                VStack(spacing: 8) {
                    Text("AI Suggested Mission")
                        .font(AppFonts.nunito(16, weight: .black))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    Text("(mocked)")
                        .font(AppFonts.nunito(11, weight: .bold))
                        .foregroundColor(Color(hex: "#A8A29E"))
                }

                VStack(spacing: 12) {
                    if showCalories {
                        goalCard(title: "Calories", value: calories, unit: "kcal", onDecrease: { calories = max(0, calories - 100) }, onIncrease: { calories += 100 }, onDelete: { showCalories = false })
                    }
                    if showMinutes {
                        goalCard(title: "Time (min)", value: minutes, unit: "min", onDecrease: { minutes = max(0, minutes - 10) }, onIncrease: { minutes += 10 }, onDelete: { showMinutes = false })
                    }
                    if showSessions {
                        goalCard(title: "Sessions", value: sessions, unit: "", onDecrease: { sessions = max(0, sessions - 1) }, onIncrease: { sessions += 1 }, onDelete: { showSessions = false })
                    }
                }

                Button(action: { viewModel.onConfirm(selectedCalories, selectedMinutes, selectedSessions) }) {
                    Text("Confirm & Create Goal")
                        .font(AppFonts.nunito(16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#FF8577"))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(MaterialSymbol(name: "arrow_back_ios_new", size: 18).foregroundColor(Color(hex: "#3D3D3D")))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            Spacer()
            Text("Get a Quest")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private func goalCard(title: String, value: Int, unit: String, onDecrease: @escaping () -> Void, onIncrease: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                HStack(spacing: 4) {
                    Text(formattedValue(value))
                        .font(AppFonts.nunito(18, weight: .black))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(AppFonts.nunito(11, weight: .bold))
                            .foregroundColor(Color(hex: "#A8A29E"))
                    }
                }
            }
            Spacer()
            Button(action: onDecrease) {
                Circle()
                    .fill(Color(hex: "#F3F4F6"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "remove", size: 18).foregroundColor(Color(hex: "#FF8577")))
            }
            Button(action: onIncrease) {
                Circle()
                    .fill(Color(hex: "#FF8577"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "add", size: 18).foregroundColor(.white))
            }
            Button(action: onDelete) {
                Circle()
                    .fill(Color(hex: "#FEE2E2"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "close", size: 16).foregroundColor(Color(hex: "#EF4444")))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func formattedValue(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var selectedCalories: Int {
        showCalories ? calories : 0
    }

    private var selectedMinutes: Int {
        showMinutes ? minutes : 0
    }

    private var selectedSessions: Int {
        showSessions ? sessions : 0
    }
}
