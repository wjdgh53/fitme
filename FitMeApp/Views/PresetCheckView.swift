import SwiftUI

struct PresetCheckView: View {
    let viewModel: PresetCheckViewModel

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                VStack(spacing: 16) {
                    mascotHeader
                    energySection
                    locationSection
                    timeSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            startButton
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    .overlay(MaterialSymbol(name: "arrow_back", size: 24).foregroundColor(Color(hex: "#2d2420")))
            }
            Spacer()
            Button(action: viewModel.onClose) {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 48, height: 48)
                    .overlay(MaterialSymbol(name: "close", size: 24).foregroundColor(Color(hex: "#2d2420").opacity(0.6)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var mascotHeader: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#ee652b").opacity(0.2), Color.clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 72, height: 72)
                    .blur(radius: 6)
                AsyncImage(url: viewModel.data.mascotURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white
                }
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
            Text("Ready to start?")
                .font(AppFonts.plusJakarta(22, weight: .heavy))
                .foregroundColor(Color(hex: "#181311"))
            Text("Quick check before we sweat!")
                .font(AppFonts.plusJakarta(14, weight: .medium))
                .foregroundColor(Color(hex: "#8a7e78"))
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                MaterialSymbol(name: "ecg_heart", size: 20)
                    .foregroundColor(Color(hex: "#ee652b"))
                Text("How do you feel?")
                    .font(AppFonts.plusJakarta(18, weight: .bold))
            }
            HStack(spacing: 8) {
                energyButton(title: "Low", icon: "battery_low", isSelected: viewModel.data.energySelection == 0)
                energyButton(title: "Normal", icon: "battery_full", isSelected: viewModel.data.energySelection == 1)
                energyButton(title: "High", icon: "local_fire_department", isSelected: viewModel.data.energySelection == 2)
            }
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
    }

    private func energyButton(title: String, icon: String, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "#ee652b") : Color(hex: "#F3F4F6"))
                    .frame(width: 32, height: 32)
                MaterialSymbol(name: icon, size: 20)
                    .foregroundColor(isSelected ? .white : Color(hex: "#9CA3AF"))
            }
            Text(title)
                .font(AppFonts.plusJakarta(14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? Color(hex: "#ee652b") : Color(hex: "#9CA3AF"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isSelected ? Color(hex: "#ee652b").opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isSelected ? Color(hex: "#ee652b") : Color.clear, lineWidth: 2))
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                MaterialSymbol(name: "location_on", size: 20)
                    .foregroundColor(Color(hex: "#ee652b"))
                Text("Where are you?")
                    .font(AppFonts.plusJakarta(18, weight: .bold))
            }
            HStack(spacing: 12) {
                locationButton(title: "Home", icon: "home", isSelected: viewModel.data.locationSelection == 0)
                locationButton(title: "Gym", icon: "fitness_center", isSelected: viewModel.data.locationSelection == 1)
            }
        }
    }

    private func locationButton(title: String, icon: String, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "#ee652b") : Color(hex: "#F3F4F6"))
                    .frame(width: 40, height: 40)
                MaterialSymbol(name: icon, size: 20)
                    .foregroundColor(isSelected ? .white : Color(hex: "#6B7280"))
            }
            Text(title)
                .font(AppFonts.plusJakarta(16, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? Color(hex: "#ee652b") : Color(hex: "#6B7280"))
            Spacer()
            if isSelected {
                MaterialSymbol(name: "check_circle", size: 20)
                    .foregroundColor(Color(hex: "#ee652b"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isSelected ? Color(hex: "#ee652b") : Color(hex: "#F3F4F6"), lineWidth: 2))
        .opacity(isSelected ? 1 : 0.6)
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                MaterialSymbol(name: "timer", size: 20)
                    .foregroundColor(Color(hex: "#ee652b"))
                Text("Target Time")
                    .font(AppFonts.plusJakarta(18, weight: .bold))
            }
            HStack {
                Circle()
                    .fill(Color(hex: "#F3F4F6"))
                    .frame(width: 44, height: 44)
                    .overlay(MaterialSymbol(name: "remove", size: 20).foregroundColor(Color(hex: "#ee652b")))
                Spacer()
                VStack(spacing: -2) {
                    Text("\(viewModel.data.targetMinutes)")
                        .font(AppFonts.plusJakarta(42, weight: .black))
                        .foregroundColor(Color(hex: "#181311"))
                    Text("minutes")
                        .font(AppFonts.plusJakarta(10, weight: .bold))
                        .foregroundColor(Color(hex: "#8a7e78").opacity(0.6))
                        .tracking(2)
                }
                Spacer()
                Circle()
                    .fill(Color(hex: "#ee652b"))
                    .frame(width: 44, height: 44)
                    .shadow(color: Color(hex: "#ee652b").opacity(0.3), radius: 12, x: 0, y: 6)
                    .overlay(MaterialSymbol(name: "add", size: 20).foregroundColor(.white))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
    }

    private var startButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(height: 1)
            Button(action: viewModel.onStart) {
                HStack(spacing: 10) {
                    Text("Start My Workout")
                        .font(AppFonts.plusJakarta(18, weight: .bold))
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 26, height: 26)
                        MaterialSymbol(name: "play_arrow", size: 18)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(Color(hex: "#ee652b"))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "#FFF8F0").padding(.bottom, AppLayout.tabBarHeight))
    }
}
