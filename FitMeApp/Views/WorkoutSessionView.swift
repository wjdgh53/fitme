import SwiftUI

struct WorkoutSessionView: View {
    let viewModel: WorkoutSessionViewModel
    @State private var phase: SessionPhase = .lifting
    @State private var isPaused: Bool = false
    @State private var showPauseSheet: Bool = false
    @State private var restRemaining: Int = 60
    @State private var setHistory: [WorkoutSetEntry] = []
    @State private var weightValue: Int = 60
    @State private var repsValue: Int = 10
    @State private var currentSetIndex: Int = 1
    @State private var totalSets: Int = 4
    @State private var currentExerciseIndex: Int = 0
    @State private var workoutElapsedSeconds: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showCelebration: Bool = false
    @State private var celebrationMessage: String = ""
    
    private var currentExercise: WorkoutPlanExercise? {
        guard let plan = viewModel.data.plan,
              currentExerciseIndex < plan.exercises.count else { return nil }
        return plan.exercises[currentExerciseIndex]
    }
    
    private var totalExercises: Int {
        viewModel.data.plan?.exercises.count ?? 0
    }

    var body: some View {
        ZStack {
            ZStack {
                Color(hex: "#FFF8F0")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: contentSpacing) {
                            timeRow
                            titleSection
                            videoSection
                            setSection
                            metricsSection
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
            
            // Celebration popup
            if showCelebration {
                celebrationPopup
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.easeInOut, value: phase)
        .animation(.easeInOut, value: showPauseSheet)
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            if phase == .resting {
                if restRemaining > 0 {
                    restRemaining -= 1
                }
            } else {
                workoutElapsedSeconds += 1
            }
        }
        .onAppear {
            if let exercise = currentExercise, let firstSet = exercise.sets.first {
                weightValue = Int(firstSet.weight)
                repsValue = firstSet.reps
                totalSets = exercise.sets.count
            }
        }
    }

    private var timeRow: some View {
        Text(timeString(workoutElapsedSeconds))
            .font(AppFonts.nunito(20, weight: .black))
            .foregroundColor(Color(hex: "#3D3D3D"))
            .monospacedDigit()
            .padding(.top, 2)
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(MaterialSymbol(name: "arrow_back", size: 20).foregroundColor(Color(hex: "#3D3D3D")))
                    .overlay(Circle().stroke(Color(hex: "#F0EAE4"), lineWidth: 1))
            }
            Spacer()
            Button(action: handlePause) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(MaterialSymbol(name: "pause", size: 18).foregroundColor(Color(hex: "#3D3D3D")))
                    .overlay(Circle().stroke(Color(hex: "#F0EAE4"), lineWidth: 1))
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
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("\(currentExerciseIndex + 1) / \(totalExercises)")
                    .font(AppFonts.nunito(18, weight: .bold))
                    .foregroundColor(Color(hex: "#8B8B9B"))
            }
        }
    }

    private var videoSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(hex: "#FFF1EE"))
                .frame(height: mediaHeight)
                .overlay(
                    MaterialSymbol(name: "fitness_center", size: 48)
                        .foregroundColor(Color(hex: "#FF8577").opacity(0.3))
                )
                .blur(radius: phase == .resting ? 10 : 0)
                .overlay(
                    Group {
                        if phase == .resting {
                            Color.black.opacity(0.45)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .overlay(
                                    Text(timeString(restRemaining))
                                        .font(AppFonts.nunito(48, weight: .black))
                                        .foregroundColor(Color(hex: "#22C55E"))
                                        .monospacedDigit()
                                )
                                .transition(.opacity)
                        }
                    }
                )
                .padding(6)
        }
        .frame(height: mediaContainerHeight, alignment: .top)
        .clipped()
    }

    private var setSection: some View {
        HStack(spacing: 10) {
            Text("Current Set")
                .font(AppFonts.nunito(12, weight: .bold))
                .foregroundColor(Color(hex: "#8B8B9B"))
            Text("\(currentSetIndex) / \(totalSets)")
                .font(AppFonts.nunito(22, weight: .black))
                .foregroundColor(Color(hex: "#FF8577"))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private var metricsSection: some View {
        Group {
            if phase == .lifting {
                HStack(spacing: 24) {
                    inputColumn(title: "WEIGHT", value: weightValue, unit: "lb", onIncrease: { weightValue += 5 }, onDecrease: { weightValue = max(0, weightValue - 5) })
                    inputColumn(title: "REPS", value: repsValue, unit: "", onIncrease: { repsValue += 1 }, onDecrease: { repsValue = max(0, repsValue - 1) })
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
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .padding(.horizontal, 8)

                    ForEach(setHistory.indices, id: \.self) { index in
                        let entry = setHistory[index]
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                MaterialSymbol(name: "check", size: 14)
                                    .foregroundColor(Color(hex: "#22C55E"))
                                Text("\(index + 1)")
                                    .font(AppFonts.nunito(14, weight: .bold))
                                    .foregroundColor(Color(hex: "#6B7280"))
                            }
                            .frame(width: 44, alignment: .leading)

                            Text("\(entry.weight) lb")
                                .font(AppFonts.nunito(16, weight: .black))
                                .foregroundColor(Color(hex: "#3D3D3D"))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(entry.reps)
                                .font(AppFonts.nunito(16, weight: .black))
                                .foregroundColor(Color(hex: "#3D3D3D"))
                                .frame(width: 52, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white)
                .frame(width: 56, height: 56)
                .overlay(MaterialSymbol(name: "arrow_back", size: 26).foregroundColor(Color(hex: "#C4C4D0")))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

            Button(action: handlePrimaryAction) {
                Text(phase == .resting ? "Complete Rest" : "Complete Set")
                    .font(AppFonts.nunito(18, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(phase == .resting ? Color(hex: "#22C55E") : Color(hex: "#FF8577"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: (phase == .resting ? Color(hex: "#22C55E") : Color(hex: "#FF8577")).opacity(0.3), radius: 16, x: 0, y: 8)
            }
            .disabled(isCompleteSetDisabled)

            Circle()
                .fill(Color.white)
                .frame(width: 56, height: 56)
                .overlay(MaterialSymbol(name: "arrow_forward", size: 26).foregroundColor(Color(hex: "#C4C4D0")))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.95).padding(.bottom, AppLayout.tabBarHeight))
        .overlay(Rectangle().fill(Color(hex: "#F0EAE4")).frame(height: 1), alignment: .top)
    }

    private func handlePrimaryAction() {
        switch phase {
        case .resting:
            // Rest 끝 = 1세트 완료 → 다음 세트로
            if currentSetIndex >= totalSets {
                // 마지막 세트 완료
                if currentExerciseIndex + 1 >= totalExercises {
                    viewModel.onComplete()
                } else {
                    moveToNextExercise()
                }
            } else {
                // 다음 세트로
                currentSetIndex += 1
                phase = .lifting
            }
        case .lifting:
            guard weightValue > 0, repsValue > 0 else { return }
            setHistory.append(WorkoutSetEntry(weight: String(weightValue), reps: String(repsValue)))
            
            // 마지막 세트의 lifting이면 rest 없이 바로 완료/다음 운동
            if currentSetIndex >= totalSets {
                if currentExerciseIndex + 1 >= totalExercises {
                    viewModel.onComplete()
                } else {
                    moveToNextExercise()
                }
            } else {
                // lifting 끝 → rest 시작 (아직 세트 완료 아님)
                startRest()
            }
        }
    }

    private func startRest() {
        phase = .resting
        restRemaining = 60
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func handlePause() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        isPaused = true
        showPauseSheet = true
    }

    private func resumeWorkout() {
        showPauseSheet = false
        isPaused = false
    }

    private func endWorkoutEarly() {
        showPauseSheet = false
        isPaused = false
        viewModel.onComplete()
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
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text("지금까지 한 운동은 모두 기록돼요.")
                    .font(AppFonts.nunito(13, weight: .bold))
                    .foregroundColor(Color(hex: "#8B8B9B"))

                Button(action: endWorkoutEarly) {
                    Text("오늘은 여기까지")
                        .font(AppFonts.nunito(16, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#FF8577"))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(action: resumeWorkout) {
                    Text("계속 운동하기")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var mediaHeight: CGFloat {
        phase == .resting ? 96 : 170
    }

    private var mediaContainerHeight: CGFloat {
        phase == .resting ? 120 : 202
    }

    private var contentSpacing: CGFloat {
        phase == .resting ? 8 : 16
    }

    private var isCompleteSetDisabled: Bool {
        phase == .lifting && (weightValue <= 0 || repsValue <= 0)
    }

    private func moveToNextExercise() {
        // Show celebration before moving
        showCelebrationPopup()
        
        currentExerciseIndex += 1
        currentSetIndex = 1
        setHistory = []
        phase = .lifting
        
        if let exercise = currentExercise {
            totalSets = exercise.sets.count
            if let firstSet = exercise.sets.first {
                weightValue = Int(firstSet.weight)
                repsValue = firstSet.reps
            }
        }
    }
    
    private func showCelebrationPopup() {
        let messages = [
            "You did it! 💪",
            "Crushed it! 🔥",
            "Beast mode! 🦁",
            "Keep going! 🚀",
            "Amazing! ⭐️",
            "Nailed it! 🎯"
        ]
        celebrationMessage = messages.randomElement() ?? "Great job!"
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCelebration = true
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.2)) {
            showCelebration = false
        }
    }
    
    private var celebrationPopup: some View {
        ZStack {
            // Tap anywhere to dismiss
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }
            
            // Speech bubble
            VStack(spacing: 0) {
                Text(celebrationMessage)
                    .font(AppFonts.nunito(24, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white)
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color(hex: "#FF8577"), lineWidth: 3)
                        }
                    )
                    .shadow(color: Color(hex: "#FF8577").opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Bubble tail
                Triangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 12)
                    .overlay(
                        Triangle()
                            .stroke(Color(hex: "#FF8577"), lineWidth: 3)
                    )
                    .offset(y: -3)
            }
            .onTapGesture {
                dismissCelebration()
            }
        }
    }

    private func inputColumn(title: String, value: Int, unit: String, onIncrease: @escaping () -> Void, onDecrease: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppFonts.nunito(10, weight: .bold))
                .tracking(2)
                .foregroundColor(Color(hex: "#FF8577").opacity(0.6))
            Button(action: onIncrease) {
                MaterialSymbol(name: "keyboard_arrow_up", size: 28)
                    .foregroundColor(Color(hex: "#3D3D3D"))
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(AppFonts.nunito(48, weight: .black))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.nunito(16, weight: .bold))
                        .foregroundColor(Color(hex: "#6B6B7B"))
                        .offset(y: -4)
                }
            }
            Button(action: onDecrease) {
                MaterialSymbol(name: "keyboard_arrow_down", size: 28)
                    .foregroundColor(Color(hex: "#3D3D3D"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private struct WorkoutSetEntry: Equatable {
    let weight: String
    let reps: String
}

private enum SessionPhase {
    case lifting
    case resting
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
