import SwiftUI

struct WorkoutSessionView: View {
    let viewModel: WorkoutSessionViewModel
    @State private var phase: SessionPhase = .lifting
    @State private var isPaused: Bool = false
    @State private var showPauseSheet: Bool = false
    @State private var restRemaining: Int
    @State private var setHistory: [WorkoutSetEntry]
    @State private var weightValue: Int
    @State private var repsValue: Int
    @State private var currentSetIndex: Int
    @State private var totalSets: Int
    @State private var currentExerciseIndex: Int
    @State private var totalExercises: Int
    @State private var workoutElapsedSeconds: Int
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(viewModel: WorkoutSessionViewModel) {
        self.viewModel = viewModel
        _restRemaining = State(initialValue: viewModel.data.restSeconds)
        _setHistory = State(initialValue: viewModel.data.previousSets.map {
            WorkoutSetEntry(weight: $0.weight, reps: $0.reps)
        })
        _weightValue = State(initialValue: Int(viewModel.data.weight) ?? 0)
        _repsValue = State(initialValue: Int(viewModel.data.reps) ?? 0)
        let setParts = viewModel.data.currentSet.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        _currentSetIndex = State(initialValue: Int(setParts.first ?? "1") ?? 1)
        _totalSets = State(initialValue: Int(setParts.last ?? "4") ?? 4)
        let exerciseParts = viewModel.data.currentExerciseIndex.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        _currentExerciseIndex = State(initialValue: Int(exerciseParts.first ?? "1") ?? 1)
        _totalExercises = State(initialValue: Int(exerciseParts.last ?? "6") ?? 6)
        _workoutElapsedSeconds = State(initialValue: 0)
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
                Text(viewModel.data.exerciseName)
                    .font(AppFonts.nunito(28, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("\(currentExerciseIndex) / \(totalExercises)")
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

            AsyncImage(url: viewModel.data.videoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white
            }
            .frame(height: mediaHeight)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
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
                    } else {
                        LinearGradient(colors: [Color(hex: "#FF8577").opacity(0.2), Color.clear], startPoint: .bottom, endPoint: .top)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
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
                    inputColumn(title: "WEIGHT", value: weightValue, unit: viewModel.data.weightUnit, onIncrease: { weightValue += 5 }, onDecrease: { weightValue = max(0, weightValue - 5) })
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

                    ForEach(recentSetHistory.indices, id: \.self) { index in
                        let entry = recentSetHistory[index]
                        let setNumber = setHistory.count - recentSetHistory.count + index + 1
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                MaterialSymbol(name: "check", size: 14)
                                    .foregroundColor(Color(hex: "#22C55E"))
                                Text("\(setNumber)")
                                    .font(AppFonts.nunito(14, weight: .bold))
                                    .foregroundColor(Color(hex: "#6B7280"))
                            }
                            .frame(width: 44, alignment: .leading)

                            Text("\(entry.weight) \(viewModel.data.weightUnit)")
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
            if currentSetIndex >= totalSets {
                if currentExerciseIndex >= totalExercises {
                    viewModel.onComplete()
                } else {
                    moveToNextExercise()
                }
            } else {
                phase = .lifting
            }
        case .lifting:
            guard weightValue > 0, repsValue > 0 else { return }
            setHistory.append(WorkoutSetEntry(weight: String(weightValue), reps: String(repsValue)))
            if currentSetIndex >= totalSets && currentExerciseIndex >= totalExercises {
                viewModel.onComplete()
            } else {
                currentSetIndex = min(currentSetIndex + 1, totalSets)
                startRest()
            }
        }
    }

    private func startRest() {
        phase = .resting
        restRemaining = viewModel.data.restSeconds
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

    private var recentSetHistory: [WorkoutSetEntry] {
        setHistory // 전체 세트 기록 표시
    }

    private func moveToNextExercise() {
        currentExerciseIndex = min(currentExerciseIndex + 1, totalExercises)
        currentSetIndex = 1
        setHistory = []
        phase = .lifting
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
