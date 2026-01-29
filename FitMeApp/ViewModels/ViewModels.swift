import Foundation

struct HomeDashboardViewModel {
    let data: HomeDashboardMock
    let onStartWorkout: () -> Void
    let onOpenLibrary: () -> Void
    let onOpenExerciseDetail: () -> Void
    let onOpenWeeklyGoals: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.homeDashboard
        self.onStartWorkout = { appViewModel.startWorkoutFlow() }
        self.onOpenLibrary = { appViewModel.openLibrary() }
        self.onOpenExerciseDetail = { appViewModel.openExerciseDetail() }
        self.onOpenWeeklyGoals = { appViewModel.openMyGoals() }
    }
}

struct PresetCheckViewModel {
    let data: PresetCheckMock
    let onBack: () -> Void
    let onClose: () -> Void
    let onStart: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.presetCheck
        self.onBack = { appViewModel.goHomeFromFlow() }
        self.onClose = { appViewModel.goHomeFromFlow() }
        self.onStart = { appViewModel.goToWorkoutPreview1() }
    }
}

struct WorkoutPreviewViewModel {
    let data: WorkoutPreviewMock
    let onBack: () -> Void
    let onMore: () -> Void
    let onStart: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.workoutPreview
        self.onBack = { appViewModel.startWorkoutFlow() }
        self.onMore = { appViewModel.goToWorkoutPreview2() }
        self.onStart = { appViewModel.startWorkoutSession() }
    }
}

struct WorkoutSessionViewModel {
    let data: WorkoutSessionMock
    let onBack: () -> Void
    let onComplete: () -> Void
    let onIncreaseWeight: () -> Void
    let onDecreaseWeight: () -> Void
    let onIncreaseReps: () -> Void
    let onDecreaseReps: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.workoutSession
        self.onBack = { appViewModel.goToWorkoutPreview1() }
        self.onComplete = { appViewModel.goToSummary() }
        self.onIncreaseWeight = {}
        self.onDecreaseWeight = {}
        self.onIncreaseReps = {}
        self.onDecreaseReps = {}
    }
}

struct RestViewModel {
    let data: RestMock
    let onBack: () -> Void
    let onContinue: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.rest
        self.onBack = { appViewModel.startWorkoutSession() }
        self.onContinue = { appViewModel.goToSummary() }
    }
}

struct SummaryViewModel {
    let onFinish: () -> Void

    init(appViewModel: AppViewModel) {
        self.onFinish = { appViewModel.completeWorkoutFlow() }
    }
}

struct ReportViewModel {
    let data: ReportMock

    init() {
        self.data = MockDataProvider.report
    }
}

struct HistoryListViewModel {
    let data: HistoryListMock
    let onSelectDetail: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.historyList
        self.onSelectDetail = { appViewModel.openHistoryDetail() }
    }
}

struct HistoryDetailViewModel {
    let data: HistoryDetailMock
    let onBack: () -> Void
    let onHome: () -> Void
    let onShare: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.historyDetail
        self.onBack = { appViewModel.pop() }
        self.onHome = { appViewModel.goHomeFromFlow() }
        self.onShare = {}
    }

    init(data: HistoryDetailMock, onBack: @escaping () -> Void, onHome: @escaping () -> Void, onShare: @escaping () -> Void) {
        self.data = data
        self.onBack = onBack
        self.onHome = onHome
        self.onShare = onShare
    }
}

struct LibraryViewModel {
    let data: LibraryMock
    let onBack: () -> Void
    let onSelectItem: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.library
        self.onBack = { appViewModel.pop() }
        self.onSelectItem = { appViewModel.openExerciseDetail() }
    }
}

struct ExerciseDetailViewModel {
    let data: ExerciseDetailMock
    let onBack: () -> Void

    init(appViewModel: AppViewModel) {
        self.data = MockDataProvider.exerciseDetail
        self.onBack = { appViewModel.pop() }
    }
}

struct ProfileViewModel {
    let onMyGoals: () -> Void
    let onAppSettings: () -> Void
    let onHelpCenter: () -> Void

