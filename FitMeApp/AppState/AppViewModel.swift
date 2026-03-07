import Foundation
import SwiftUI
import Combine

enum WorkoutSource {
    case phone
    case watch
}

enum WorkoutSaveState: Equatable {
    case idle
    case saving(sessionId: String)
    case saved(sessionId: String, record: SessionSummary)
    case failed(sessionId: String, message: String)

    var sessionId: String? {
        switch self {
        case .idle:
            return nil
        case .saving(let sid), .saved(let sid, _), .failed(let sid, _):
            return sid
        }
    }

    var watchSaveStatus: FitMeWatchSaveStatus {
        switch self {
        case .idle:
            return .notSaved
        case .saving:
            return .saving
        case .saved:
            return .saved
        case .failed:
            return .failed
        }
    }

    var errorMessage: String? {
        switch self {
        case .failed(_, let message):
            return message
        default:
            return nil
        }
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Sub-modules
    let navigation = NavigationCoordinator()
    let missionRepo = MissionRepository()
    let sessionRepo = SessionRepository()
    let profile = UserProfileStore()

    private static let presetConditionKey = "fitme.preset.condition"
    private static let presetTargetMinutesKey = "fitme.preset.targetMinutes"
    private static let presetEquipmentKey = "fitme.preset.equipment"
    private static let presetLocationKey = "fitme.preset.defaultLocation"

    // MARK: - Workout Plan State
    @Published private(set) var currentWorkoutPlan: WorkoutPlan?
    @Published private(set) var isGeneratingPlan = false
    @Published private(set) var completedWorkoutPlan: WorkoutPlan?
    @Published private(set) var workoutRuntime: WorkoutRuntime?

    // MARK: - Workout Flow State
    @Published var workoutCondition: String = "normal" {
        didSet {
            UserDefaults.standard.set(workoutCondition, forKey: Self.presetConditionKey)
        }
    }
    @Published var workoutTargetMinutes: Int = 45 {
        didSet {
            UserDefaults.standard.set(workoutTargetMinutes, forKey: Self.presetTargetMinutesKey)
        }
    }
    @Published var workoutEquipment: [String] = ["barbell", "dumbbell", "cable"] {
        didSet {
            if let data = try? JSONEncoder().encode(workoutEquipment) {
                UserDefaults.standard.set(data, forKey: Self.presetEquipmentKey)
            }
        }
    }
    @Published var workoutLocation: String = "gym" {
        didSet {
            UserDefaults.standard.set(workoutLocation, forKey: Self.presetLocationKey)
        }
    }

    // MARK: - Watch Sync
    let watchWorkoutSync = WatchWorkoutSync()
    @Published var activeWorkoutSessionId: String? = nil
    @Published private(set) var activeWorkoutSource: WorkoutSource = .phone
    @Published private(set) var activeWorkoutSaveState: WorkoutSaveState = .idle

    private let watchPlanStore = WatchSessionPlanStore()
    private let watchEventBufferStore = WatchEventBufferStore()
    private let pendingWatchSaveStore = PendingWatchSaveStore()
    private var pendingWatchSaveRetryTask: Task<Void, Never>? = nil
    private var stagedNextWatchSessionId: String? = nil

    private var childCancellables = Set<AnyCancellable>()

    // MARK: - Forwarding Properties (backward compatibility)

    var screenStack: [AppScreen] { navigation.screenStack }
    var selectedTab: AppTab {
        get { navigation.selectedTab }
        set { navigation.selectedTab = newValue }
    }
    var currentScreen: AppScreen { navigation.currentScreen }
    var isTabBarDisabled: Bool { navigation.isTabBarDisabled }

    var missions: [Mission] { missionRepo.missions }
    var activeMissions: [Mission] { missionRepo.activeMissions }
    var completedMissions: [Mission] { missionRepo.completedMissions }
    var suspendedMissions: [Mission] { missionRepo.suspendedMissions }
    var canAddMission: Bool { missionRepo.canAddMission }
    var hasMissions: Bool { missionRepo.hasMissions }
    var caloriesMission: Mission? { missionRepo.caloriesMission }
    var minutesMission: Mission? { missionRepo.minutesMission }
    var sessionsMission: Mission? { missionRepo.sessionsMission }

    var sessions: [SessionSummary] { sessionRepo.sessions }
    var currentSessionDetail: SessionDetail? { sessionRepo.currentSessionDetail }
    var weeklyReports: [WeeklyReport] { sessionRepo.weeklyReports }
    var currentWeeklyReport: WeeklyReport? { sessionRepo.currentWeeklyReport }

    var userName: String {
        get { profile.userName }
        set { profile.userName = newValue }
    }
    var profileImageURL: URL? {
        get { profile.profileImageURL }
        set { profile.profileImageURL = newValue }
    }
    var profileImageData: Data? { profile.profileImageData }

    var isLoading: Bool { missionRepo.isLoading }
    @Published var errorMessage: String? = nil

    var completedWorkoutsCount: Int { sessionRepo.completedWorkoutsCount }
    var completedMissionsCount: Int { missionRepo.completedMissionsCount }

    var calculatedPoints: Int {
        let workoutPoints = completedWorkoutsCount * 5
        let missionPoints = completedMissionsCount * 10
        return workoutPoints + missionPoints
    }

    @Published private(set) var totalPoints: Int = 0
    @Published private(set) var rank: String = "Bronze"

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        if let value = defaults.string(forKey: Self.presetConditionKey) {
            workoutCondition = value
        }
        let minutes = defaults.integer(forKey: Self.presetTargetMinutesKey)
        if minutes > 0 {
            workoutTargetMinutes = minutes
        }
        if let data = defaults.data(forKey: Self.presetEquipmentKey),
           let equipment = try? JSONDecoder().decode([String].self, from: data),
           !equipment.isEmpty {
            workoutEquipment = equipment
        }
        if let loc = defaults.string(forKey: Self.presetLocationKey) {
            workoutLocation = loc
        }

        // Forward child objectWillChange to self so SwiftUI picks up changes
        navigation.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)

