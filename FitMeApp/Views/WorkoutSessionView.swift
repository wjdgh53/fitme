import SwiftUI
import AVKit

#if canImport(UIKit)

struct WorkoutSessionView: View {
    let viewModel: WorkoutSessionViewModel
    @ObservedObject var runtime: WorkoutRuntime
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showPauseSheet: Bool = false
    
    private var currentExercise: WorkoutPlanExercise? {
        guard runtime.currentExerciseIndex < runtime.plan.exercises.count else { return nil }
        return runtime.plan.exercises[runtime.currentExerciseIndex]
    }
    
    private var totalExercises: Int {
        runtime.plan.exercises.count
    }

    var body: some View {
        ZStack {
            ZStack {
                AppTheme.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: contentSpacing) {
                            timeRow
                            titleSection
                            videoSection
                                .animation(.easeInOut(duration: reduceMotion ? 0.12 : 0.2), value: runtime.phase)
                                .transaction { transaction in
                                    transaction.animation = .easeInOut(duration: reduceMotion ? 0.12 : 0.2)
                                }
                            setSection
                            metricsSection
                                .animation(.easeInOut(duration: reduceMotion ? 0.12 : 0.2), value: runtime.phase)
                                .transaction { transaction in
                                    transaction.animation = .easeInOut(duration: reduceMotion ? 0.12 : 0.2)
                                }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomControls
            }
            .blur(radius: showPauseSheet ? 6 : 0)
            .disabled(showPauseSheet)

            if showPauseSheet {
                pauseOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showPauseSheet)
    }

    private var timeRow: some View {
        Text(timeString(runtime.workoutElapsedSeconds))
            .font(AppFonts.nunito(20, weight: .black))
            .foregroundColor(AppTheme.title)
            .monospacedDigit()
            .padding(.top, 2)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: handlePause) {
                Circle()
                    .fill(AppTheme.elevatedSurface)
                    .frame(width: 40, height: 40)
                    .overlay(MaterialSymbol(name: "pause", size: 18).foregroundColor(AppTheme.title))
                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(currentExercise?.exerciseId.replacingOccurrences(of: "_", with: " ").capitalized ?? "Exercise")
                    .font(AppFonts.nunito(28, weight: .heavy))
                    .foregroundColor(AppTheme.title)
                Spacer()
                Text("\(runtime.currentExerciseIndex + 1) / \(totalExercises)")
                    .font(AppFonts.nunito(18, weight: .bold))
                    .foregroundColor(AppTheme.muted)
            }
        }
    }

    private var videoSection: some View {
        ZStack {
            SessionLoopingVideoView(resourceName: runtime.phase == .resting ? "cute_rest_bear" : "exercise_bear", resourceType: "mp4")
                .id(runtime.phase == .resting ? "rest_video" : "workout_video")
                .frame(height: mediaHeight)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.border.opacity(0.7), lineWidth: 1)
                )
                .opacity(0.84)
                .overlay(alignment: .top) {
                    if runtime.phase == .resting {
                        Text(timeString(runtime.restRemaining))
                            .font(AppFonts.nunito(30, weight: .black))
                            .foregroundColor(AppTheme.success)
                            .monospacedDigit()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppTheme.elevatedSurface.opacity(0.88))
                            .clipShape(Capsule())
                            .padding(.top, 10)
                            .transition(.opacity)
                    }
                }
        }
        .frame(height: mediaContainerHeight, alignment: .top)
        .clipped()
    }

    private var setSection: some View {
        HStack(spacing: 10) {
            Text("Current Set")
                .font(AppFonts.nunito(12, weight: .bold))
                .foregroundColor(AppTheme.muted)
            Text("\(runtime.currentSetIndex) / \(runtime.totalSets)")
                .font(AppFonts.nunito(22, weight: .black))
                .foregroundColor(AppTheme.primaryButton)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private var metricsSection: some View {
        Group {
            if runtime.phase == .lifting {
                if runtime.isCurrentExerciseBodyweight {
                    inputColumn(title: "REPS", value: runtime.repsValue, unit: "", onIncrease: { runtime.updateReps(runtime.repsValue + 1) }, onDecrease: { runtime.updateReps(max(0, runtime.repsValue - 1)) })
                } else {
                    HStack(spacing: 24) {
                        inputColumn(title: "WEIGHT", value: runtime.weightValue, unit: "lb", onIncrease: { runtime.updateWeight(runtime.weightValue + 5) }, onDecrease: { runtime.updateWeight(max(0, runtime.weightValue - 5)) })
                        inputColumn(title: "REPS", value: runtime.repsValue, unit: "", onIncrease: { runtime.updateReps(runtime.repsValue + 1) }, onDecrease: { runtime.updateReps(max(0, runtime.repsValue - 1)) })
                    }
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text("SET")
                            .frame(width: 44, alignment: .leading)
                        Text("WEIGHT")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("REPS")
                            .frame(width: 52, alignment: .trailing)
                    }
                    .font(AppFonts.nunito(10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(AppTheme.muted.opacity(0.8))
                    .padding(.horizontal, 8)

                    ForEach(runtime.setHistory.indices, id: \.self) { index in
                        let entry = runtime.setHistory[index]
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                MaterialSymbol(name: "check", size: 14)
                                    .foregroundColor(AppTheme.success)
                                Text("\(index + 1)")
                                    .font(AppFonts.nunito(14, weight: .bold))
                                    .foregroundColor(AppTheme.subtitle)
                            }
                            .frame(width: 44, alignment: .leading)

                            Text(entry.weight == "0" ? "BW" : "\(entry.weight) lb")
                                .font(AppFonts.nunito(16, weight: .black))
                                .foregroundColor(AppTheme.title)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(entry.reps)
                                .font(AppFonts.nunito(16, weight: .black))
                                .foregroundColor(AppTheme.title)
                                .frame(width: 52, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(AppTheme.elevatedSurface.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: reduceMotion ? 0.12 : AppMotion.durationNormal), value: runtime.setHistory.count)
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 16) {
            Button(action: { runtime.goToPreviousExercise() }) {
                Circle()
                    .fill(AppTheme.subtleSurface.opacity(0.95))
                    .frame(width: 56, height: 56)
                    .overlay(MaterialSymbol(name: "arrow_back", size: 26).foregroundColor(AppTheme.iconMuted))
                    .overlay(Circle().stroke(AppTheme.border.opacity(0.6), lineWidth: 1))
            }
            .disabled(runtime.currentExerciseIndex == 0)

            Button(action: handlePrimaryAction) {
                Text(runtime.phase == .resting ? "Complete Rest" : "Complete Set")
                    .font(AppFonts.nunito(18, weight: .black))
                    .foregroundColor(AppTheme.primaryButtonText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(runtime.phase == .resting ? AppTheme.success : AppTheme.primaryButton)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: (runtime.phase == .resting ? AppTheme.success : AppTheme.primaryButton).opacity(0.3), radius: 16, x: 0, y: 8)
            }
            .disabled(isCompleteSetDisabled)
            .motionPressable(haptic: true)

            Button(action: { runtime.skipToNextExercise() }) {
                Circle()
                    .fill(AppTheme.subtleSurface.opacity(0.95))
                    .frame(width: 56, height: 56)
                    .overlay(MaterialSymbol(name: "arrow_forward", size: 26).foregroundColor(AppTheme.iconMuted))
                    .overlay(Circle().stroke(AppTheme.border.opacity(0.6), lineWidth: 1))
            }
            .disabled(runtime.currentExerciseIndex + 1 >= runtime.totalExercises)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(AppTheme.appBackground.opacity(0.92).padding(.bottom, AppLayout.tabBarHeight))
    }

    private func handlePrimaryAction() {
        runtime.completeSet()
    }

    private func timeString(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func handlePause() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        runtime.pause()
        showPauseSheet = true
    }

    private func resumeWorkout() {
        showPauseSheet = false
        runtime.resume()
    }

    private func endWorkoutEarly() {
        showPauseSheet = false
        runtime.endWorkout()
    }

    private var pauseOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    resumeWorkout()
                }

            VStack(spacing: 14) {
                Text("오늘 운동을 여기까지 마칠까요?")
                    .font(AppFonts.nunito(18, weight: .black))
                    .foregroundColor(AppTheme.title)
                Text("지금까지 한 운동은 모두 기록돼요.")
                    .font(AppFonts.nunito(13, weight: .bold))
                    .foregroundColor(AppTheme.muted)

                Button(action: endWorkoutEarly) {
                    Text("오늘은 여기까지")
                        .font(AppFonts.nunito(16, weight: .black))
                        .foregroundColor(AppTheme.primaryButtonText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .motionPressable(haptic: true)

                Button(action: resumeWorkout) {
                    Text("계속 운동하기")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.title)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.elevatedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
                }
                .motionPressable(haptic: true)
            }
            .padding(20)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var mediaHeight: CGFloat {
        228
    }

    private var mediaContainerHeight: CGFloat {
        228
    }

    private var contentSpacing: CGFloat {
        16
    }

    private var isCompleteSetDisabled: Bool {
        if runtime.phase == .resting { return false }
        if runtime.isCurrentExerciseBodyweight {
            return runtime.repsValue <= 0
        }
        return runtime.weightValue <= 0 || runtime.repsValue <= 0
    }

    private func inputColumn(title: String, value: Int, unit: String, onIncrease: @escaping () -> Void, onDecrease: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppFonts.nunito(10, weight: .bold))
                .tracking(2)
                .foregroundColor(AppTheme.primaryButton.opacity(0.6))
            Button(action: onIncrease) {
                MaterialSymbol(name: "keyboard_arrow_up", size: 28)
                    .foregroundColor(AppTheme.title)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(AppFonts.nunito(48, weight: .black))
                    .foregroundColor(AppTheme.title)
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.nunito(16, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                        .offset(y: -4)
                }
            }
            Button(action: onDecrease) {
                MaterialSymbol(name: "keyboard_arrow_down", size: 28)
                    .foregroundColor(AppTheme.title)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private struct SessionLoopingVideoView: UIViewRepresentable {
    let resourceName: String
    let resourceType: String

    func makeUIView(context: Context) -> UIView {
        let view = SessionPlayerContainerView()
        view.backgroundColor = .clear

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceType) else {
            return view
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none

        let looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        context.coordinator.player = queuePlayer
        context.coordinator.looper = looper

        let layer = AVPlayerLayer(player: queuePlayer)
        // Fill the hero area height with a subtle zoom-in crop.
        layer.videoGravity = .resizeAspectFill
        view.playerLayer = layer
        view.layer.addSublayer(layer)

        queuePlayer.play()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let view = uiView as? SessionPlayerContainerView {
            view.playerLayer?.frame = view.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
    }
}

private final class SessionPlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

#endif
