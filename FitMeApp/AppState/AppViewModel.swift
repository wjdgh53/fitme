import Foundation
import SwiftUI

final class AppViewModel: ObservableObject {
    @Published private(set) var screenStack: [AppScreen] = [.home]
    @Published var selectedTab: AppTab = .home
    @Published var hasWeeklyGoal: Bool = false
    @Published var weeklyTargetCalories: Int = 1200
    @Published var weeklyTargetMinutes: Int = 150
    @Published var weeklyTargetSessions: Int = 3
    @Published var weeklyProgressCalories: Int = 800
    @Published var weeklyProgressMinutes: Int = 90
    @Published var weeklyProgressSessions: Int = 2

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

    func updateWeeklyGoal(calories: Int, minutes: Int, sessions: Int) {
        weeklyTargetCalories = calories
        weeklyTargetMinutes = minutes
        weeklyTargetSessions = sessions
        hasWeeklyGoal = true
    }

    func goHomeFromFlow() {
        setTab(.home)
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
