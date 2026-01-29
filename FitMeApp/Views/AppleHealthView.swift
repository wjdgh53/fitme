import SwiftUI

struct AppleHealthView: View {
    let viewModel: AppleHealthViewModel
    @State private var workouts: Bool = true
    @State private var calories: Bool = true
    @State private var sleep: Bool = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                statusCard
                permissionsCard

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
            Text("Apple Health")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(AppFonts.nunito(12, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
            HStack {
                Text("Connected")
                    .font(AppFonts.nunito(16, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("Manage")
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: "#FF8577"))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Access")
                .font(AppFonts.nunito(12, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
            toggleRow(label: "Workouts", isOn: $workouts)
            toggleRow(label: "Active Calories", isOn: $calories)
            toggleRow(label: "Sleep", isOn: $sleep)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: "#FF8577"))
        }
        .padding(.vertical, 6)
    }
}
