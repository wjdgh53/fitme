import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appViewModel.currentScreen {
                case .home:
                    HomeDashboardView(viewModel: HomeDashboardViewModel(appViewModel: appViewModel), appViewModel: appViewModel)
                case .report:
                    ReportView(viewModel: ReportViewModel(appViewModel: appViewModel))
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
                    WorkoutSessionView(viewModel: WorkoutSessionViewModel(appViewModel: appViewModel))
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
            .padding(.bottom, AppLayout.tabBarHeight)

            AppTabBar(selectedTab: appViewModel.selectedTab,
                      isDisabled: appViewModel.isTabBarDisabled,
                      onSelect: appViewModel.setTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
