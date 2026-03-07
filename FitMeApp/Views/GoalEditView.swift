import SwiftUI

struct GoalEditView: View {
    let viewModel: GoalEditViewModel
    @State private var calories: Int = 1200
    @State private var minutes: Int = 150
    @State private var sessions: Int = 3
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    init(viewModel: GoalEditViewModel) {
        self.viewModel = viewModel
        // Initialize from existing missions if available
        if let caloriesMission = viewModel.missions.first(where: { $0.type == .calories }) {
            _calories = State(initialValue: caloriesMission.targetValue)
        }
        if let minutesMission = viewModel.missions.first(where: { $0.type == .minutes }) {
            _minutes = State(initialValue: minutesMission.targetValue)
        }
        if let sessionsMission = viewModel.missions.first(where: { $0.type == .sessions }) {
            _sessions = State(initialValue: sessionsMission.targetValue)
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                VStack(spacing: 16) {
                    goalRow(title: "Calories", value: calories, unit: "kcal", onDecrease: { calories = max(100, calories - 100) }, onIncrease: { calories += 100 })
                    goalRow(title: "Time (min)", value: minutes, unit: "min", onDecrease: { minutes = max(10, minutes - 10) }, onIncrease: { minutes += 10 })
                    goalRow(title: "Sessions", value: sessions, unit: "", onDecrease: { sessions = max(1, sessions - 1) }, onIncrease: { sessions += 1 })
                }
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

                if let error = errorMessage {
                    Text(error)
                        .font(AppFonts.nunito(13, weight: .medium))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        isLoading = true
                        errorMessage = nil
                        var firstError: String? = nil
                        let calError = await viewModel.onSave(.calories, .medium, calories)
                        let minError = await viewModel.onSave(.minutes, .medium, minutes)
                        let sesError = await viewModel.onSave(.sessions, .medium, sessions)
                        firstError = calError ?? minError ?? sesError
                        isLoading = false
                        if let err = firstError {
                            errorMessage = err
                        } else {
                            viewModel.onBack()
                        }
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#FF8577"))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        Text("Save Goal")
                            .font(AppFonts.nunito(16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#FF8577"))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .disabled(isLoading)

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
            Text("Edit Goal")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private func goalRow(title: String, value: Int, unit: String, onDecrease: @escaping () -> Void, onIncrease: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Button(action: onDecrease) {
                Circle()
                    .fill(Color(hex: "#F3F4F6"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "remove", size: 18).foregroundColor(Color(hex: "#FF8577")))
            }
            .disabled(isLoading)
            HStack(spacing: 4) {
                Text("\(value)")
                    .font(AppFonts.nunito(16, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.nunito(11, weight: .bold))
                        .foregroundColor(Color(hex: "#A8A29E"))
                }
            }
            Button(action: onIncrease) {
                Circle()
                    .fill(Color(hex: "#FF8577"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "add", size: 18).foregroundColor(.white))
            }
            .disabled(isLoading)
        }
    }
}
