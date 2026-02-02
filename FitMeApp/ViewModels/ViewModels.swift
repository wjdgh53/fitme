import Foundation
import Combine

// MARK: - Home Dashboard

struct HomeDashboardData {
    let userName: String
    let greeting: String
    let profileImageURL: URL?
    let missions: [Mission]
    let totalPoints: Int
    let rank: String
    let isLoading: Bool
}

@MainActor
struct HomeDashboardViewModel {
    let data: HomeDashboardData
    let onStartWorkout: () -> Void
    let onOpenLibrary: () -> Void
    let onOpenExerciseDetail: () -> Void
    let onOpenWeeklyGoals: () -> Void
    let onRefresh: () async -> Void
    
    init(appViewModel: AppViewModel) {
        self.data = HomeDashboardData(
            userName: appViewModel.userName,
            greeting: "Ready to move?",
            profileImageURL: appViewModel.profileImageURL,
            missions: appViewModel.activeMissions,
            totalPoints: appViewModel.totalPoints,
            rank: appViewModel.rank,
            isLoading: appViewModel.isLoading
        )
        self.onStartWorkout = { appViewModel.startWorkoutFlow() }
        self.onOpenLibrary = { appViewModel.openLibrary() }
        self.onOpenExerciseDetail = { appViewModel.openExerciseDetail() }
        self.onOpenWeeklyGoals = { appViewModel.openMyGoals() }
        self.onRefresh = { await appViewModel.loadDashboard() }
    }
}

// MARK: - Preset Check

struct PresetCheckData {
    let energySelection: Int
    let locationSelection: Int
    let targetMinutes: Int
}

@MainActor
struct PresetCheckViewModel {
    let data: PresetCheckData
    let onBack: () -> Void
    let onClose: () -> Void
    let onStart: (String, Int, [String]) async -> String?  // 에러 메시지 반환
    
    init(appViewModel: AppViewModel) {
        self.data = PresetCheckData(
            energySelection: 1,
            locationSelection: 1,
            targetMinutes: appViewModel.workoutTargetMinutes
        )
        self.onBack = { appViewModel.goHomeFromFlow() }
        self.onClose = { appViewModel.goHomeFromFlow() }
        self.onStart = { condition, minutes, equipment in
            appViewModel.workoutCondition = condition
            appViewModel.workoutTargetMinutes = minutes
            appViewModel.workoutEquipment = equipment
            await appViewModel.generateWorkoutPlan()
            // plan 생성 성공했을 때만 Preview로 이동
            if appViewModel.currentWorkoutPlan != nil {
                appViewModel.goToWorkoutPreview1()
                return nil
            }
            // 실패 시 에러 메시지 반환
            return appViewModel.errorMessage ?? "Failed to generate workout plan"
        }
    }
}

// MARK: - Workout Preview

struct WorkoutPreviewData {
    let title: String
    let duration: String
    let energy: String
    let calories: String
    let coachNote: String
    let exercises: [WorkoutPlanExercise]
    let isLoading: Bool
}

@MainActor
class WorkoutPreviewViewModel: ObservableObject {
    private let appViewModel: AppViewModel
    private var cancellable: AnyCancellable?
    
    var data: WorkoutPreviewData {
        let plan = appViewModel.currentWorkoutPlan
        return WorkoutPreviewData(
            title: plan?.title ?? "Workout",
            duration: "\(plan?.estimatedMinutes ?? 0)m",
            energy: appViewModel.workoutCondition.capitalized + " Energy",
            calories: "\(plan?.estimatedCalories ?? 0)",
            coachNote: plan?.coachMessage ?? "",
            exercises: plan?.exercises ?? [],
            isLoading: appViewModel.isGeneratingPlan
        )
    }
    
    var onBack: () -> Void { { [weak self] in self?.appViewModel.startWorkoutFlow() } }
    var onMore: () -> Void { { [weak self] in self?.appViewModel.goToWorkoutPreview2() } }
    var onStart: () -> Void { { [weak self] in self?.appViewModel.startWorkoutSession() } }
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.cancellable = appViewModel.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}

// MARK: - Workout Session