        missionRepo.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)

        missionRepo.$errorMessage.sink { [weak self] message in
            self?.errorMessage = message
        }.store(in: &childCancellables)

        sessionRepo.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)

        profile.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &childCancellables)

        retryPendingWatchSavesOnLaunch()
    }

    func applyOnboardingDefaults(equipment: [String], targetMinutes: Int, location: String) {
        if !equipment.isEmpty { workoutEquipment = equipment }
        if targetMinutes > 0 { workoutTargetMinutes = targetMinutes }
        workoutLocation = location
    }

    // MARK: - Forwarding Methods (backward compatibility)

    func setProfileImageData(_ data: Data?) throws {
        try profile.setProfileImageData(data)
    }

    func setTab(_ tab: AppTab) {
        navigation.setTab(tab)
    }

    func push(_ screen: AppScreen) {
        navigation.push(screen)
    }

    func pop() {
        navigation.pop()
    }

    func goHomeFromFlow() {
        navigation.goHomeFromFlow()
    }

    // MARK: - Mission Forwarding

    func loadMissions() async {
        await missionRepo.loadMissions()
    }

    func completeMission(id: String) async {
        await missionRepo.completeMission(id: id)
    }

    func suspendMission(id: String) async {
        await missionRepo.suspendMission(id: id)
    }

    func reactivateMission(id: String) async {
        await missionRepo.reactivateMission(id: id)
    }

    func createAIMissions() async {
        await missionRepo.createAIMissions()
    }

    func createAISingleMission(type: MissionType) async -> String? {
        await missionRepo.createAISingleMission(type: type)
    }

    func createCustomMission(type: MissionType, difficulty: MissionDifficulty, targetValue: Int) async -> String? {
        await missionRepo.createCustomMission(type: type, difficulty: difficulty, targetValue: targetValue)
    }

    func deleteMission(id: String) async {
        await missionRepo.deleteMission(id: id)
    }

    // MARK: - Session Forwarding

    func loadSessions(period: String? = nil) async {
        await sessionRepo.loadSessions(period: period)
        missionRepo.recalculateMissionProgress()
    }

    func loadSessionDetail(id: String) async {
        await sessionRepo.loadSessionDetail(id: id)
    }

    func loadWeeklyReports() async {
        await sessionRepo.loadWeeklyReports()
    }

    func loadWeeklyReportDetail(startAt: String) async {
        await sessionRepo.loadWeeklyReportDetail(startAt: startAt)
    }

    // MARK: - Dashboard (cross-cutting)

    func loadDashboard() async {
        do {
            let response = try await APIClient.shared.getDashboard()
            missionRepo.applyDashboardMissions(response.missions)
            totalPoints = response.totalPoints
            rank = response.rank
        } catch {
            #if DEBUG
            print("Dashboard load error: \(error)")
            #endif
        }
    }

    // MARK: - Workout Plan

    func generateWorkoutPlan() async {
        let sourceAtStart = activeWorkoutSource
        isGeneratingPlan = true
        currentWorkoutPlan = nil

        do {
            currentWorkoutPlan = try await APIClient.shared.generateWorkoutPlan(
                condition: workoutCondition,
                targetMinutes: workoutTargetMinutes,
                equipment: workoutEquipment,
                location: workoutLocation
            )
            if sourceAtStart == .phone, let plan = currentWorkoutPlan, !plan.exercises.isEmpty {
                stagePlanForWatchStartIfNeeded(plan: plan)
            }
        } catch {
            #if DEBUG
            print("Workout plan generation error: \(error)")
            #endif
        }

        isGeneratingPlan = false
    }

    // MARK: - Save Session (cross-cutting: watch + session repo)

    func saveWorkoutSession(durationMinutes: Int, exercises: [SessionExercise]) async {
        if activeWorkoutSource == .watch, let sessionId = activeWorkoutSessionId {
            switch activeWorkoutSaveState {
            case .saving(let sid) where sid == sessionId:
                return
            case .saved(let sid, _) where sid == sessionId:
                return
            default:
                break
            }

            let plan = completedWorkoutPlan ?? currentWorkoutPlan ?? watchPlanStore.load(sessionId: sessionId)
            activeWorkoutSaveState = .saving(sessionId: sessionId)
            sendWatchWorkoutSummaryIfPossible(sessionId: sessionId, plan: plan, saveState: activeWorkoutSaveState)

            let result = await sessionRepo.saveWorkoutSessionInternal(durationMinutes: durationMinutes, exercises: exercises)
            switch result {
            case .success(let record):
                activeWorkoutSaveState = .saved(sessionId: sessionId, record: record)
                pendingWatchSaveStore.remove(sessionId: sessionId)
                watchPlanStore.remove(sessionId: sessionId)
                watchEventBufferStore.clear(sessionId: sessionId)
            case .failure(let error):
                activeWorkoutSaveState = .failed(sessionId: sessionId, message: error.localizedDescription)
                pendingWatchSaveStore.upsert(sessionId: sessionId,
                                             durationMinutes: durationMinutes,
                                             exercises: exercises,
                                             plan: plan,
                                             errorMessage: error.localizedDescription)
            }
            sendWatchWorkoutSummaryIfPossible(sessionId: sessionId, plan: plan, saveState: activeWorkoutSaveState)
            await missionRepo.loadMissions()
            return
        }

        let result = await sessionRepo.saveWorkoutSessionInternal(durationMinutes: durationMinutes, exercises: exercises)
        if case .success = result {
            missionRepo.recalculateMissionProgress()
            await missionRepo.loadMissions()
        }
    }

    // MARK: - Navigation (workout flow)

    func startWorkoutFlow() {
        activeWorkoutSource = .phone
        activeWorkoutSaveState = .idle
        activeWorkoutSessionId = nil
        stagedNextWatchSessionId = nil
        currentWorkoutPlan = nil
        workoutRuntime?.stop()
        workoutRuntime = nil
        navigation.goToPresetCheck()
    }

    func startQuickWorkoutFlow() {
        activeWorkoutSource = .phone
        activeWorkoutSaveState = .idle
        navigation.goToWorkoutPreview1()
        applyQuickStartPresetDefaults()
        Task { await generateWorkoutPlan() }
    }

    func goToWorkoutPreview1() {
        navigation.goToWorkoutPreview1()
    }

    func goToWorkoutPreview2() {
        navigation.goToWorkoutPreview2()
    }

    func startWorkoutSession() {
        if activeWorkoutSessionId == nil {
            activeWorkoutSessionId = UUID().uuidString
        }
        guard let plan = currentWorkoutPlan, !plan.exercises.isEmpty else {
            return
        }
        if let sessionId = activeWorkoutSessionId {
            ensureWorkoutRuntime(plan: plan, sessionId: sessionId)
        }
        navigation.goToWorkoutSession()
    }

    func goToRest() {
        navigation.goToRest()
    }

    func goToSummary() {
        #if DEBUG
        print("[AppViewModel] goToSummary - currentWorkoutPlan: \(currentWorkoutPlan?.title ?? "nil")")
        #endif
        completedWorkoutPlan = currentWorkoutPlan
        #if DEBUG
        print("[AppViewModel] completedWorkoutPlan set: \(completedWorkoutPlan?.exercises.count ?? 0) exercises")
        #endif
        navigation.goToSummary()
    }

    func completeWorkoutFlow() {
        currentWorkoutPlan = nil
        completedWorkoutPlan = nil
        activeWorkoutSessionId = nil
        activeWorkoutSource = .phone
        activeWorkoutSaveState = .idle
        workoutRuntime?.stop()
        workoutRuntime = nil
        navigation.setTab(.home)
    }

    func openLibrary() { navigation.openLibrary() }
    func openExerciseDetail() { navigation.openExerciseDetail() }
    func openHistoryDetail() { navigation.openHistoryDetail() }

    func openWeeklyReportDetail(startAt: String) {
        Task {
            await sessionRepo.loadWeeklyReportDetail(startAt: startAt)
            if sessionRepo.currentWeeklyReport?.periodStart == startAt {
                navigation.openReportDetail()
            }
        }
    }

    func openMyGoals() { navigation.openMyGoals() }
    func openPoints() { navigation.openPoints() }
    func openGoalEdit() { navigation.openGoalEdit() }
    func openWeeklyMission() { navigation.openWeeklyMission() }
    func openGetQuest() { navigation.openGetQuest() }
    func openAppSettings() { navigation.openAppSettings() }
    func openHelpCenter() { navigation.openHelpCenter() }
    func openAppleHealth() { navigation.openAppleHealth() }
    func openAppleWatch() { navigation.openAppleWatch() }
    func openPersonalInfo() { navigation.openPersonalInfo() }

    // MARK: - Watch Events

    internal func processWatchEvents(_ events: [FitMeWatchEvent]) {
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        for event in sorted {
            if activeWorkoutSessionId == nil {
                activeWorkoutSessionId = event.sessionId
                activeWorkoutSource = .watch
            }

            switch event.type {
            case .start:
                activeWorkoutSessionId = event.sessionId
                activeWorkoutSource = .watch
                startWorkoutFromWatch()
            default:
                if event.sessionId != activeWorkoutSessionId {
                    if event.type == .end {
                        activeWorkoutSessionId = event.sessionId
                        activeWorkoutSource = .watch
                    } else {
                        watchEventBufferStore.append(event)
                        continue
                    }
                }

                if ensureWatchRuntimeReadyIfPossible(sessionId: event.sessionId) {
                    applyBufferedWatchEventsIfAny(sessionId: event.sessionId)
                    workoutRuntime?.applyWatchEvent(event)
                } else {
                    watchEventBufferStore.append(event)
                    if event.type == .end {
                        activeWorkoutSource = .watch
                        handleWorkoutCompleted(sessionId: event.sessionId)
                    }
                }
            }
        }
    }

    // MARK: - Private Watch Helpers

    private var watchStartTask: Task<Void, Never>? = nil

    private func startWorkoutFromWatch() {
        watchStartTask?.cancel()
        watchStartTask = Task { @MainActor in
            activeWorkoutSource = .watch
            activeWorkoutSaveState = .idle

            guard let sessionId = activeWorkoutSessionId else { return }

            navigation.goToWorkoutPreview1()

            if let stored = watchPlanStore.load(sessionId: sessionId), !stored.exercises.isEmpty {
                currentWorkoutPlan = stored
                ensureWorkoutRuntime(plan: stored, sessionId: sessionId)
                sendWorkoutSnapshotIfReady(sessionId: sessionId)
                applyBufferedWatchEventsIfAny(sessionId: sessionId)
                return
            }

            sendWatchStatusSnapshot(sessionId: sessionId, status: .generating, message: "Generating plan...")

            await generateWorkoutPlan()
            guard !Task.isCancelled else { return }

            if let plan = currentWorkoutPlan, !plan.exercises.isEmpty {
                watchPlanStore.save(plan: plan, sessionId: sessionId)
                ensureWorkoutRuntime(plan: plan, sessionId: sessionId)
                sendWorkoutSnapshotIfReady(sessionId: sessionId)
                applyBufferedWatchEventsIfAny(sessionId: sessionId)
            } else {
                sendWatchStatusSnapshot(sessionId: sessionId, status: .error, message: "Plan generation failed")
            }
        }
    }

    private func handleWorkoutCompleted(sessionId: String) {
        goToSummary()
        if activeWorkoutSource == .watch {
            autoSaveCompletedWorkoutIfNeeded(sessionId: sessionId)
        }
    }

    private func sendWatchStatusSnapshot(sessionId: String, status: FitMeWatchWorkoutStatus, message: String) {
        let snapshot = FitMeWorkoutStateSnapshot(
            sessionId: sessionId,
            status: status,
            exerciseName: message,
            currentExerciseIndex: 0,
            totalExercises: 0,
            currentSetIndex: 0,
            totalSets: 0,
            currentWeight: nil,
            currentReps: nil,
            weightUnit: nil,
            restRemainingSeconds: 0,
            updatedAt: Date()
        )
        watchWorkoutSync.sendWorkoutState(snapshot)
    }

    private func sendWatchWorkoutSummaryIfPossible(sessionId: String, plan: WorkoutPlan?, saveState: WorkoutSaveState) {
        let totalExercises = plan?.exercises.count ?? 0
        let totalSets = plan?.exercises.reduce(0, { $0 + $1.sets.count }) ?? 0

        var savedSessionRecordId: String?
        if case .saved(let sid, let record) = saveState, sid == sessionId {
            savedSessionRecordId = record.id
        }

        let summary = FitMeWatchWorkoutSummary(
            sessionId: sessionId,
            planTitle: plan?.title,
            estimatedMinutes: plan?.estimatedMinutes,
            estimatedCalories: plan?.estimatedCalories,
            totalExercises: totalExercises,
            totalSets: totalSets,
            saveStatus: saveState.watchSaveStatus,
            savedSessionRecordId: savedSessionRecordId,
            saveErrorMessage: (saveState.sessionId == sessionId) ? saveState.errorMessage : nil,
            updatedAt: Date()
        )
        watchWorkoutSync.sendWorkoutSummary(summary)
    }

    private func sendWatchWorkoutSummary(
        sessionId: String,
        plan: WorkoutPlan?,
        saveStatus: FitMeWatchSaveStatus,
        savedSessionRecordId: String?,
        saveErrorMessage: String?
    ) {
        let totalExercises = plan?.exercises.count ?? 0
        let totalSets = plan?.exercises.reduce(0, { $0 + $1.sets.count }) ?? 0
        let summary = FitMeWatchWorkoutSummary(
            sessionId: sessionId,
            planTitle: plan?.title,
            estimatedMinutes: plan?.estimatedMinutes,
            estimatedCalories: plan?.estimatedCalories,
            totalExercises: totalExercises,
            totalSets: totalSets,
            saveStatus: saveStatus,
            savedSessionRecordId: savedSessionRecordId,
            saveErrorMessage: saveErrorMessage,
            updatedAt: Date()
        )
        watchWorkoutSync.sendWorkoutSummary(summary)
    }

    private func sendWatchWorkoutSummary(
        sessionId: String,
        planTitle: String?,
        estimatedMinutes: Int?,
        estimatedCalories: Int?,
        totalExercises: Int,
        totalSets: Int,
        saveStatus: FitMeWatchSaveStatus,
        savedSessionRecordId: String?,
        saveErrorMessage: String?
    ) {
        let summary = FitMeWatchWorkoutSummary(
            sessionId: sessionId,
            planTitle: planTitle,
            estimatedMinutes: estimatedMinutes,
            estimatedCalories: estimatedCalories,
            totalExercises: totalExercises,
            totalSets: totalSets,
            saveStatus: saveStatus,
            savedSessionRecordId: savedSessionRecordId,
            saveErrorMessage: saveErrorMessage,
            updatedAt: Date()
        )
        watchWorkoutSync.sendWorkoutSummary(summary)
    }

    private func ensureWatchRuntimeReadyIfPossible(sessionId: String) -> Bool {
        if let runtime = workoutRuntime, runtime.sessionId == sessionId {
            return true
        }

        if let plan = watchPlanStore.load(sessionId: sessionId) {
            activeWorkoutSource = .watch
            activeWorkoutSessionId = sessionId
            currentWorkoutPlan = plan
            ensureWorkoutRuntime(plan: plan, sessionId: sessionId)
            return workoutRuntime?.sessionId == sessionId
        }

        return false
    }

    private func applyBufferedWatchEventsIfAny(sessionId: String) {
        guard let runtime = workoutRuntime, runtime.sessionId == sessionId else { return }
        let buffered = watchEventBufferStore.drain(sessionId: sessionId)
        guard !buffered.isEmpty else { return }

        let sorted = buffered.sorted { $0.timestamp < $1.timestamp }
        for event in sorted {
            runtime.applyWatchEvent(event)
        }
    }

    private func retryPendingWatchSavesOnLaunch() {
        pendingWatchSaveRetryTask?.cancel()
        pendingWatchSaveRetryTask = Task { @MainActor in
            let pending = pendingWatchSaveStore.loadAll()
            guard !pending.isEmpty else { return }

            for item in pending {
                guard !Task.isCancelled else { return }

                let plan = watchPlanStore.load(sessionId: item.sessionId)
                let planTitle = plan?.title ?? item.planTitle
                let estimatedMinutes = plan?.estimatedMinutes ?? item.estimatedMinutes
                let estimatedCalories = plan?.estimatedCalories ?? item.estimatedCalories
                let totalExercises = plan?.exercises.count ?? item.totalExercises
                let totalSets = plan?.exercises.reduce(0, { $0 + $1.sets.count }) ?? item.totalSets

                sendWatchWorkoutSummary(sessionId: item.sessionId,
                                       planTitle: planTitle,
                                       estimatedMinutes: estimatedMinutes,
                                       estimatedCalories: estimatedCalories,
                                       totalExercises: totalExercises,
                                       totalSets: totalSets,
                                       saveStatus: .saving,
                                       savedSessionRecordId: nil,
                                       saveErrorMessage: nil)

                let result = await sessionRepo.saveWorkoutSessionInternal(durationMinutes: item.durationMinutes, exercises: item.exercises)
                switch result {
                case .success(let record):
                    pendingWatchSaveStore.remove(sessionId: item.sessionId)
                    watchPlanStore.remove(sessionId: item.sessionId)
                    watchEventBufferStore.clear(sessionId: item.sessionId)
                    sendWatchWorkoutSummary(sessionId: item.sessionId,
                                           planTitle: planTitle,
                                           estimatedMinutes: estimatedMinutes,
                                           estimatedCalories: estimatedCalories,
                                           totalExercises: totalExercises,
                                           totalSets: totalSets,
                                           saveStatus: .saved,
                                           savedSessionRecordId: record.id,
                                           saveErrorMessage: nil)
                case .failure(let error):
                    pendingWatchSaveStore.recordAttemptFailed(sessionId: item.sessionId, errorMessage: error.localizedDescription)
                    sendWatchWorkoutSummary(sessionId: item.sessionId,
                                           planTitle: planTitle,
                                           estimatedMinutes: estimatedMinutes,
                                           estimatedCalories: estimatedCalories,
                                           totalExercises: totalExercises,
                                           totalSets: totalSets,
                                           saveStatus: .failed,
                                           savedSessionRecordId: nil,
                                           saveErrorMessage: error.localizedDescription)
                }
            }
        }
    }

    private var autoSaveTask: Task<Void, Never>? = nil

    private func autoSaveCompletedWorkoutIfNeeded(sessionId: String) {
        guard activeWorkoutSource == .watch else { return }
        let plan = completedWorkoutPlan ?? currentWorkoutPlan ?? watchPlanStore.load(sessionId: sessionId)
        guard let plan else {
            sendWatchWorkoutSummaryIfPossible(sessionId: sessionId, plan: nil, saveState: .failed(sessionId: sessionId, message: "Missing workout plan"))
            return
        }

        switch activeWorkoutSaveState {
        case .saving(let sid) where sid == sessionId:
            return
        case .saved(let sid, _) where sid == sessionId:
            sendWatchWorkoutSummaryIfPossible(sessionId: sessionId, plan: plan, saveState: activeWorkoutSaveState)
            return
        default:
            break
        }

        autoSaveTask?.cancel()
        activeWorkoutSaveState = .saving(sessionId: sessionId)
        sendWatchWorkoutSummaryIfPossible(sessionId: sessionId, plan: plan, saveState: activeWorkoutSaveState)

        autoSaveTask = Task { @MainActor in
            let exercises = plan.exercises.map { SessionExercise(exerciseId: $0.exerciseId, sets: $0.sets) }
            let durationMinutes = plan.estimatedMinutes

            let result = await sessionRepo.saveWorkoutSessionInternal(durationMinutes: durationMinutes, exercises: exercises)
            switch result {
            case .success(let record):
                activeWorkoutSaveState = .saved(sessionId: sessionId, record: record)
                pendingWatchSaveStore.remove(sessionId: sessionId)
                watchPlanStore.remove(sessionId: sessionId)
                watchEventBufferStore.clear(sessionId: sessionId)
            case .failure(let error):
                activeWorkoutSaveState = .failed(sessionId: sessionId, message: error.localizedDescription)
                pendingWatchSaveStore.upsert(sessionId: sessionId,
                                             durationMinutes: durationMinutes,
                                             exercises: exercises,
                                             plan: plan,
                                             errorMessage: error.localizedDescription)
            }
            sendWatchWorkoutSummaryIfPossible(sessionId: sessionId, plan: plan, saveState: activeWorkoutSaveState)
        }
    }

    private func applyQuickStartPresetDefaults() {
        workoutCondition = "normal"
        workoutEquipment = ["barbell", "dumbbell", "cable", "machine"]
    }

    private func stagePlanForWatchStartIfNeeded(plan: WorkoutPlan) {
        guard activeWorkoutSource == .phone else { return }
        guard activeWorkoutSessionId == nil else { return }
        guard workoutRuntime == nil else { return }
        guard navigation.currentScreen == .workoutPreview1 || navigation.currentScreen == .workoutPreview2 else { return }

        let sessionId = stagedNextWatchSessionId ?? UUID().uuidString
        stagedNextWatchSessionId = sessionId
        watchPlanStore.save(plan: plan, sessionId: sessionId)

        let firstExercise = plan.exercises.first
        let firstSet = firstExercise?.sets.first

        let snapshot = FitMeWorkoutStateSnapshot(
            sessionId: sessionId,
            status: .idle,
            exerciseName: plan.title,
            currentExerciseIndex: 0,
            totalExercises: plan.exercises.count,
            currentSetIndex: 1,
            totalSets: firstExercise?.sets.count ?? 0,
            currentWeight: firstSet.map { Int($0.weight) },
            currentReps: firstSet?.reps,
            weightUnit: "kg",
            restRemainingSeconds: 0,
            updatedAt: Date()
        )
        watchWorkoutSync.sendWorkoutState(snapshot)
    }

    private func ensureWorkoutRuntime(plan: WorkoutPlan, sessionId: String) {
        if let runtime = workoutRuntime, runtime.sessionId == sessionId {
            return
        }

        workoutRuntime?.stop()
        workoutRuntime = WorkoutRuntime(
            plan: plan,
            sessionId: sessionId,
            watchWorkoutSync: watchWorkoutSync,
            onComplete: { [weak self] in
                self?.handleWorkoutCompleted(sessionId: sessionId)
            }
        )
        workoutRuntime?.start()
    }

    private func sendWorkoutSnapshotIfReady(sessionId: String) {
        guard let runtime = workoutRuntime, runtime.sessionId == sessionId else { return }
        runtime.sendSnapshotIfNeeded()
    }
}

