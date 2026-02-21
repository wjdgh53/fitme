import SwiftUI

struct AppSettingsView: View {
    let viewModel: AppSettingsViewModel
    @State private var workoutReminder: Bool = true
    @State private var weeklySummary: Bool = true
    @StateObject private var connectivity = ConnectivityStatus()
    @State private var showsWatchGuide = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                sectionCard(title: "Units") {
                    settingsRow(label: "Weight", value: "kg")
                    settingsRow(label: "Height", value: "cm")
                }

                sectionCard(title: "Notifications") {
                    toggleRow(label: "Workout Reminder", isOn: $workoutReminder)
                    toggleRow(label: "Weekly Summary", isOn: $weeklySummary)
                }

                sectionCard(title: "Apple Health") {
                    statusRow(isConnected: connectivity.isAppleHealthConnected) {
                        connectivity.requestAppleHealthAuthorization()
                    }
                }

                sectionCard(title: "Apple Watch") {
                    statusRow(isConnected: connectivity.isAppleWatchConnected) {
                        showsWatchGuide = true
                        connectivity.refresh()
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .onAppear { connectivity.refresh() }
        .alert("Connect Apple Watch", isPresented: $showsWatchGuide) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open the Watch app and complete pairing to enable sync.")
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
            Text("App Settings")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFonts.nunito(12, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
            VStack(spacing: 10) {
                content()
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Text(value)
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#78716C"))
        }
        .padding(.vertical, 6)
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

    private func statusRow(isConnected: Bool, action: @escaping () -> Void) -> some View {
        let statusText = isConnected ? "Connected" : "Not Connected"
        let statusColor = isConnected ? Color(hex: "#16A34A") : Color(hex: "#FF8577")
        let statusBackground = isConnected ? Color(hex: "#DCFCE7") : Color(hex: "#FFE6E3")

        return Button(action: action) {
            HStack {
                Text("Status")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text(statusText)
                    .font(AppFonts.nunito(12, weight: .black))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusBackground)
                    .clipShape(Capsule())
                if !isConnected {
                    MaterialSymbol(name: "chevron_right", size: 18)
                        .foregroundColor(Color(hex: "#A8A29E"))
                }
            }
            .padding(.vertical, 6)
        }
        .disabled(isConnected)
    }
}