struct WorkoutSessionData {
    let plan: WorkoutPlan?
    let currentExerciseIndex: Int
}

@MainActor
struct WorkoutSessionViewModel {
    let data: WorkoutSessionData
    let onBack: () -> Void
    let onComplete: () -> Void
    let onRest: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.data = WorkoutSessionData(
            plan: appViewModel.currentWorkoutPlan,
            currentExerciseIndex: 0
        )
        self.onBack = { appViewModel.goToWorkoutPreview1() }
        self.onComplete = { appViewModel.goToSummary() }
        self.onRest = { appViewModel.goToRest() }
    }
}

// MARK: - Rest

@MainActor
struct RestViewModel {
    let plan: WorkoutPlan?
    let onBack: () -> Void
    let onContinue: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.plan = appViewModel.currentWorkoutPlan
        self.onBack = { appViewModel.startWorkoutSession() }
        self.onContinue = { appViewModel.goToSummary() }
    }
}

// MARK: - Summary

struct SummaryData {
    let plan: WorkoutPlan?
}

@MainActor
class SummaryViewModel: ObservableObject {
    private let appViewModel: AppViewModel
    private var cancellable: AnyCancellable?
    
    var data: SummaryData {
        // 완료된 운동 데이터 사용 (현재 plan보다 우선)
        SummaryData(plan: appViewModel.completedWorkoutPlan ?? appViewModel.currentWorkoutPlan)
    }
    
    var onFinish: () -> Void {
        { [weak self] in self?.appViewModel.completeWorkoutFlow() }
    }
    
    var onSave: (Int, [SessionExercise]) async -> Void {
        { [weak self] duration, exercises in
            await self?.appViewModel.saveWorkoutSession(durationMinutes: duration, exercises: exercises)
        }
    }
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.cancellable = appViewModel.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}

// MARK: - Report

struct ReportData {
    let sessions: [SessionSummary]
    let totalWorkouts: Int
    let totalMinutes: Int
    let totalCalories: Int
}

@MainActor
struct ReportViewModel {
    let data: ReportData
    let onRefresh: () async -> Void
    
    init(appViewModel: AppViewModel) {
        let sessions = appViewModel.sessions
        self.data = ReportData(
            sessions: sessions,
            totalWorkouts: sessions.count,
            totalMinutes: sessions.reduce(0) { $0 + $1.durationMinutes },
            totalCalories: sessions.reduce(0) { $0 + $1.calories }
        )
        self.onRefresh = { await appViewModel.loadSessions(period: "month") }
    }
}

// MARK: - History List

struct HistoryListData {
    let title: String
    let subtitle: String
    let sessions: [SessionSummary]
    let completedMissions: [Mission]
}

@MainActor
struct HistoryListViewModel {
    let data: HistoryListData
    let onSelectDetail: (String) -> Void
    let onRefresh: () async -> Void
    
    init(appViewModel: AppViewModel) {
        self.data = HistoryListData(
            title: "운동 기록",
            subtitle: "Logbook",
            sessions: appViewModel.sessions,
            completedMissions: appViewModel.completedMissions
        )
        self.onSelectDetail = { id in
            Task {
                await appViewModel.loadSessionDetail(id: id)
                appViewModel.openHistoryDetail()
            }
        }
        self.onRefresh = { await appViewModel.loadSessions() }
    }
}

// MARK: - History Detail

struct HistoryDetailData {
    let session: SessionDetail?
}

@MainActor
class HistoryDetailViewModel: ObservableObject {
    private let appViewModel: AppViewModel
    private var cancellable: AnyCancellable?
    
    var data: HistoryDetailData {
        HistoryDetailData(session: appViewModel.currentSessionDetail)
    }
    
    var onBack: () -> Void { { [weak self] in self?.appViewModel.pop() } }
    var onHome: () -> Void { { [weak self] in self?.appViewModel.goHomeFromFlow() } }
    var onShare: () -> Void { { } }
    var onDelete: () -> Void { { [weak self] in self?.appViewModel.pop() } }
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.cancellable = appViewModel.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}

// MARK: - Library (Static for now)

struct LibraryItemData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let equipment: String
    let imageURL: URL?
}