// MARK: - WorkoutRuntime

@MainActor
final class WorkoutRuntime: ObservableObject {
    private let watchWorkoutSync: WatchWorkoutSync
    private let onComplete: () -> Void
    private var timer: Timer?
    private var didStart = false
    private var isEnded = false

    let plan: WorkoutPlan
    let sessionId: String

    @Published var phase: WorkoutSessionPhase = .lifting
    @Published var isPaused: Bool = false
    @Published var restRemaining: Int = 60
    @Published var setHistory: [WorkoutSetEntry] = []
    @Published var weightValue: Int = 0
    @Published var repsValue: Int = 0
    @Published var currentSetIndex: Int = 1
    @Published var totalSets: Int = 0
    @Published var currentExerciseIndex: Int = 0
    @Published var workoutElapsedSeconds: Int = 0

    var currentExercise: WorkoutPlanExercise? {
        guard currentExerciseIndex < plan.exercises.count else { return nil }
        return plan.exercises[currentExerciseIndex]
    }

    var isCurrentExerciseBodyweight: Bool {
        currentExercise?.isBodyweight ?? false
    }

    var totalExercises: Int {
        plan.exercises.count
    }

    init(plan: WorkoutPlan, sessionId: String, watchWorkoutSync: WatchWorkoutSync, onComplete: @escaping () -> Void) {
        self.plan = plan
        self.sessionId = sessionId
        self.watchWorkoutSync = watchWorkoutSync
        self.onComplete = onComplete
        configureForCurrentExercise(resetIndices: true)
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        startTimer()
        sendSnapshotIfNeeded()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func applyWatchEvent(_ event: FitMeWatchEvent) {
        guard !isEnded else { return }
        switch event.type {
        case .start:
            break
        case .completeSet:
            completeSet()
        case .skipRest:
            if phase == .resting {
                completeSet()
            }
        case .adjustRest:
            if phase == .resting, let raw = event.payload?["seconds"], let seconds = Int(raw) {
                restRemaining = max(0, min(600, seconds))
                sendSnapshotIfNeeded()
            }
        case .adjustWeight:
            if phase == .lifting, let raw = event.payload?["value"], let value = Int(raw) {
                weightValue = max(0, value)
                sendSnapshotIfNeeded()
            }
        case .adjustReps:
            if phase == .lifting, let raw = event.payload?["value"], let value = Int(raw) {
                repsValue = max(0, value)
                sendSnapshotIfNeeded()
            }
        case .pause:
            pause()
        case .resume:
            resume()
        case .skipSet:
            if phase == .lifting {
                startRest()
            }
        case .changeExercise:
            if currentExerciseIndex + 1 < totalExercises {
                moveToNextExercise()
            }
        case .end:
            endWorkout()
        }
    }

    func completeSet() {
        guard !isPaused else { return }
        switch phase {
        case .resting:
            if currentSetIndex >= totalSets {
                if currentExerciseIndex + 1 >= totalExercises {
                    endWorkout()
                } else {
                    moveToNextExercise()
                }
            } else {
                currentSetIndex += 1
                phase = .lifting
                sendSnapshotIfNeeded()
            }
        case .lifting:
            let weightOk = isCurrentExerciseBodyweight || weightValue > 0
            guard weightOk, repsValue > 0 else { return }
            setHistory.append(WorkoutSetEntry(weight: String(weightValue), reps: String(repsValue)))

            if currentSetIndex >= totalSets {
                if currentExerciseIndex + 1 >= totalExercises {
                    endWorkout()
                } else {
                    startRest()
                }
            } else {
                startRest()
            }
        }
    }

    func startRest() {
        phase = .resting
        restRemaining = 60
        sendSnapshotIfNeeded()
    }

    func pause() {
        guard !isPaused else { return }
        isPaused = true
        sendSnapshotIfNeeded()
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        sendSnapshotIfNeeded()
    }

    func updateWeight(_ value: Int) {
        guard phase == .lifting else { return }
        weightValue = max(0, value)
        sendSnapshotIfNeeded()
    }

    func updateReps(_ value: Int) {
        guard phase == .lifting else { return }
        repsValue = max(0, value)
        sendSnapshotIfNeeded()
    }

    func endWorkout() {
        guard !isEnded else { return }
        isEnded = true
        isPaused = false
        sendSnapshot(ended: true)
        stop()
        onComplete()
    }

    func sendSnapshotIfNeeded() {
        sendSnapshot(ended: false)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard !isPaused, !isEnded else { return }
        if phase == .resting {
            if restRemaining > 0 {
                restRemaining -= 1
            }

            if restRemaining <= 0 {
                completeSet()
            } else {
                sendSnapshotIfNeeded()
            }
        } else {
            workoutElapsedSeconds += 1
        }
    }

    func skipToNextExercise() {
        guard currentExerciseIndex + 1 < totalExercises else { return }
        currentExerciseIndex += 1
        configureForCurrentExercise(resetIndices: true)
        sendSnapshotIfNeeded()
    }

    func goToPreviousExercise() {
        guard currentExerciseIndex > 0 else { return }
        currentExerciseIndex -= 1
        configureForCurrentExercise(resetIndices: true)
        sendSnapshotIfNeeded()
    }

    private func moveToNextExercise() {
        currentExerciseIndex += 1
        configureForCurrentExercise(resetIndices: true)
        sendSnapshotIfNeeded()
    }

    private func configureForCurrentExercise(resetIndices: Bool) {
        if resetIndices {
            currentSetIndex = 1
            setHistory = []
            phase = .lifting
        }
        if let exercise = currentExercise {
            totalSets = exercise.sets.count
            if let firstSet = exercise.sets.first {
                weightValue = Int(firstSet.weight)
                repsValue = firstSet.reps
            } else {
                weightValue = 0
                repsValue = 0
            }
        } else {
            totalSets = 0
            weightValue = 0
            repsValue = 0
        }
    }

    private func sendSnapshot(ended: Bool) {
        let exerciseName = currentExercise?.exerciseId.replacingOccurrences(of: "_", with: " ").capitalized ?? "Exercise"
        let status: FitMeWatchWorkoutStatus
        if ended {
            status = .ended
        } else if isPaused {
            status = .paused
        } else if phase == .resting {
            status = .resting
        } else {
            status = .active
        }

        let snapshot = FitMeWorkoutStateSnapshot(
            sessionId: sessionId,
            status: status,
            exerciseName: exerciseName,
            currentExerciseIndex: currentExerciseIndex,
            totalExercises: totalExercises,
            currentSetIndex: currentSetIndex,
            totalSets: totalSets,
            currentWeight: weightValue,
            currentReps: repsValue,
            weightUnit: "kg",
            restRemainingSeconds: phase == .resting ? restRemaining : 0,
            isBodyweight: isCurrentExerciseBodyweight,
            updatedAt: Date()
        )
        watchWorkoutSync.sendWorkoutState(snapshot)
    }
}

struct WorkoutSetEntry: Equatable {
    let weight: String
    let reps: String
}

enum WorkoutSessionPhase {
    case lifting
    case resting
}

private final class WatchSessionPlanStore {
    private let defaults = UserDefaults.standard
    private let keyPrefix = "fitme.watch.plan."

