import Foundation
import SwiftUI

// MARK: - Onboarding Enums

enum BirthSex: String, CaseIterable {
    case male
    case female
    case preferNotToSay = "prefer_not_to_say"

    var displayLabel: String {
        switch self {
        case .male: return "남성"
        case .female: return "여성"
        case .preferNotToSay: return "밝히지 않음"
        }
    }

    var icon: String {
        switch self {
        case .male: return "♂"
        case .female: return "♀"
        case .preferNotToSay: return "◎"
        }
    }
}

enum WorkoutGoal: String, CaseIterable {
    case hypertrophy
    case strength
    case fatLoss = "fat_loss"
    case fitness

    var displayLabel: String {
        switch self {
        case .hypertrophy: return "근비대"
        case .strength: return "근력"
        case .fatLoss: return "다이어트"
        case .fitness: return "건강"
        }
    }

    var icon: String {
        switch self {
        case .hypertrophy: return "💪"
        case .strength: return "🏋️"
        case .fatLoss: return "🔥"
        case .fitness: return "❤️"
        }
    }

    var description: String {
        switch self {
        case .hypertrophy: return "근육량 증가"
        case .strength: return "최대 근력 향상"
        case .fatLoss: return "체지방 감소"
        case .fitness: return "전반적 건강 개선"
        }
    }
}

enum ExperienceLevel: String, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayLabel: String {
        switch self {
        case .beginner: return "초보자"
        case .intermediate: return "중급자"
        case .advanced: return "고급자"
        }
    }
}

enum ExperienceDuration: String, CaseIterable {
    case lessThan6m = "less_than_6m"
    case sixMonthsTo1y = "6m_to_1y"
    case oneYearTo3y = "1y_to_3y"
    case over3y = "over_3y"

    var displayLabel: String {
        switch self {
        case .lessThan6m: return "6개월 미만"
        case .sixMonthsTo1y: return "6개월~1년"
        case .oneYearTo3y: return "1~3년"
        case .over3y: return "3년 이상"
        }
    }
}

enum WorkoutLocation: String, CaseIterable {
    case home
    case gym
    case hybrid

    var displayLabel: String {
        switch self {
        case .home: return "홈"
        case .gym: return "헬스장"
        case .hybrid: return "둘 다"
        }
    }

    var icon: String {
        switch self {
        case .home: return "🏠"
        case .gym: return "🏋️"
        case .hybrid: return "🌐"
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case sex = 0
    case age
    case bodyStats
    case experience
    case goal
    case location
    case equipment
    case schedule

    var question: String {
        switch self {
        case .sex: return "성별을 알려주세요!"
        case .age: return "나이가 어떻게 되세요?"
        case .bodyStats: return "신체 정보를 입력해주세요."
        case .experience: return "운동 경력이 어떻게 되세요?"
        case .goal: return "어떤 목표를 갖고 계세요?"
        case .location: return "주로 어디서 운동하세요?"
        case .equipment: return "어떤 장비를 사용하세요?"
        case .schedule: return "주간 운동 계획을 세워봐요!"
        }
    }

    var stepNumber: Int { rawValue + 1 }
    static let totalSteps = allCases.count
}

// MARK: - OnboardingViewModel

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .sex
    @Published var slideDirection: Int = 1

    // Step 1: Sex
    @Published var selectedSex: BirthSex?

    // Step 2: Age
    @Published var age: Int = 25

    // Step 3: Body Stats
    @Published var heightCm: Double = 170
    @Published var weightKg: Double = 70

    // Step 4: Experience
    @Published var selectedLevel: ExperienceLevel?
    @Published var selectedDuration: ExperienceDuration?

    // Step 5: Goal
    @Published var selectedGoal: WorkoutGoal?

    // Step 6: Location
    @Published var selectedLocation: WorkoutLocation?

    // Step 7: Equipment
    @Published var selectedEquipment: Set<String> = []

    // Step 8: Schedule
    @Published var weeklyDays: Int = 3
    @Published var sessionMinutes: Int = 35

    // Submit state
    @Published var isSubmitting: Bool = false
    @Published var submitError: String?

    var onComplete: (() -> Void)?

    private static let onboardingKey = "fitme.onboarding.completed"

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.totalSteps)
    }

    var isCurrentStepValid: Bool {
        switch currentStep {
        case .sex: return selectedSex != nil
        case .age: return true
        case .bodyStats: return true
        case .experience: return selectedLevel != nil && selectedDuration != nil
        case .goal: return selectedGoal != nil
        case .location: return selectedLocation != nil
        case .equipment: return !selectedEquipment.isEmpty
        case .schedule: return true
        }
    }

    var isLastStep: Bool {
        currentStep == .schedule
    }

    func goNext() {
        guard isCurrentStepValid else { return }
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            submit()
            return
        }
        slideDirection = 1
        withAnimation(.easeInOut(duration: 0.28)) {
            currentStep = nextStep
        }
    }

    func goBack() {
        guard let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        slideDirection = -1
        withAnimation(.easeInOut(duration: 0.28)) {
            currentStep = prevStep
        }
    }

    func submit() {
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        let payload = buildPayload()
        Task {
            isSubmitting = true
            do {
                _ = try await APIClient.shared.updateWorkoutPreferences(payload)
            } catch {
                // 오프라인 허용: 서버 에러 시 로컬 완료 기록 유지
                submitError = error.localizedDescription
            }
            isSubmitting = false
            onComplete?()
        }
    }

    private func buildPayload() -> [String: JSONValue] {
        var payload: [String: JSONValue] = [
            "goal": .string(selectedGoal?.rawValue ?? "fitness"),
            "experience_level": .string(selectedLevel?.rawValue ?? "beginner"),
            "weekly_training_days": .int(weeklyDays),
            "preferred_session_minutes": .int(sessionMinutes),
            "preferred_location": .string(selectedLocation?.rawValue ?? "gym"),
            "birth_sex": .string(selectedSex?.rawValue ?? "prefer_not_to_say"),
            "equipment": .array(Array(selectedEquipment).map { .string($0) }),
            "onboarding_completed_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        if age >= 15 && age <= 80 {
            payload["age"] = .int(age)
        }
        if heightCm >= 100 && heightCm <= 250 {
            payload["height_cm"] = .double(heightCm)
        }
        if weightKg >= 30 && weightKg <= 300 {
            payload["weight_kg"] = .double(weightKg)
        }
        if let duration = selectedDuration {
            payload["experience_duration"] = .string(duration.rawValue)
        }
        return payload
    }

    // Helpers for AppViewModel.applyOnboardingDefaults
    var equipmentArray: [String] { Array(selectedEquipment) }
    var locationRawValue: String { selectedLocation?.rawValue ?? "gym" }
}
