import SwiftUI

struct WorkoutPreviewView1: View {
    @ObservedObject var viewModel: WorkoutPreviewViewModel

    var body: some View {
        WorkoutPreviewStyledScreen(
            data: viewModel.data,
            onBack: viewModel.onBack,
            onMore: viewModel.onMore,
            onStart: viewModel.onStart,
            showLoading: viewModel.data.isLoading
        )
        .alert("Workout Generation Failed", isPresented: alertIsPresented) {
            Button("Retry", action: viewModel.onRetry)
            Button("OK", role: .cancel) { viewModel.alertMessage = nil }
        } message: {
            Text(viewModel.alertMessage ?? "Please try again.")
        }
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.alertMessage = nil }
            }
        )
    }
}

struct WorkoutPreviewStyledScreen: View {
    let data: WorkoutPreviewData
    let onBack: () -> Void
    let onMore: () -> Void
    let onStart: () -> Void
    let showLoading: Bool

    private let bg = AppTheme.appBackground
    private let titleColor = AppTheme.title
    private let bodyColor = Color(hex: "#5D3A32")
    private let subColor = Color(hex: "#A3938D")
    private let yellow = Color(hex: "#FFB300")

    private var uiScale: CGFloat {
        min(max(UIScreen.main.bounds.width / 430.0, 0.84), 0.98)
    }

