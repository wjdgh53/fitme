import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SummaryView: View {
    @ObservedObject var viewModel: SummaryViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSaving = false
    @State private var heroScale: CGFloat = 0.7
    @State private var heroOffsetY: CGFloat = 10
    @State private var didPlayHeroPop = false
    @State private var confettiStartDate: Date?
    @State private var confettiBurstID = UUID()
    
    var body: some View {
        ZStack {
            AppTheme.appBackground
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                let compact = proxy.size.height < 760
                let heroHeight: CGFloat = compact ? 140 : 176
                let cardMinHeight: CGFloat = compact ? 148 : 170

                VStack(spacing: 0) {
                    heroSection(height: heroHeight)
                        .padding(.top, compact ? 8 : 12)

                    titleSection
                        .padding(.top, compact ? 4 : 8)
                        .padding(.bottom, compact ? 12 : 16)

                    if let plan = viewModel.data.plan {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: compact ? 12 : 16
                        ) {
                            statCard(icon: "timer", value: "\(plan.estimatedMinutes)", unit: "min", minHeight: cardMinHeight, compact: compact)
                            statCard(icon: "local_fire_department", value: "\(plan.estimatedCalories)", unit: "kcal", minHeight: cardMinHeight, compact: compact)
                            statCard(icon: "fitness_center", value: "\(plan.exercises.count)", unit: "exercises", minHeight: cardMinHeight, compact: compact)
                            statCard(icon: "repeat", value: "\(totalSets(plan))", unit: "sets", minHeight: cardMinHeight, compact: compact)
                        }
                    }

                    Spacer(minLength: compact ? 10 : 16)

                    doneButton(compact: compact)
                        .padding(.horizontal, 24)
                        .padding(.bottom, compact ? 8 : 14)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            if let confettiStartDate, !reduceMotion {
                SummaryConfettiBurst(startDate: confettiStartDate)
                    .id(confettiBurstID)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
    }

    private func heroSection(height: CGFloat) -> some View {
        ZStack {
#if canImport(UIKit)
            if let image = UIImage(named: heroImageName) {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
            } else {
                MaterialSymbol(name: "mood", size: 88, style: .rounded)
                    .foregroundColor(AppTheme.subtitle)
            }
#else
            Image(heroImageName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
#endif
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .scaleEffect(reduceMotion ? 1 : heroScale)
        .offset(y: reduceMotion ? 0 : heroOffsetY)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .onAppear(perform: playHeroPopIfNeeded)
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Workout Complete!")
                .font(AppFonts.quicksand(31, weight: .black))
                .foregroundColor(AppTheme.title)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text("Great job! You crushed it!")
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(AppTheme.subtitle)
                .multilineTextAlignment(.center)
        }
    }

    private func doneButton(compact: Bool) -> some View {
        Button(action: primaryAction) {
            HStack(spacing: 10) {
                if isBusy {
                    ProgressView()
                        .tint(AppTheme.primaryButtonText)
                }
                Text(buttonTitle)
                    .font(AppFonts.nunito(compact ? 20 : 22, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(AppTheme.primaryButtonText)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 68 : 74)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.primaryButtonGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.primaryButtonPressed.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: AppTheme.primaryButton.opacity(0.22), radius: 12, x: 0, y: 8)
        }
        .disabled(isBusy)
    }

    private var statCardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(AppTheme.cardGold.opacity(0.62))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(AppTheme.cardBorderGold.opacity(0.7), lineWidth: 1.5)
            )
            .shadow(color: AppTheme.accentGold.opacity(0.18), radius: 10, x: 0, y: 6)
    }

    private func statCard(icon: String, value: String, unit: String, minHeight: CGFloat, compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 10) {
            MaterialSymbol(name: icon, size: compact ? 30 : 34, style: .rounded)
                .foregroundColor(AppTheme.accentGold)
                .frame(height: compact ? 36 : 40)
            Text(value)
                .font(AppFonts.quicksand(compact ? 34 : 38, weight: .black))
                .foregroundColor(AppTheme.title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(unit)
                .font(AppFonts.nunito(compact ? 14 : 15, weight: .bold))
                .foregroundColor(AppTheme.subtitle.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minHeight)
        .padding(.horizontal, 8)
        .background(statCardBackground)
    }

    private var heroImageName: String {
        "hooray_bear"
    }

    private var isBusy: Bool {
        if viewModel.data.isWatchDriven {
            if case .saving = viewModel.data.saveState { return true }
            return false
        }
        return isSaving
    }

    private var buttonTitle: String {
        if viewModel.data.isWatchDriven {
            switch viewModel.data.saveState {
            case .idle:
                return "Save"
            case .saving:
                return "Saving..."
            case .saved:
                return "Done"
            case .failed:
                return "Retry Save"
            }
        }
        return isSaving ? "Saving..." : "Done"
    }
    
    private func primaryAction() {
        if viewModel.data.isWatchDriven {
            switch viewModel.data.saveState {
            case .saved:
                viewModel.onFinish()
                return
            case .saving:
                return
            case .idle, .failed:
                break
            }
        }

        saveAndFinish()
    }

    private func saveAndFinish() {
        guard let plan = viewModel.data.plan else {
            print("❌ [SummaryView] plan is nil! Cannot save.")
            viewModel.onFinish()
            return
        }
        
        print("✅ [SummaryView] Saving workout: \(plan.estimatedMinutes)min, \(plan.exercises.count) exercises, \(plan.estimatedCalories) cal")
        
        isSaving = true
        Task {
            // Convert plan exercises to session exercises
            let exercises = plan.exercises.map { exercise in
                SessionExercise(
                    exerciseId: exercise.exerciseId,
                    sets: exercise.sets
                )
            }
            
            print("📤 [SummaryView] Calling onSave with \(exercises.count) exercises")
            await viewModel.onSave(plan.estimatedMinutes, exercises)
            print("✅ [SummaryView] Save completed")
            isSaving = false
            viewModel.onFinish()
        }
    }
    
    private func totalSets(_ plan: WorkoutPlan) -> Int {
        plan.exercises.reduce(0) { $0 + $1.sets.count }
    }

    private func playHeroPopIfNeeded() {
        guard !didPlayHeroPop else { return }
        didPlayHeroPop = true

        guard !reduceMotion else {
            heroScale = 1
            heroOffsetY = 0
            return
        }

        let burstID = UUID()
        confettiBurstID = burstID
        confettiStartDate = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            if confettiBurstID == burstID {
                confettiStartDate = nil
            }
        }

        // Comedic pop: 0.7 -> 1.15 -> 1.0 with a brief upward bounce.
        heroScale = 0.7
        heroOffsetY = 10

        withAnimation(.spring(response: 0.18, dampingFraction: 0.62)) {
            heroScale = 1.15
            heroOffsetY = -10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.20, dampingFraction: 0.84)) {
                heroScale = 1.0
                heroOffsetY = 0
            }
        }
    }
}