struct LibraryData {
    let title: String
    let searchPlaceholder: String
    let categoryChips: [String]
    let countText: String
    let items: [LibraryItemData]
}

@MainActor
struct LibraryViewModel {
    let data: LibraryData
    let onBack: () -> Void
    let onSelectItem: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.data = LibraryData(
            title: "운동 라이브러리",
            searchPlaceholder: "어떤 운동을 찾으세요?",
            categoryChips: ["전체", "가슴", "등", "하체", "어깨", "팔", "코어"],
            countText: "724개의 운동",
            items: [
                LibraryItemData(title: "벤치 프레스", subtitle: "가슴 (CHEST)", equipment: "Barbell", imageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuCQttwyEWF6qXJa4GlsWMkmUdU50FAKOOvJsbb29QdPbTjuKa6JM9KUHC8VXJmH3Z-qYpUjy02hX1TNGkUvM_a-26iyv0gLVRBmpFfw1s76dlndFD7QkmJ84pezsisXP9fknFMNZ91Toj9hNKyqu0PjsvHBYT5ak3ZjtSBovtZqK56i9viOSEw6vAxQOGMHxbNG1_TPg5QOVlWAeHgJtqGhHGfqCMYXvIdTEESZdGMamX_0NotvWS4BAuYL0s10rUHmCGErVbnmGXE")),
                LibraryItemData(title: "데드리프트", subtitle: "등 (BACK)", equipment: "Compound", imageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuD31Hj9MkRMg5lQK90LgpZ0qcUvwuVmY2kOFc3Iedtzi-oPWhGlDNUuMM_HJmMaLDyWp7A4KAs1Cdq7LaMpIo4VY5ubIgojMQCxfvdO48x-F0AjRZmEtgLByV7NEHPCV-rH75MxiAVr23z9dqs_6K-Q7T5Cf-rViJ3Kcmga-CQ81tHMpIEn5iliPn2vW0r7zi9Mr-G3igHVqjs4YawPSI2bOoi_v7hn2ZuVKHFbynw4BCsyHCeNHeWmHJ1SYXCnY8srwSptRFdsDKQ"))
            ]
        )
        self.onBack = { appViewModel.pop() }
        self.onSelectItem = { appViewModel.openExerciseDetail() }
    }
}

// MARK: - Exercise Detail (Static for now)

struct ExerciseDetailData {
    let title: String
    let description: String
    let heroURL: URL?
}

@MainActor
struct ExerciseDetailViewModel {
    let data: ExerciseDetailData
    let onBack: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.data = ExerciseDetailData(
            title: "Barbell Bench Press",
            description: "Let's pump those pecs! A great move for a strong chest and arms. 💪",
            heroURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuCUyk_A0ZAvBPbzKmC9ddJh6KwAfF5fHPOsqWS_cA4AcKWybACPncj6MQUvSMjQA4pr25S3lu6hrnJkd8_821ir86JS3ej4BHqiyl9BW2vmcKA8Kr9g82zzH249sz6TkmVCHprArcj_IZnJGbRm_8pjlTDXCiXq59yUVJYeNQZA5syBhp1UxXS00G0xn_qEBz28RhyXuYp43EWvXgQPiYHNH0Z4dI-h3HkF8_YujVi1Zkd-9iS-WHgkw6GD7E2mzHxBrDAqDXBa5W0")
        )
        self.onBack = { appViewModel.pop() }
    }
}

// MARK: - Profile

@MainActor
struct ProfileViewModel {
    let userName: String
    let totalPoints: Int
    let onMyGoals: () -> Void
    let onPoints: () -> Void
    let onAppSettings: () -> Void
    let onHelpCenter: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.userName = appViewModel.userName
        self.totalPoints = appViewModel.calculatedPoints
        self.onMyGoals = { appViewModel.openMyGoals() }
        self.onPoints = { appViewModel.openPoints() }
        self.onAppSettings = { appViewModel.openAppSettings() }
        self.onHelpCenter = { appViewModel.openHelpCenter() }
    }
}

// MARK: - My Goals

struct MyGoalsData {
    let hasMissions: Bool
    let missions: [Mission]
    let dateRange: String
}

