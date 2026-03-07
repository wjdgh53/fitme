import Foundation

@MainActor
final class NavigationCoordinator: ObservableObject {
    // MARK: - Published State
    @Published private(set) var screenStack: [AppScreen] = [.home]
    @Published var selectedTab: AppTab = .home

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

    // MARK: - Core Navigation

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

    func goHomeFromFlow() {
        selectedTab = .home
        screenStack = [.home]
    }

    // MARK: - Workout Flow Navigation

    func goToPresetCheck() {
        screenStack = [.presetCheck]
    }

    func goToWorkoutPreview1() {
        screenStack = [.workoutPreview1]
    }

    func goToWorkoutPreview2() {
        screenStack = [.workoutPreview2]
    }

    func goToWorkoutSession() {
        screenStack = [.workoutSession]
    }

    func goToRest() {
        screenStack = [.rest]
    }

    func goToSummary() {
        screenStack = [.summary]
    }

    // MARK: - Open Screens

    func openLibrary() {
        push(.library)
    }

    func openExerciseDetail() {
        push(.exerciseDetail)
    }

    func openHistoryDetail() {
        push(.historyDetail)
    }

    func openReportDetail() {
        push(.reportDetail)
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

    func openPersonalInfo() {
        push(.personalInfo)
    }

    // MARK: - Internal

    private func syncSelectedTabWithRoot() {
        switch screenStack.first ?? .home {
        case .home:
            selectedTab = .home
        case .report, .reportDetail:
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
