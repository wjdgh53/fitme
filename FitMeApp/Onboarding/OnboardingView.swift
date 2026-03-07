import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                mascotSection
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                stepContent
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Spacer()

                nextButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            vm.onComplete = {
                appViewModel.applyOnboardingDefaults(
                    equipment: vm.equipmentArray,
                    targetMinutes: vm.sessionMinutes,
                    location: vm.locationRawValue
                )
                onComplete()
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: { vm.goBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.title)
                    .frame(width: 44, height: 44)
            }
            .opacity(vm.currentStep.rawValue > 0 ? 1 : 0)
            .disabled(vm.currentStep.rawValue == 0)

            progressBar
                .padding(.horizontal, 8)

            Text("\(vm.currentStep.stepNumber)/\(OnboardingStep.totalSteps)")
                .font(AppFonts.nunito(13, weight: .bold))
                .foregroundColor(AppTheme.subtitle)
                .frame(width: 40)
        }
        .padding(.horizontal, 12)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.cardGold.opacity(0.5))
                    .frame(height: 8)

                Capsule()
                    .fill(AppTheme.primaryButtonGradient)
                    .frame(width: max(0, geo.size.width * vm.progressFraction), height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.progressFraction)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Mascot

    private var mascotSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Image("bear-hero")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            speechBubble
                .id(vm.currentStep)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.2), value: vm.currentStep)
        }
    }

    private var speechBubble: some View {
        Text(vm.currentStep.question)
            .font(AppFonts.nunito(15, weight: .bold))
            .foregroundColor(AppTheme.title)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    // MARK: - Step Content

    private var stepContent: some View {
        Group {
            switch vm.currentStep {
            case .sex:
                SexStepView(selectedSex: $vm.selectedSex)
            case .age:
                AgeStepView(age: $vm.age)
            case .bodyStats:
                BodyStatsStepView(heightCm: $vm.heightCm, weightKg: $vm.weightKg)
            case .experience:
                ExperienceStepView(selectedLevel: $vm.selectedLevel, selectedDuration: $vm.selectedDuration)
            case .goal:
                GoalStepView(selectedGoal: $vm.selectedGoal)
            case .location:
                LocationStepView(selectedLocation: $vm.selectedLocation)
            case .equipment:
                EquipmentStepView(selectedEquipment: $vm.selectedEquipment)
            case .schedule:
                ScheduleStepView(weeklyDays: $vm.weeklyDays, sessionMinutes: $vm.sessionMinutes)
            }
        }
        .id(vm.currentStep)
        .transition(
            vm.slideDirection > 0
                ? .asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                  )
                : .asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                  )
        )
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button(action: {
            if vm.isLastStep {
                vm.submit()
            } else {
                vm.goNext()
            }
        }) {
            HStack {
                if vm.isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 20)
                } else {
                    Text(vm.isLastStep ? "완료" : "다음")
                        .font(AppFonts.nunito(17, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                vm.isCurrentStepValid
                    ? AnyView(AppTheme.primaryButtonGradient)
                    : AnyView(AppTheme.muted.opacity(0.3))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!vm.isCurrentStepValid || vm.isSubmitting)
        .animation(.easeOut(duration: 0.18), value: vm.isCurrentStepValid)
    }
}
