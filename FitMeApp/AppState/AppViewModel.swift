import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Navigation State
    @Published private(set) var screenStack: [AppScreen] = [.home]
    @Published var selectedTab: AppTab = .home
    
    // MARK: - Dashboard State
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var missions: [Mission] = []
    @Published private(set) var totalPoints: Int = 0
    @Published private(set) var rank: String = "Bronze"
    
    // MARK: - Mission Computed Properties
    var activeMissions: [Mission] {
        missions.filter { $0.status == .active }
    }
    
    var completedMissions: [Mission] {
        missions.filter { $0.status == .complete }
    }
    
    var suspendedMissions: [Mission] {
        missions.filter { $0.status == .suspended }
    }
    
    var canAddMission: Bool {
        activeMissions.count < 3
    }
    
    // MARK: - Workout Plan State
    @Published private(set) var currentWorkoutPlan: WorkoutPlan?
    @Published private(set) var isGeneratingPlan = false
    @Published private(set) var completedWorkoutPlan: WorkoutPlan?  // 운동 완료 시 저장
    
    // MARK: - Session State
    @Published private(set) var sessions: [SessionSummary] = []
    @Published private(set) var currentSessionDetail: SessionDetail?
    
    // MARK: - Workout Flow State
    @Published var workoutCondition: String = "normal"
    @Published var workoutTargetMinutes: Int = 45
    @Published var workoutEquipment: [String] = ["barbell", "dumbbell", "cable"]
    
    // MARK: - User Profile (TODO: Auth)
    var userName: String = "User"
    var profileImageURL: URL? = nil
    
    // MARK: - Points System
    var completedWorkoutsCount: Int {
        sessions.count
    }
    
    var completedMissionsCount: Int {
        missions.filter { $0.status == .complete }.count
    }
    
    var calculatedPoints: Int {
        let workoutPoints = completedWorkoutsCount * 5  // 운동 1회 = 5점
        let missionPoints = completedMissionsCount * 10  // 미션 달성 = 10점
        return workoutPoints + missionPoints
    }
    
    var currentScreen: AppScreen {
        screenStack.last ?? .home
    }
    
    var isTabBarDisabled: Bool {
        switch currentScreen {
        case .presetCheck, .workoutPreview1, .workoutPreview2, .workoutSession, .rest:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Computed Properties
    
    var hasMissions: Bool {
        !missions.isEmpty
    }
    
    var caloriesMission: Mission? {
        missions.first { $0.type == .calories }
    }
    
    var minutesMission: Mission? {
        missions.first { $0.type == .minutes }
    }
    
    var sessionsMission: Mission? {
        missions.first { $0.type == .sessions }
    }
    
    // MARK: - API Calls
    
    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIClient.shared.getDashboard()
            missions = response.missions
            checkAndCompleteMissions()
            totalPoints = response.totalPoints
            rank = response.rank
        } catch {
            errorMessage = error.localizedDescription
            print("Dashboard load error: \(error)")
        }
        
        isLoading = false
    }
    
    func loadMissions() async {
        do {
            let response = try await APIClient.shared.getMissions()
            missions = response.missions
            // 자동으로 완료된 미션 체크 및 status 업데이트
            checkAndCompleteMissions()
        } catch {
            print("Missions load error: \(error)")
        }
    }
    
    private func checkAndCompleteMissions() {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for i in missions.indices {
            // due date(end_at) 지났고 progress 100% 이상이면 complete
            if missions[i].status == .active,
               let endDate = dateFormatter.date(from: missions[i].endAt),
               today > endDate,
               missions[i].isComplete {
                let missionId = missions[i].id
                missions[i].status = .complete
                // API에 status 업데이트
                Task {
                    try? await APIClient.shared.updateMissionStatus(id: missionId, status: .complete)
                }
            }
        }
    }
    
    func completeMission(id: String) async {
        if let index = missions.firstIndex(where: { $0.id == id }) {
            missions[index].status = .complete
            try? await APIClient.shared.updateMissionStatus(id: id, status: .complete)
        }
    }
    
    func suspendMission(id: String) async {
        if let index = missions.firstIndex(where: { $0.id == id }) {
            missions[index].status = .suspended
            try? await APIClient.shared.updateMissionStatus(id: id, status: .suspended)
        }
    }
    
    func reactivateMission(id: String) async {
        guard canAddMission else { return }
        if let index = missions.firstIndex(where: { $0.id == id }) {
            missions[index].status = .active
            try? await APIClient.shared.updateMissionStatus(id: id, status: .active)
        }
    }
    
    func createAIMissions() async {
        isLoading = true
        do {
            let response = try await APIClient.shared.createMissions(mode: "ai")
            missions = response.missions
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func createAISingleMission(type: MissionType) async {
        isLoading = true
        do {
            let response = try await APIClient.shared.createMissions(mode: "ai", type: type, aiSingle: true)
            missions = response.missions
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func createCustomMission(type: MissionType, difficulty: MissionDifficulty, targetValue: Int) async {
        isLoading = true
        do {
            let response = try await APIClient.shared.createMissions(
                mode: "custom",
                type: type,
                difficulty: difficulty,
                targetValue: targetValue
            )
            missions = response.missions
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteMission(id: String) async {
        do {
            try await APIClient.shared.deleteMission(id: id)
            missions.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func generateWorkoutPlan() async {
        isGeneratingPlan = true
        errorMessage = nil
        
        do {
            currentWorkoutPlan = try await APIClient.shared.generateWorkoutPlan(
                condition: workoutCondition,
                targetMinutes: workoutTargetMinutes,
                equipment: workoutEquipment
            )
        } catch {
            errorMessage = error.localizedDescription
            print("Workout plan generation error: \(error)")
        }
        
        isGeneratingPlan = false
    }
    
    func loadSessions(period: String? = nil) async {
        do {
            sessions = try await APIClient.shared.getSessions(period: period)
        } catch {
            print("Sessions load error: \(error)")
        }
    }
    
    func loadSessionDetail(id: String) async {
        do {
            currentSessionDetail = try await APIClient.shared.getSession(id: id)
        } catch {
            print("Session detail load error: \(error)")
        }
    }
    
    func saveWorkoutSession(durationMinutes: Int, exercises: [SessionExercise]) async {
        print("📥 [AppViewModel] saveWorkoutSession: \(durationMinutes)min, \(exercises.count) exercises")
        do {
            let session = try await APIClient.shared.saveSession(
                source: .fitme,
                durationMinutes: durationMinutes,
                exercises: exercises
            )
            print("✅ [AppViewModel] Session saved: id=\(session.id), calories=\(session.calories)")
            sessions.insert(session, at: 0)
            // Refresh missions as progress may have changed
            await loadMissions()
        } catch {
            print("❌ [AppViewModel] Save failed: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Navigation
    
    func setTab(_ tab: AppTab) {
        guard !isTabBarDisabled else { return }
        selectedTab = tab
        switch tab {
        case .home:
            screenStack = [.home]
        case .report:
            screenStack = [.report]
        case .history:
            screenStack = [.historyList]
        case .profile:
            screenStack = [.profile]
        }
    }
    
    func push(_ screen: AppScreen) {
        screenStack.append(screen)
    }
    
    func pop() {
        guard screenStack.count > 1 else { return }
        screenStack.removeLast()
        syncSelectedTabWithRoot()
    }
    
    func startWorkoutFlow() {
        screenStack = [.presetCheck]
    }
    
    func goToWorkoutPreview1() {
        screenStack = [.workoutPreview1]
    }
    
    func goToWorkoutPreview2() {
        screenStack = [.workoutPreview2]
    }
    
    func startWorkoutSession() {
        screenStack = [.workoutSession]
    }
    
    func goToRest() {
        screenStack = [.rest]
    }
    
    func goToSummary() {
        // 운동 완료 시점에 plan 데이터 저장
        print("🏁 [AppViewModel] goToSummary - currentWorkoutPlan: \(currentWorkoutPlan?.title ?? "nil")")
        completedWorkoutPlan = currentWorkoutPlan
        print("🏁 [AppViewModel] completedWorkoutPlan set: \(completedWorkoutPlan?.exercises.count ?? 0) exercises")
        screenStack = [.summary]
    }
    
    func completeWorkoutFlow() {
        currentWorkoutPlan = nil
        completedWorkoutPlan = nil
        setTab(.home)
    }
    
    func openLibrary() {
        push(.library)
    }
    
    func openExerciseDetail() {
        push(.exerciseDetail)
    }
    
    func openHistoryDetail() {
        push(.historyDetail)
    }
    
    func openMyGoals() {
        push(.myGoals)
    }
    
    func openPoints() {
        push(.points)
    }
    
    func openGoalEdit() {
        push(.goalEdit)
    }
    
    func openWeeklyMission() {
        push(.weeklyMission)
    }
    
    func openGetQuest() {
        push(.getQuest)
    }
    
    func openAppSettings() {
        push(.appSettings)
    }
    
    func openHelpCenter() {
        push(.helpCenter)
    }
    
    func openAppleHealth() {
        push(.appleHealth)
    }
    
    func openAppleWatch() {
        push(.appleWatch)
    }
    
    func goHomeFromFlow() {
        selectedTab = .home
        screenStack = [.home]
    }
    
    private func syncSelectedTabWithRoot() {
        switch screenStack.first ?? .home {
        case .home:
            selectedTab = .home
        case .report:
            selectedTab = .report
        case .historyList, .historyDetail:
            selectedTab = .history
        case .profile:
            selectedTab = .profile
        default:
            break
        }
    }
}
