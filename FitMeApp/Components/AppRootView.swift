import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        Group {
            switch appViewModel.currentScreen {
            case .home:
                HomeDashboardView(viewModel: HomeDashboardViewModel(appViewModel: appViewModel), appViewModel: appViewModel)
            case .report:
                ReportListView(viewModel: ReportListViewModel(appViewModel: appViewModel))
            case .reportDetail:
                ReportView(viewModel: WeeklyReportDetailViewModel(appViewModel: appViewModel))
            case .historyList:
                HistoryListView(viewModel: HistoryListViewModel(appViewModel: appViewModel))
            case .historyDetail:
                HistoryDetailView(viewModel: HistoryDetailViewModel(appViewModel: appViewModel))
            case .profile:
                ProfileView(viewModel: ProfileViewModel(appViewModel: appViewModel))
            case .library:
                LibraryView(viewModel: LibraryViewModel(appViewModel: appViewModel))
            case .exerciseDetail:
                ExerciseDetailView(viewModel: ExerciseDetailViewModel(appViewModel: appViewModel))
            case .presetCheck:
                PresetCheckView(viewModel: PresetCheckViewModel(appViewModel: appViewModel))
            case .workoutPreview1:
                WorkoutPreviewView1(viewModel: WorkoutPreviewViewModel(appViewModel: appViewModel))
            case .workoutPreview2:
                WorkoutPreviewView2(viewModel: WorkoutPreviewViewModel(appViewModel: appViewModel))
            case .workoutSession:
                if let runtime = appViewModel.workoutRuntime {
                    WorkoutSessionView(viewModel: WorkoutSessionViewModel(appViewModel: appViewModel), runtime: runtime)
                } else {
                    ProgressView()
                }
            case .rest:
                RestView(viewModel: RestViewModel(appViewModel: appViewModel))
            case .summary:
                SummaryView(viewModel: SummaryViewModel(appViewModel: appViewModel))
            case .myGoals:
                MyGoalsView(viewModel: MyGoalsViewModel(appViewModel: appViewModel))
            case .goalEdit:
                GoalEditView(viewModel: GoalEditViewModel(appViewModel: appViewModel))
            case .weeklyMission:
                WeeklyMissionView(viewModel: WeeklyMissionViewModel(appViewModel: appViewModel))
            case .getQuest:
                GetQuestView(viewModel: GetQuestViewModel(appViewModel: appViewModel))
            case .appSettings:
                AppSettingsView(viewModel: AppSettingsViewModel(appViewModel: appViewModel))
            case .helpCenter:
                HelpCenterView(viewModel: HelpCenterViewModel(appViewModel: appViewModel))
            case .appleHealth:
                AppleHealthView(viewModel: AppleHealthViewModel(appViewModel: appViewModel))
            case .appleWatch:
                AppleWatchView(viewModel: AppleWatchViewModel(appViewModel: appViewModel))
            case .points:
                PointsView(viewModel: PointsViewModel(appViewModel: appViewModel))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(selectedTab: appViewModel.selectedTab,
                      isDisabled: appViewModel.isTabBarDisabled,
                      onSelect: appViewModel.setTab)
                .zIndex(10)
        }
        .onAppear {
            let drained = appViewModel.watchWorkoutSync.drainPersistedIncomingEvents()
            if !drained.isEmpty {
                appViewModel.processWatchEvents(drained)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fitMeDidReceiveWatchEvents)) { note in
            guard let events = note.object as? [FitMeWatchEvent] else { return }
            appViewModel.processWatchEvents(events)
        }
    }
}