private struct SummaryConfettiBurst: View {
    let startDate: Date

    private let duration: TimeInterval = 1.9
    private let gravity: CGFloat = 900
    private let particleCount = 64
    private let colors: [Color] = [
        Color(hex: "#F5B23E"),
        Color(hex: "#FF8577"),
        Color(hex: "#FFD76B"),
        Color(hex: "#7A5A43"),
        Color(hex: "#FFF3D2")
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(startDate)

            Canvas { context, size in
                guard t >= 0, t <= duration else { return }

                let baseY = size.height * 0.2
                let fade = max(0, 1 - (t / duration))

                for i in 0..<particleCount {
                    let n1 = normalized(i, salt: 11)
                    let n2 = normalized(i, salt: 29)
                    let n3 = normalized(i, salt: 47)
                    let n4 = normalized(i, salt: 71)

                    let originX = size.width * (0.2 + 0.6 * n1)
                    let angle = CGFloat((-135.0 + 90.0 * n2) * .pi / 180.0)
                    let speed = CGFloat(220 + 280 * n3)
                    let vx = cos(angle) * speed
                    let vy = sin(angle) * speed
                    let time = CGFloat(t)

                    let x = originX + vx * time
                    let y = baseY + vy * time + 0.5 * gravity * time * time

                    let sizeUnit = CGFloat(5 + 7 * n4)
                    let alpha = Double(fade) * (0.8 + 0.2 * n2)
                    let color = colors[i % colors.count].opacity(alpha)
                    let spin = CGFloat((t * (2.0 + n1 * 5.5)) + (n2 * .pi))

                    var piece = context
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: Angle(radians: spin))

                    if i % 3 == 0 {
                        let rect = CGRect(x: -sizeUnit * 0.6, y: -sizeUnit * 0.6, width: sizeUnit * 1.2, height: sizeUnit * 1.2)
                        piece.fill(Path(ellipseIn: rect), with: .color(color))
                    } else {
                        let rect = CGRect(x: -sizeUnit, y: -sizeUnit * 0.35, width: sizeUnit * 2.0, height: sizeUnit * 0.7)
                        piece.fill(Path(roundedRect: rect, cornerRadius: sizeUnit * 0.2), with: .color(color))
                    }
                }
            }
        }
    }

    private func normalized(_ index: Int, salt: UInt64) -> CGFloat {
        var x = UInt64(index + 1) &* 0x9E3779B185EBCA87 &+ salt
        x ^= x >> 30
        x &*= 0xBF58476D1CE4E5B9
        x ^= x >> 27
        x &*= 0x94D049BB133111EB
        x ^= x >> 31
        return CGFloat(Double(x % 10_000) / 10_000.0)
    }
}