    func save(plan: WorkoutPlan, sessionId: String) {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        defaults.set(data, forKey: keyPrefix + sessionId)
    }

    func load(sessionId: String) -> WorkoutPlan? {
        guard let data = defaults.data(forKey: keyPrefix + sessionId) else { return nil }
        return try? JSONDecoder().decode(WorkoutPlan.self, from: data)
    }

    func remove(sessionId: String) {
        defaults.removeObject(forKey: keyPrefix + sessionId)
    }
}

private final class WatchEventBufferStore {
    private static let maxEventsPerSession = 4000
    private let defaults = UserDefaults.standard
    private let keyPrefix = "fitme.watch.bufferedEvents."

    func append(_ event: FitMeWatchEvent) {
        let key = keyPrefix + event.sessionId
        var all = loadInternal(key: key)
        all.append(event)
        if all.count > Self.maxEventsPerSession {
            all.removeFirst(all.count - Self.maxEventsPerSession)
        }
        saveInternal(all, key: key)
    }

    func drain(sessionId: String) -> [FitMeWatchEvent] {
        let key = keyPrefix + sessionId
        let all = loadInternal(key: key)
        clear(sessionId: sessionId)
        return all
    }

    func clear(sessionId: String) {
        defaults.removeObject(forKey: keyPrefix + sessionId)
    }