@MainActor
final class MyGoalsViewModel: ObservableObject {
    let appViewModel: AppViewModel
    
    var data: MyGoalsData {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateRange = "\(formatter.string(from: weekStart)) – \(formatter.string(from: weekEnd))"
        
        return MyGoalsData(
            hasMissions: appViewModel.hasMissions,
            missions: appViewModel.missions,
            dateRange: dateRange
        )
    }
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }
    
    func onBack() {
        appViewModel.pop()
    }
    
    func onCreateAIMissions() async {
        await appViewModel.createAIMissions()
    }
    
    func onCreateAISingleMission(_ type: MissionType) async {
        await appViewModel.createAISingleMission(type: type)
    }
    
    func onCreateCustomMission(_ type: MissionType, _ difficulty: MissionDifficulty, _ target: Int) async {
        await appViewModel.createCustomMission(type: type, difficulty: difficulty, targetValue: target)
    }
    
    func onDeleteMission(_ id: String) async {
        await appViewModel.deleteMission(id: id)
    }
}

// MARK: - Goal Edit

@MainActor
struct GoalEditViewModel {
    let missions: [Mission]
    let onBack: () -> Void
    let onSave: (MissionType, MissionDifficulty, Int) async -> Void
    
    init(appViewModel: AppViewModel) {
        self.missions = appViewModel.missions
        self.onBack = { appViewModel.pop() }
        self.onSave = { type, difficulty, target in
            await appViewModel.createCustomMission(type: type, difficulty: difficulty, targetValue: target)
            await MainActor.run { appViewModel.pop() }
        }
    }
}

// MARK: - Weekly Mission

struct WeeklyMissionData {
    let missions: [Mission]
    let dateRange: String
}

@MainActor
struct WeeklyMissionViewModel {
    let data: WeeklyMissionData
    let onBack: () -> Void
    
    init(appViewModel: AppViewModel) {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateRange = "\(formatter.string(from: weekStart)) – \(formatter.string(from: weekEnd))"
        
        self.data = WeeklyMissionData(
            missions: appViewModel.missions,
            dateRange: dateRange
        )
        self.onBack = { appViewModel.pop() }
    }
}

// MARK: - Get Quest

@MainActor
struct GetQuestViewModel {
    let onBack: () -> Void
    let onConfirmAI: () async -> Void
    let onConfirmCustom: (MissionType, MissionDifficulty, Int) async -> Void
    
    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
        self.onConfirmAI = {
            await appViewModel.createAIMissions()
            await MainActor.run { appViewModel.pop() }
        }
        self.onConfirmCustom = { type, difficulty, target in
            await appViewModel.createCustomMission(type: type, difficulty: difficulty, targetValue: target)
            await MainActor.run { appViewModel.pop() }
        }
    }
}

// MARK: - Settings Views

@MainActor
struct AppSettingsViewModel {
    let onBack: () -> Void
    let onAppleHealth: () -> Void
    let onAppleWatch: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
        self.onAppleHealth = { appViewModel.openAppleHealth() }
        self.onAppleWatch = { appViewModel.openAppleWatch() }
    }
}

@MainActor
struct HelpCenterViewModel {
    let onBack: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
    }
}

@MainActor
struct AppleHealthViewModel {
    let onBack: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
    }
}

@MainActor
struct AppleWatchViewModel {
    let onBack: () -> Void
    
    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
    }
}

// MARK: - Points

struct PointsData {
    let totalPoints: Int
    let completedWorkouts: Int
    let completedMissions: Int
}

@MainActor
class PointsViewModel: ObservableObject {
    private let appViewModel: AppViewModel
    private var cancellable: AnyCancellable?
    
    var data: PointsData {
        PointsData(
            totalPoints: appViewModel.calculatedPoints,
            completedWorkouts: appViewModel.completedWorkoutsCount,
            completedMissions: appViewModel.completedMissionsCount
        )
    }
    
    var onBack: () -> Void {
        { [weak self] in self?.appViewModel.pop() }
    }
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.cancellable = appViewModel.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    func loadData() async {
        await appViewModel.loadSessions()
        await appViewModel.loadMissions()
    }
}
