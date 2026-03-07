import SwiftUI

struct PresetCheckView: View {
    let viewModel: PresetCheckViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var energySelection: Int
    @State private var locationSelection: Int
    @State private var targetMinutes: Int
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let minTargetMinutes = 15
    private let maxTargetMinutes = 180
    private let targetStep = 5

    init(viewModel: PresetCheckViewModel) {
        self.viewModel = viewModel
        _energySelection = State(initialValue: viewModel.data.energySelection)
        _locationSelection = State(initialValue: viewModel.data.locationSelection)
        _targetMinutes = State(initialValue: viewModel.data.targetMinutes)
    }
    
    private var conditionString: String {
        switch energySelection {
        case 0: return "low"
        case 2: return "high"
        default: return "normal"
        }
    }
    
    private var locationString: String {
        locationSelection == 0 ? "home" : "gym"
    }

    private var equipmentList: [String] {
        locationSelection == 0 ? viewModel.data.homeEquipment : []
    }

    var body: some View {
        ZStack {
            AppTheme.appBackground
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
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Generating your workout...")
                        .font(AppFonts.plusJakarta(16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isLoading)
        .safeAreaInset(edge: .bottom) {
            startButton
        }
        .alert("Workout Generation Failed", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Please try again")
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(AppTheme.elevatedSurface)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    .overlay(MaterialSymbol(name: "arrow_back", size: 24).foregroundColor(AppTheme.title))
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: viewModel.onClose) {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 48, height: 48)
                    .overlay(MaterialSymbol(name: "close", size: 24).foregroundColor(AppTheme.subtitle.opacity(0.75)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .motionEntry(index: 0)
    }

    private var mascotHeader: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppTheme.primaryButton.opacity(0.22), Color.clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 72, height: 72)
                    .blur(radius: 6)
                Circle()
                    .fill(AppTheme.cardGold.opacity(0.46))
                    .frame(width: 72, height: 72)
                    .overlay(
                        MaterialSymbol(name: "fitness_center", size: 32)
                            .foregroundColor(AppTheme.accentGold)
                    )
                    .overlay(Circle().stroke(AppTheme.elevatedSurface, lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
            Text("Ready to start?")
                .font(AppFonts.plusJakarta(22, weight: .heavy))
                .foregroundColor(AppTheme.title)
            Text("Quick check before we sweat!")
                .font(AppFonts.plusJakarta(14, weight: .medium))
                .foregroundColor(AppTheme.subtitle)
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .motionEntry(index: 1)
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                MaterialSymbol(name: "ecg_heart", size: 20)
                    .foregroundColor(AppTheme.accentGold)
                Text("How do you feel?")
                    .font(AppFonts.plusJakarta(18, weight: .bold))
                    .foregroundColor(AppTheme.title)
            }
            HStack(spacing: 8) {
                energyButton(title: "Low", icon: "battery_low", isSelected: energySelection == 0) {
                    energySelection = 0
                }
                energyButton(title: "Normal", icon: "battery_full", isSelected: energySelection == 1) {
                    energySelection = 1
                }
                energyButton(title: "High", icon: "local_fire_department", isSelected: energySelection == 2) {
                    energySelection = 2
                }
            }
            .padding(8)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
            .animation(.easeOut(duration: reduceMotion ? 0.12 : AppMotion.durationFast), value: energySelection)
        }
        .motionEntry(index: 2)
    }

    private func energyButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primaryButton : AppTheme.subtleSurface.opacity(0.4))
                        .frame(width: 32, height: 32)
                    MaterialSymbol(name: icon, size: 20)
                        .foregroundColor(isSelected ? AppTheme.primaryButtonText : AppTheme.iconMuted)
                }
                Text(title)
                    .font(AppFonts.plusJakarta(14, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? AppTheme.title : AppTheme.subtitle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? AppTheme.primaryButton.opacity(0.14) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isSelected ? AppTheme.cardBorderGold : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                MaterialSymbol(name: "location_on", size: 20)
                    .foregroundColor(AppTheme.accentGold)
                Text("Where are you?")
                    .font(AppFonts.plusJakarta(18, weight: .bold))
                    .foregroundColor(AppTheme.title)
            }
            HStack(spacing: 12) {
                locationButton(title: "Home", icon: "home", isSelected: locationSelection == 0) {
                    locationSelection = 0
                }
                locationButton(title: "Gym", icon: "fitness_center", isSelected: locationSelection == 1) {
                    locationSelection = 1
                }
            }
            .animation(.easeOut(duration: reduceMotion ? 0.12 : AppMotion.durationFast), value: locationSelection)
        }
        .motionEntry(index: 3)
    }

    private func locationButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primaryButton : AppTheme.subtleSurface.opacity(0.35))
                        .frame(width: 40, height: 40)
                    MaterialSymbol(name: icon, size: 20)
                        .foregroundColor(isSelected ? AppTheme.primaryButtonText : AppTheme.subtitle)
                }
                Text(title)
                    .font(AppFonts.plusJakarta(16, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? AppTheme.title : AppTheme.subtitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
                Spacer()
                if isSelected {
                    MaterialSymbol(name: "check_circle", size: 20)
                        .foregroundColor(AppTheme.accentGold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isSelected ? AppTheme.cardBorderGold : AppTheme.border.opacity(0.25), lineWidth: 2))
            .opacity(isSelected ? 1 : 0.6)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                MaterialSymbol(name: "timer", size: 20)
                    .foregroundColor(AppTheme.accentGold)
                Text("Target Time")
                    .font(AppFonts.plusJakarta(18, weight: .bold))
                    .foregroundColor(AppTheme.title)
            }
            HStack {
                Button(action: decreaseTime) {
                    Circle()
                        .fill(AppTheme.subtleSurface.opacity(0.45))
                        .frame(width: 44, height: 44)
                        .overlay(MaterialSymbol(name: "remove", size: 20).foregroundColor(AppTheme.accentGold))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                Spacer()
                VStack(spacing: -2) {
                    Text("\(targetMinutes)")
                        .font(AppFonts.plusJakarta(42, weight: .black))
                        .foregroundColor(AppTheme.title)
                    Text("minutes")
                        .font(AppFonts.plusJakarta(10, weight: .bold))
                        .foregroundColor(AppTheme.subtitle.opacity(0.7))
                        .tracking(2)
                }
                Spacer()
                Button(action: increaseTime) {
                    Circle()
                        .fill(AppTheme.primaryButton)
                        .frame(width: 44, height: 44)
                        .shadow(color: AppTheme.accentGold.opacity(0.3), radius: 12, x: 0, y: 6)
                        .overlay(MaterialSymbol(name: "add", size: 20).foregroundColor(AppTheme.primaryButtonText))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
        .motionEntry(index: 4)
    }

    private func decreaseTime() {
        targetMinutes = max(minTargetMinutes, targetMinutes - targetStep)
    }

    private func increaseTime() {
        targetMinutes = min(maxTargetMinutes, targetMinutes + targetStep)
    }

    private var startButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.border.opacity(0.24))
                .frame(height: 1)
            Button {
                Task {
                    isLoading = true
                    if let error = await viewModel.onStart(conditionString, targetMinutes, equipmentList, locationString) {
                        errorMessage = error
                        showError = true
                    }
                    isLoading = false
                }
            } label: {
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
                .foregroundColor(AppTheme.primaryButtonText)
                .background(AppTheme.primaryButtonGradient)
                .clipShape(Capsule())
            }
            .disabled(isLoading)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .motionPressable(haptic: true)
        }
        .background(AppTheme.appBackground.padding(.bottom, AppLayout.tabBarHeight))
    }
}
