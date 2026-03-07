import SwiftUI
import Foundation

#if canImport(WatchKit)
struct WatchMainView: View {
    @ObservedObject var controller: WatchWorkoutController
    @State private var showEndConfirm = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let accent = Color(red: 0.20, green: 0.64, blue: 1.00)
    private let primary = Color(red: 1.00, green: 0.52, blue: 0.47) // #FF8577
    private let backgroundLight = Color(red: 1.00, green: 0.97, blue: 0.94) // #FFF8F0
    private let textMain = Color(red: 0.29, green: 0.23, blue: 0.22) // #4A3B38
    private let textMuted = Color(red: 0.54, green: 0.41, blue: 0.38) // #896861
    private let mascotImageURL = URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBlEOcqb_hFvORwqPPUoARUn2ifei96o5XuwkdNP7h506Os106NL4M40j2PKIO4uofA9zoY_OerqsPOi4PZx-uGk-tYoms0rc66xDpJ8BawXoJETEC5Q2vs7KlG89Y2jlHcj5tzivT_vs6EOvNrTs_YBXEm-z4CokZKpxppK9HlERViNnM29tZBl9VlVpD63qqUAjag2DYKRlxkdX1RvOooOt4dPWand9uOezcNu0IlgN3WqKWDDxW8OnQh-EOIfdtMvb4pDsCQNcs")

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()
            switch controller.status {
            case .idle:
                ready
            case .generating:
                generating
            case .active:
                active
            case .resting:
                resting
            case .paused:
                paused
            case .ended:
                ended
            case .error:
                error
            }
        }
        .onReceive(timer) { _ in
            controller.tickRest()
            controller.tickElapsed()
        }
        .confirmationDialog("End workout?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) {
                controller.onEnd()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will finish your session on the watch.")
        }
    }

    private var ready: some View {
        VStack(spacing: 10) {
            Text("FitMe")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Ready")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))

            Spacer(minLength: 0)

            circleIconButton(systemImage: "play.fill", background: accent, accessibilityLabel: "Start Workout", action: controller.onStart)
        }
        .watchContentPadding()
    }

    private var generating: some View {
        VStack(spacing: 10) {
            Text("FitMe")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ProgressView()
                .tint(.white)

            Text("Generating plan…")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.70))
                .multilineTextAlignment(.center)

            Text("Keep iPhone nearby")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))

            Spacer(minLength: 0)
        }
        .watchContentPadding()
    }

    private var active: some View {
        ViewThatFits(in: .vertical) {
            activeLayout(density: .regular)
            activeLayout(density: .compact)
            ScrollView {
                activeLayout(density: .compact)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private enum ActiveDensity {
        case regular
        case compact
    }

    private func activeLayout(density: ActiveDensity) -> some View {
        let contentPaddingV: CGFloat = (density == .compact) ? 0 : 0
        let headerBottomPadding: CGFloat = (density == .compact) ? 1 : 2
        let stepperBlockPaddingV: CGFloat = (density == .compact) ? 0 : 1
        let metricsTopPadding: CGFloat = (density == .compact) ? 0 : 1
        let metricsBottomPadding: CGFloat = 1

        let stepperSpacing: CGFloat = (density == .compact) ? 18 : 22
        let headerTopInset: CGFloat = (density == .compact) ? 2 : 3

        let stepperValueFont: CGFloat = (density == .compact) ? 36 : 40
        let stepperCardPaddingV: CGFloat = (density == .compact) ? 2 : 3

        let tileValueFont: CGFloat = (density == .compact) ? 16 : 17
        let tilePaddingV: CGFloat = (density == .compact) ? 4 : 5

        let buttonFont: CGFloat = (density == .compact) ? 15 : 16
        let buttonMinHeight: CGFloat = (density == .compact) ? 32 : 34
        let buttonShadowRadius: CGFloat = (density == .compact) ? 10 : 12
        let buttonShadowY: CGFloat = (density == .compact) ? 5 : 6
        let buttonBottomInset: CGFloat = (density == .compact) ? 4 : 6
        let layoutTopNudge: CGFloat = (density == .compact) ? -8 : -10

        return VStack(spacing: 0) {
            activeHeader(density: density)
                .padding(.bottom, headerBottomPadding)

            Group {
                if controller.isBodyweight {
                    metricStepperCard(
                        label: "REPS",
                        value: repsValueText,
                        valueFontSize: stepperValueFont,
                        cardVerticalPadding: stepperCardPaddingV,
                        onIncrement: { controller.changeReps(by: 1) },
                        onDecrement: { controller.changeReps(by: -1) }
                    )
                } else {
                    HStack(spacing: stepperSpacing) {
                        metricStepperCard(
                            label: controller.weightUnit.uppercased(),
                            value: weightValueText,
                            valueFontSize: stepperValueFont,
                            cardVerticalPadding: stepperCardPaddingV,
                            onIncrement: { controller.changeWeight(by: 5) },
                            onDecrement: { controller.changeWeight(by: -5) }
                        )

                        metricStepperCard(
                            label: "REPS",
                            value: repsValueText,
                            valueFontSize: stepperValueFont,
                            cardVerticalPadding: stepperCardPaddingV,
                            onIncrement: { controller.changeReps(by: 1) },
                            onDecrement: { controller.changeReps(by: -1) }
                        )
                    }
                }
            }
            .padding(.vertical, stepperBlockPaddingV)

            HStack(spacing: 12) {
                metricTile(
                    title: "BPM",
                    systemImage: "heart.fill",
                    value: bpmText,
                    valueFontSize: tileValueFont,
                    tileVerticalPadding: tilePaddingV
                )
                metricTile(
                    title: "Time",
                    systemImage: nil,
                    value: timeString(controller.elapsedSeconds),
                    valueFontSize: tileValueFont,
                    tileVerticalPadding: tilePaddingV
                )
            }
            .padding(.top, metricsTopPadding)
            .padding(.bottom, metricsBottomPadding)

            Button(action: controller.onCompleteSet) {
                Text("Complete Set")
                    .font(.system(size: buttonFont, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: buttonMinHeight)
                    .background(primary)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.14), radius: buttonShadowRadius, x: 0, y: buttonShadowY)
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.95))
            .accessibilityLabel("Complete Set")
            .padding(.bottom, buttonBottomInset)
        }
        .watchContentPadding(vertical: contentPaddingV)
        .padding(.top, headerTopInset)
        .padding(.top, layoutTopNudge)
    }

    private func activeHeader(density: ActiveDensity) -> some View {
        let avatarFrame: CGFloat = (density == .compact) ? 32 : 36
        let avatarImageFrame: CGFloat = (density == .compact) ? 24 : 28
        let titleFont: CGFloat = (density == .compact) ? 16 : 17
        let subtitleFont: CGFloat = (density == .compact) ? 10 : 11
        let pauseButtonSize: CGFloat = (density == .compact) ? 30 : 32
        let pauseButtonYOffset: CGFloat = (density == .compact) ? 8 : 10

        return HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.10), radius: 3, x: 0, y: 2)

                AsyncImage(url: mascotImageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                        .tint(primary)
                }
                .frame(width: avatarImageFrame, height: avatarImageFrame)
            }
            .frame(width: avatarFrame, height: avatarFrame)

            VStack(alignment: .leading, spacing: 1) {
                Text("FitCoach")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                    .textCase(.uppercase)
                    .tracking(1.6)

                Text(controller.exerciseName)
                    .font(.system(size: titleFont, weight: .bold, design: .rounded))
                    .foregroundStyle(textMain)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)

                if controller.totalExercises > 0 {
                    Text("EX \(controller.currentExerciseIndex)/\(controller.totalExercises) · SET \(controller.currentSetIndex)/\(controller.totalSets)")
                        .font(.system(size: subtitleFont, weight: .bold, design: .rounded))
                        .foregroundStyle(textMuted)
                        .textCase(.uppercase)
                        .tracking(0.8)
                } else {
                    Text("EX --/-- · SET --/--")
                        .font(.system(size: subtitleFont, weight: .bold, design: .rounded))
                        .foregroundStyle(textMuted)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
            }
            Spacer(minLength: 0)

            Button(action: controller.onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(textMain)
                    .frame(width: pauseButtonSize, height: pauseButtonSize)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .offset(y: pauseButtonYOffset)
            .accessibilityLabel("Pause")
        }
    }

    private func metricStepperCard(
        label: String,
        value: String,
        valueFontSize: CGFloat = 42,
        cardVerticalPadding: CGFloat = 4,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: valueFontSize, weight: .black, design: .rounded))
                .foregroundStyle(primary)
                .kerning(-1)
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(primary.opacity(0.65))
                .textCase(.uppercase)
                .tracking(1.2)
        }
        .padding(.vertical, cardVerticalPadding)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 74)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Button(action: onIncrement) { Color.clear }
                        .buttonStyle(.plain)
                        .frame(height: proxy.size.height / 2)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Increase \(label)")

                    Button(action: onDecrement) { Color.clear }
                        .buttonStyle(.plain)
                        .frame(height: proxy.size.height / 2)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Decrease \(label)")
                }
            }
        }
    }

    private func metricTile(
        title: String,
        systemImage: String?,
        value: String,
        valueFontSize: CGFloat = 18,
        tileVerticalPadding: CGFloat = 6
    ) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(primary)
                }
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(textMuted)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(textMain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, tileVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.40))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func circleIconButton(
        systemImage: String,
        background: Color,
        accessibilityLabel: String,
        size: CGFloat = 66,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(background))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var weightValueText: String {
        if controller.isBodyweight { return "BW" }
        guard let weight = controller.currentWeight else { return "--" }
        return String(weight)
    }

    private var repsValueText: String {
        controller.currentReps.map(String.init) ?? "--"
    }

    private var bpmText: String {
        controller.heartRate.map { "\(Int($0))" } ?? "—"
    }

    private var previousLine: String? {
        guard let weight = controller.previousWeight,
              let reps = controller.previousReps else { return nil }
        let w = String(format: "%.1f", Double(weight))
        let unit = controller.weightUnit.lowercased()
        return "Previous: \(w) \(unit) x \(reps)"
    }

    private var resting: some View {
        VStack(spacing: 0) {
            Text("Rest")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 10)

            Text(timeString(controller.restRemainingSeconds))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Spacer(minLength: 10)

            circleIconButton(systemImage: "forward.fill",
                             background: Color.green,
                             accessibilityLabel: "Skip Rest",
                             size: 72,
                             action: controller.onSkipRest)
        }
        .watchContentPadding()
        .focusable(true)
        .digitalCrownRotation(
            Binding(
                get: { Double(controller.restRemainingSeconds) },
                set: { controller.updateRestSeconds(Int($0)) }
            ),
            from: 0,
            through: 600,
            by: 5,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }

    private var paused: some View {
        VStack(spacing: 0) {
            Text("Paused")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 10)

            circleIconButton(systemImage: "play.fill",
                             background: Color.green,
                             accessibilityLabel: "Resume",
                             size: 72,
                             action: controller.onResume)

            Button("End Workout") { showEndConfirm = true }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.red)
                .padding(.top, 10)
        }
        .watchContentPadding()
    }

    private var ended: some View {
        let summary = controller.workoutSummary
        return VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("Workout Complete")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(textMain)
                if let summary {
                    Text(saveStatusText(summary.saveStatus))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(textMuted)
                } else {
                    Text("Syncing to iPhone…")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(textMuted)
                }
            }

            HStack(spacing: 12) {
                metricTile(title: "Time", systemImage: nil, value: timeString(controller.elapsedSeconds), valueFontSize: 16, tileVerticalPadding: 6)
                metricTile(title: "Sets", systemImage: nil, value: "\(max(0, controller.currentSetIndex))/\(controller.totalSets)", valueFontSize: 16, tileVerticalPadding: 6)
            }
            .padding(.top, 2)

            if let summary {
                HStack(spacing: 12) {
                    metricTile(title: "Ex", systemImage: nil, value: "\(summary.totalExercises)", valueFontSize: 16, tileVerticalPadding: 6)
                    metricTile(title: "Kcal", systemImage: nil, value: summary.estimatedCalories.map(String.init) ?? "—", valueFontSize: 16, tileVerticalPadding: 6)
                }
            }

            Button {
                controller.resetToIdle()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 34)
                    .background(primary)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.95))
            .accessibilityLabel("Done")
        }
        .watchContentPadding(vertical: 6)
    }

    private var error: some View {
        VStack(spacing: 10) {
            Text("Couldn’t start")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(controller.exerciseName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            circleIconButton(systemImage: "arrow.clockwise",
                             background: accent,
                             accessibilityLabel: "Try Again",
                             action: controller.onStart)
        }
        .watchContentPadding()
    }

    private func saveStatusText(_ status: FitMeWatchSaveStatus) -> String {
        switch status {
        case .notSaved:
            return "Not saved"
        case .saving:
            return "Saving…"
        case .saved:
            return "Saved"
        case .failed:
            return "Save failed"
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private var background: Color {
        if controller.status == .active || controller.status == .ended {
            return backgroundLight
        }
        return Color.black
    }

}

private struct WatchContentPadding: ViewModifier {
    let vertical: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, vertical)
    }
}

#endif

#if canImport(WatchKit)
private extension View {
    func watchContentPadding(vertical: CGFloat = 8) -> some View {
        modifier(WatchContentPadding(vertical: vertical))
    }
}
#endif

private struct PressScaleButtonStyle: ButtonStyle {
    let scale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
