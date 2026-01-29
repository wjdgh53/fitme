import SwiftUI

struct GoalEditView: View {
    let viewModel: GoalEditViewModel
    @State private var calories: Int
    @State private var minutes: Int
    @State private var sessions: Int

    init(viewModel: GoalEditViewModel) {
        self.viewModel = viewModel
        _calories = State(initialValue: viewModel.caloriesTarget)
        _minutes = State(initialValue: viewModel.minutesTarget)
        _sessions = State(initialValue: viewModel.sessionsTarget)
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                VStack(spacing: 16) {
                    goalRow(title: "Calories", value: calories, unit: "kcal", onDecrease: { calories = max(0, calories - 100) }, onIncrease: { calories += 100 })
                    goalRow(title: "Time (min)", value: minutes, unit: "min", onDecrease: { minutes = max(0, minutes - 10) }, onIncrease: { minutes += 10 })
                    goalRow(title: "Sessions", value: sessions, unit: "", onDecrease: { sessions = max(0, sessions - 1) }, onIncrease: { sessions += 1 })
                }
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

                Button(action: { viewModel.onSave(calories, minutes, sessions) }) {
                    Text("Save Goal")
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
        }
    }
}