    init(appViewModel: AppViewModel) {
        self.onMyGoals = { appViewModel.openMyGoals() }
        self.onAppSettings = { appViewModel.openAppSettings() }
        self.onHelpCenter = { appViewModel.openHelpCenter() }
    }
}

struct MyGoalsViewModel {
    let hasWeeklyGoal: Bool
    let dateRange: String
    let caloriesProgress: Int
    let caloriesTarget: Int
    let minutesProgress: Int
    let minutesTarget: Int
    let sessionsProgress: Int
    let sessionsTarget: Int
    let onBack: () -> Void
    let onEditGoal: () -> Void
    let onViewMission: () -> Void
    let onGetQuest: () -> Void

    init(appViewModel: AppViewModel) {
        self.hasWeeklyGoal = appViewModel.hasWeeklyGoal
        self.dateRange = "Jan 28 – Feb 3"
        self.caloriesProgress = appViewModel.weeklyProgressCalories
        self.caloriesTarget = appViewModel.weeklyTargetCalories
        self.minutesProgress = appViewModel.weeklyProgressMinutes
        self.minutesTarget = appViewModel.weeklyTargetMinutes
        self.sessionsProgress = appViewModel.weeklyProgressSessions
        self.sessionsTarget = appViewModel.weeklyTargetSessions
        self.onBack = { appViewModel.pop() }
        self.onEditGoal = { appViewModel.openGoalEdit() }
        self.onViewMission = { appViewModel.openWeeklyMission() }
        self.onGetQuest = { appViewModel.openGetQuest() }
    }
}

struct GoalEditViewModel {
    let caloriesTarget: Int
    let minutesTarget: Int
    let sessionsTarget: Int
    let onBack: () -> Void
    let onSave: (Int, Int, Int) -> Void

    init(appViewModel: AppViewModel) {
        self.caloriesTarget = appViewModel.weeklyTargetCalories
        self.minutesTarget = appViewModel.weeklyTargetMinutes
        self.sessionsTarget = appViewModel.weeklyTargetSessions
        self.onBack = { appViewModel.pop() }
        self.onSave = { calories, minutes, sessions in
            appViewModel.updateWeeklyGoal(calories: calories, minutes: minutes, sessions: sessions)
            appViewModel.pop()
        }
    }
}

struct WeeklyMissionViewModel {
    let dateRange: String
    let caloriesProgress: Int
    let caloriesTarget: Int
    let minutesProgress: Int
    let minutesTarget: Int
    let sessionsProgress: Int
    let sessionsTarget: Int
    let onBack: () -> Void

    init(appViewModel: AppViewModel) {
        self.dateRange = "Jan 28 – Feb 3"
        self.caloriesProgress = appViewModel.weeklyProgressCalories
        self.caloriesTarget = appViewModel.weeklyTargetCalories
        self.minutesProgress = appViewModel.weeklyProgressMinutes
        self.minutesTarget = appViewModel.weeklyTargetMinutes
        self.sessionsProgress = appViewModel.weeklyProgressSessions
        self.sessionsTarget = appViewModel.weeklyTargetSessions
        self.onBack = { appViewModel.pop() }
    }
}

struct GetQuestViewModel {
    let caloriesDefault: Int
    let minutesDefault: Int
    let sessionsDefault: Int
    let onBack: () -> Void
    let onConfirm: (Int, Int, Int) -> Void

    init(appViewModel: AppViewModel) {
        self.caloriesDefault = 1200
        self.minutesDefault = 150
        self.sessionsDefault = 3
        self.onBack = { appViewModel.pop() }
        self.onConfirm = { calories, minutes, sessions in
            appViewModel.updateWeeklyGoal(calories: calories, minutes: minutes, sessions: sessions)
            appViewModel.pop()
        }
    }
}

struct AppSettingsViewModel {
    let onBack: () -> Void
    let onAppleHealth: () -> Void

    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
        self.onAppleHealth = { appViewModel.openAppleHealth() }
    }
}

struct HelpCenterViewModel {
    let onBack: () -> Void

    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
    }
}

struct AppleHealthViewModel {
    let onBack: () -> Void

    init(appViewModel: AppViewModel) {
        self.onBack = { appViewModel.pop() }
    }
}