    private func loadInternal(key: String) -> [FitMeWatchEvent] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? FitMeWatchCodec.decoder().decode([FitMeWatchEvent].self, from: data)) ?? []
    }

    private func saveInternal(_ events: [FitMeWatchEvent], key: String) {
        guard let data = try? FitMeWatchCodec.encoder().encode(events) else { return }
        defaults.set(data, forKey: key)
    }
}

private struct PendingWatchSave: Codable, Equatable {
    let sessionId: String
    let durationMinutes: Int
    let exercises: [SessionExercise]
    let planTitle: String?
    let estimatedMinutes: Int?
    let estimatedCalories: Int?
    let totalExercises: Int
    let totalSets: Int
    let createdAt: Date
    var attempts: Int
    var lastAttemptAt: Date?
    var lastErrorMessage: String?
}

private final class PendingWatchSaveStore {
    private static let storageKey = "fitme.watch.pendingSaves"
    private let defaults = UserDefaults.standard

    func loadAll() -> [PendingWatchSave] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        return (try? codecDecoder().decode([PendingWatchSave].self, from: data)) ?? []
    }

    func upsert(
        sessionId: String,
        durationMinutes: Int,
        exercises: [SessionExercise],
        plan: WorkoutPlan?,
        errorMessage: String?
    ) {
        var all = loadAll()

        let totalExercises = plan?.exercises.count ?? 0
        let totalSets = plan?.exercises.reduce(0, { $0 + $1.sets.count }) ?? 0

        if let idx = all.firstIndex(where: { $0.sessionId == sessionId }) {
            var existing = all[idx]
            existing.lastErrorMessage = errorMessage
            all[idx] = PendingWatchSave(
                sessionId: sessionId,
                durationMinutes: durationMinutes,
                exercises: exercises,
                planTitle: plan?.title ?? existing.planTitle,
                estimatedMinutes: plan?.estimatedMinutes ?? existing.estimatedMinutes,
                estimatedCalories: plan?.estimatedCalories ?? existing.estimatedCalories,
                totalExercises: totalExercises > 0 ? totalExercises : existing.totalExercises,
                totalSets: totalSets > 0 ? totalSets : existing.totalSets,
                createdAt: existing.createdAt,
                attempts: existing.attempts,
                lastAttemptAt: existing.lastAttemptAt,
                lastErrorMessage: errorMessage ?? existing.lastErrorMessage
            )
        } else {
            all.append(
                PendingWatchSave(
                    sessionId: sessionId,
                    durationMinutes: durationMinutes,
                    exercises: exercises,
                    planTitle: plan?.title,
                    estimatedMinutes: plan?.estimatedMinutes,
                    estimatedCalories: plan?.estimatedCalories,
                    totalExercises: totalExercises,
                    totalSets: totalSets,
                    createdAt: Date(),
                    attempts: 0,
                    lastAttemptAt: nil,
                    lastErrorMessage: errorMessage
                )
            )
        }

        saveAll(all)
    }

    func recordAttemptFailed(sessionId: String, errorMessage: String) {
        var all = loadAll()
        guard let idx = all.firstIndex(where: { $0.sessionId == sessionId }) else { return }
        var item = all[idx]
        item.attempts += 1
        item.lastAttemptAt = Date()
        item.lastErrorMessage = errorMessage
        all[idx] = item
        saveAll(all)
    }

    func remove(sessionId: String) {
        var all = loadAll()
        all.removeAll { $0.sessionId == sessionId }
        saveAll(all)
    }

    private func saveAll(_ items: [PendingWatchSave]) {
        if items.isEmpty {
            defaults.removeObject(forKey: Self.storageKey)
            return
        }
        guard let data = try? codecEncoder().encode(items) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private func codecEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func codecDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
