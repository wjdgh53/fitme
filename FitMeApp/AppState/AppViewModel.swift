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
    
    // MARK: - Workout Plan State
    @Published private(set) var currentWorkoutPlan: WorkoutPlan?
    @Published private(set) var isGeneratingPlan = false
    
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
        } catch {
            print("Missions load error: \(error)")
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
        do {
            let session = try await APIClient.shared.saveSession(
                source: .fitme,
                durationMinutes: durationMinutes,
                exercises: exercises
            )
            sessions.insert(session, at: 0)
            // Refresh missions as progress may have changed
            await loadMissions()
        } catch {
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
        screenStack = [.summary]
    }
    
    func completeWorkoutFlow() {
        currentWorkoutPlan = nil
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