    private func s(_ value: CGFloat) -> CGFloat { value * uiScale }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if showLoading {
                    loadingBody
                } else {
                    contentBody
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !showLoading {
                bottomCTA
            }
        }
    }

    private var topBar: some View {
        HStack {
            circleButton(symbol: "arrow_back", action: onBack)
            Spacer()
            Text("PREVIEW")
                .font(AppFonts.nunito(s(12), weight: .black))
                .tracking(s(3))
                .foregroundColor(Color(hex: "#B7A89C"))
                .padding(.horizontal, s(22))
                .padding(.vertical, s(10))
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())
            Spacer()
            circleButton(symbol: "more_horiz", action: onMore)
        }
        .padding(.horizontal, s(24))
        .padding(.top, s(8))
        .padding(.bottom, s(8))
    }

    private var contentBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: s(16)) {
                Text(formattedTitle(data.title))
                    .font(AppFonts.quicksand(s(30), weight: .bold))
                    .lineSpacing(s(1))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.top, s(8))
                    .motionEntry(index: 0)

                chips
                    .motionEntry(index: 1)
                coachSection
                    .motionEntry(index: 2)
                routineHeader
                    .motionEntry(index: 3)
                routineList
            }
            .padding(.horizontal, s(24))
            .padding(.bottom, s(26))
        }
    }

    private var chips: some View {
        HStack(spacing: s(10)) {
            chip(icon: "timer", fill: "#F6EFCF", border: "#EFD68A", tint: "#F4AA00", text: data.duration)
            chip(icon: "bolt", fill: "#F4ECA9", border: "#E7D45E", tint: "#F0C933", text: normalizedEnergy(data.energy))
            chip(icon: "local_fire_department", fill: "#F7EED5", border: "#ECCF91", tint: "#F39B00", text: "\(data.calories) kcal")
        }
    }

    private func chip(icon: String, fill: String, border: String, tint: String, text: String) -> some View {
        HStack(spacing: s(6)) {
            Circle()
                .fill(Color.white)
                .frame(width: s(20), height: s(20))
                .overlay(MaterialSymbol(name: icon, size: s(14)).foregroundColor(Color(hex: tint)))
            Text(text)
                .font(AppFonts.nunito(s(12.5), weight: .bold))
                .foregroundColor(Color(hex: "#7B6257"))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, s(12))
        .frame(height: s(44))
        .background(Color(hex: fill))
        .overlay(
            RoundedRectangle(cornerRadius: s(22), style: .continuous)
                .stroke(Color(hex: border), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: s(22), style: .continuous))
    }

    private var coachSection: some View {
        HStack(alignment: .bottom, spacing: s(10)) {
            VStack(alignment: .leading, spacing: s(10)) {
                Text("COACH SAYS")
                    .font(AppFonts.nunito(s(10), weight: .black))
                    .tracking(s(1))
                    .foregroundColor(Color(hex: "#E49D05"))
                    .padding(.horizontal, s(12))
                    .padding(.vertical, s(5))
                    .background(Color(hex: "#F6E7AD"))
                    .clipShape(Capsule())

                Text("\"\(data.coachNote)\"")
                    .font(AppFonts.quicksand(s(15), weight: .bold))
                    .lineSpacing(s(2))
                    .foregroundColor(bodyColor)
            }
            .padding(s(16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: s(146))
            .background(Color(hex: "#F8F8F8"))
            .clipShape(RoundedRectangle(cornerRadius: s(24), style: .continuous))

            RoundedRectangle(cornerRadius: s(32), style: .continuous)
                .fill(Color(hex: "#F6F6F6"))
                .overlay(
                    RoundedRectangle(cornerRadius: s(32), style: .continuous)
                        .stroke(Color.white, lineWidth: 4)
                )
                .frame(width: s(104), height: s(104))
                .overlay(
                    Image("bear-hero")
                        .resizable()
                        .scaledToFit()
                        .padding(s(10))
                )
        }
    }

    private var routineHeader: some View {
        HStack {
            HStack(spacing: s(8)) {
                RoundedRectangle(cornerRadius: s(10), style: .continuous)
                    .fill(Color(hex: "#F3E9A8"))
                    .frame(width: s(32), height: s(32))
                    .overlay(
                        MaterialSymbol(name: "fitness_center", size: s(18))
                            .foregroundColor(Color(hex: "#F3A005"))
                    )

                Text("Routine")
                    .font(AppFonts.quicksand(s(17), weight: .bold))
                    .foregroundColor(titleColor)
            }

            Spacer()

            Text("\(data.exercises.count) Moves")
                .font(AppFonts.nunito(s(12), weight: .bold))
                .foregroundColor(Color(hex: "#8A6D60"))
                .padding(.horizontal, s(10))
                .frame(height: s(32))
                .background(Color.white.opacity(0.85))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "#E8E0D8"), lineWidth: 1))
        }
    }

    private var routineList: some View {
        VStack(spacing: s(12)) {
            ForEach(Array(data.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(spacing: s(12)) {
                    RoundedRectangle(cornerRadius: s(18), style: .continuous)
                        .fill(Color(hex: "#F7EAB8"))
                        .frame(width: s(56), height: s(56))
                        .overlay(Text("\(index + 1)")
                            .font(AppFonts.quicksand(s(24), weight: .bold))
                            .foregroundColor(yellow))

                    VStack(alignment: .leading, spacing: s(2)) {
                        Text(displayName(for: exercise.exerciseId))
                            .font(AppFonts.nunito(s(16), weight: .bold))
                            .foregroundColor(titleColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text("• \(exercise.sets.count) sets • \(targetPart(for: exercise.exerciseId))")
                            .font(AppFonts.nunito(s(12), weight: .semibold))
                            .foregroundColor(subColor)
                    }

                    Spacer()

                    Circle()
                        .fill(Color(hex: "#F1E9E1"))
                        .frame(width: s(54), height: s(54))
                        .overlay(
                            MaterialSymbol(name: "swap_horiz", size: s(24))
                                .foregroundColor(Color(hex: "#B6A8A0"))
                        )
                }
                .padding(s(16))
                .frame(minHeight: s(92))
                .background(Color(hex: "#FBFAF9"))
                .clipShape(RoundedRectangle(cornerRadius: s(30), style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: s(30), style: .continuous)
                        .stroke(Color(hex: "#EAE0D7"), lineWidth: 1)
                )
                .motionEntry(index: min(index + 4, 8), enabled: index < 5)
            }
        }
    }

    private var loadingBody: some View {
        VStack(spacing: s(14)) {
            Spacer()

            AnimatedRingLoader(size: s(58), color: AppTheme.primaryButton)

            Text("Loading workout...")
                .font(AppFonts.nunito(s(15), weight: .bold))
                .foregroundColor(Color(hex: "#8F7C70"))

            Spacer()
        }
        .padding(.horizontal, s(24))
    }

    private var bottomCTA: some View {
        Button(action: onStart) {
            HStack(spacing: s(8)) {
                Text("Let's Go!")
                MaterialSymbol(name: "rocket_launch", size: s(20))
            }
                .font(AppFonts.quicksand(s(18), weight: .bold))
                .foregroundColor(AppTheme.primaryButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: s(64))
                .background(
                    AppTheme.primaryButtonGradient
                )
                .overlay(
                    RoundedRectangle(cornerRadius: s(32), style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: s(32), style: .continuous))
                .shadow(color: AppTheme.primaryButton.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, s(32))
        .padding(.top, s(8))
        .padding(.bottom, s(6))
        .motionPressable(haptic: true)
    }

    private func circleButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color.white)
                .frame(width: s(48), height: s(48))
                .overlay(Circle().stroke(Color(hex: "#EFE5DB"), lineWidth: 2))
                .overlay(
                    MaterialSymbol(name: symbol, size: s(22))
                        .foregroundColor(Color(hex: "#59342D"))
                )
        }
        .buttonStyle(.plain)
    }

    private func normalizedEnergy(_ text: String) -> String {
        text.replacingOccurrences(of: " Energy", with: "")
    }

    private func formattedTitle(_ title: String) -> String {
        let normalized = title.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.localizedCaseInsensitiveContains("strength"), !normalized.contains("\n") {
            return normalized.replacingOccurrences(of: " Strength ", with: "\nStrength ")
        }
        return normalized
    }

    private func displayName(for exerciseId: String) -> String {
        exerciseId
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func targetPart(for exerciseId: String) -> String {
        let key = exerciseId.lowercased()
        if key.contains("bench") || key.contains("fly") { return "Chest" }
        if key.contains("squat") || key.contains("lunge") { return "Legs" }
        if key.contains("deadlift") || key.contains("row") { return "Back" }
        if key.contains("bicep") || key.contains("tricep") || key.contains("curl") || key.contains("extension") { return "Arms" }
        return "Full Body"
    }
}

private struct AnimatedRingLoader: View {
    let size: CGFloat
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.22), lineWidth: 6)

            Circle()
                .trim(from: 0.12, to: 0.82)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.35), color, color.opacity(0.6)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isAnimating)
        }
        .frame(width: size, height: size)
        .onAppear { isAnimating = true }
    }
}
