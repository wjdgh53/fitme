import Foundation
import SwiftUI

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
    private static let legacyProfileImageDataKey = "fitme.profileImageData"
    private static let profileImageDirectoryName = "fitme"
    private static let profileImageFileName = "profile-avatar.jpg"
    private static let presetConditionKey = "fitme.preset.condition"
    private static let presetTargetMinutesKey = "fitme.preset.targetMinutes"
    private static let presetEquipmentKey = "fitme.preset.equipment"

    private static func profileImageDirectoryURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(profileImageDirectoryName, isDirectory: true)
    }

    private static func profileImageFileURL() -> URL {
        profileImageDirectoryURL().appendingPathComponent(profileImageFileName, isDirectory: false)
    }

    private static func ensureProfileImageDirectoryExists() throws {
        let dir = profileImageDirectoryURL()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

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
    @Published private(set) var workoutRuntime: WorkoutRuntime?
    
    // MARK: - Session State
    @Published private(set) var sessions: [SessionSummary] = []
    @Published private(set) var currentSessionDetail: SessionDetail?
    @Published private(set) var weeklyReports: [WeeklyReport] = []
    @Published private(set) var currentWeeklyReport: WeeklyReport?
    
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
                        // End should reliably advance to summary even if runtime isn't ready.
                        activeWorkoutSource = .watch
                        handleWorkoutCompleted(sessionId: event.sessionId)
                    }
                }
            }
        }
    }

    private var watchStartTask: Task<Void, Never>? = nil

    private func startWorkoutFromWatch() {
        watchStartTask?.cancel()
        watchStartTask = Task { @MainActor in
            activeWorkoutSource = .watch
            activeWorkoutSaveState = .idle

            guard let sessionId = activeWorkoutSessionId else { return }

            // Bring iPhone into a workout UI state immediately.
            screenStack = [.workoutPreview1]

            if let stored = watchPlanStore.load(sessionId: sessionId), !stored.exercises.isEmpty {
                // Plan already staged (e.g., generated on iPhone). Skip the generating step.
                currentWorkoutPlan = stored
                ensureWorkoutRuntime(plan: stored, sessionId: sessionId)
                sendWorkoutSnapshotIfReady(sessionId: sessionId)
                applyBufferedWatchEventsIfAny(sessionId: sessionId)
                return
            }

            sendWatchStatusSnapshot(sessionId: sessionId, status: .generating, message: "Generating plan...")

            await generateWorkoutPlan()
            guard !Task.isCancelled else { return }

            // Only start if a new plan was created and is valid.
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

                let result = await saveWorkoutSessionInternal(durationMinutes: item.durationMinutes, exercises: item.exercises)
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

            let result = await saveWorkoutSessionInternal(durationMinutes: durationMinutes, exercises: exercises)
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
    
    // MARK: - User Profile (TODO: Auth)
    @Published var userName: String = "User"
    var profileImageURL: URL? = nil
    @Published var profileImageData: Data? = nil

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

        let url = Self.profileImageFileURL()
        if let data = try? Data(contentsOf: url) {
            profileImageData = data
        }

        // Legacy migration from UserDefaults -> file
        if let legacyData = defaults.data(forKey: Self.legacyProfileImageDataKey) {
            do {
                try Self.ensureProfileImageDirectoryExists()
                try legacyData.write(to: url, options: [.atomic])
                profileImageData = legacyData
                defaults.removeObject(forKey: Self.legacyProfileImageDataKey)
            } catch {
                profileImageData = legacyData
            }
        }

        retryPendingWatchSavesOnLaunch()
    }
    
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
            recalculateMissionProgress()
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
            recalculateMissionProgress()
        } catch {
            print("Missions load error: \(error)")
        }
    }
    
    private func checkAndCompleteMissions() {
        for i in missions.indices where missions[i].status == .active {
            if missions[i].isComplete {
                let missionId = missions[i].id
                missions[i].status = .complete
                Task {
                    try? await APIClient.shared.updateMissionStatus(id: missionId, status: .complete)
                }
            }
        }
    }

    private func recalculateMissionProgress() {
        checkAndCompleteMissions()
    }

    private func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: value)
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
            let response = try await APIClient.shared.createWeeklyMissions(startAt: todayString())
            missions = response.missions
            recalculateMissionProgress()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createAISingleMission(type: MissionType) async -> String? {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.createAISingleMission(type: type, startAt: todayString())
            missions = response.missions
            recalculateMissionProgress()
            await loadMissions()
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return errorMessage
        }
    }

    func createCustomMission(type: MissionType, difficulty: MissionDifficulty, targetValue: Int) async -> String? {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.createCustomMission(
                type: type,
                difficulty: difficulty,
                targetValue: targetValue,
                startAt: todayString()
            )
            missions = response.missions
            recalculateMissionProgress()
            await loadMissions()
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return errorMessage
        }
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
        let sourceAtStart = activeWorkoutSource
        isGeneratingPlan = true
        errorMessage = nil
        currentWorkoutPlan = nil
        
        do {
            currentWorkoutPlan = try await APIClient.shared.generateWorkoutPlan(
                condition: workoutCondition,
                targetMinutes: workoutTargetMinutes,
                equipment: workoutEquipment
            )
            if sourceAtStart == .phone, let plan = currentWorkoutPlan, !plan.exercises.isEmpty {
                stagePlanForWatchStartIfNeeded(plan: plan)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Workout plan generation error: \(error)")
        }
        
        isGeneratingPlan = false
    }

    private func stagePlanForWatchStartIfNeeded(plan: WorkoutPlan) {
        guard activeWorkoutSource == .phone else { return }
        guard activeWorkoutSessionId == nil else { return }
        guard workoutRuntime == nil else { return }
        guard currentScreen == .workoutPreview1 || currentScreen == .workoutPreview2 else { return }

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
    
    func loadSessions(period: String? = nil) async {
        do {
            sessions = try await APIClient.shared.getSessions(period: period)
            recalculateMissionProgress()
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

    func loadWeeklyReports() async {
        do {
            weeklyReports = try await APIClient.shared.getWeeklyReports()
        } catch {
            print("Weekly reports load error: \(error)")
        }
    }

    func loadWeeklyReportDetail(startAt: String) async {
        do {
            currentWeeklyReport = try await APIClient.shared.getWeeklyReport(startAt: startAt)
        } catch {
            print("Weekly report detail load error: \(error)")
        }
    }
    
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

            let result = await saveWorkoutSessionInternal(durationMinutes: durationMinutes, exercises: exercises)
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
            return
        }

        _ = await saveWorkoutSessionInternal(durationMinutes: durationMinutes, exercises: exercises)
    }

    private func saveWorkoutSessionInternal(durationMinutes: Int, exercises: [SessionExercise]) async -> Result<SessionSummary, Error> {
        print("📥 [AppViewModel] saveWorkoutSession: \(durationMinutes)min, \(exercises.count) exercises")
        do {
            let session = try await APIClient.shared.saveSession(
                source: .fitme,
                durationMinutes: durationMinutes,
                exercises: exercises
            )
            print("✅ [AppViewModel] Session saved: id=\(session.id), calories=\(session.calories)")
            sessions.insert(session, at: 0)
            recalculateMissionProgress()
            await loadMissions()
            return .success(session)
        } catch {
            print("❌ [AppViewModel] Save failed: \(error)")
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
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

    func setProfileImageData(_ data: Data?) throws {
        profileImageData = data

        let url = Self.profileImageFileURL()
        if let data {
            try Self.ensureProfileImageDirectoryExists()
            try data.write(to: url, options: [.atomic])
        } else {
            try? FileManager.default.removeItem(at: url)
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
        activeWorkoutSource = .phone
        activeWorkoutSaveState = .idle
        activeWorkoutSessionId = nil
        stagedNextWatchSessionId = nil
        errorMessage = nil
        currentWorkoutPlan = nil
        workoutRuntime?.stop()
        workoutRuntime = nil
        screenStack = [.presetCheck]
    }

    func startQuickWorkoutFlow() {
        activeWorkoutSource = .phone
        activeWorkoutSaveState = .idle
        screenStack = [.workoutPreview1]
        applyQuickStartPresetDefaults()
        Task { await generateWorkoutPlan() }
    }

    private func applyQuickStartPresetDefaults() {
        // Match the defaults shown in PresetCheckView.
        workoutCondition = "normal"
        workoutEquipment = ["barbell", "dumbbell", "cable", "machine"]
    }
    
    func goToWorkoutPreview1() {
        screenStack = [.workoutPreview1]
    }
    
    func goToWorkoutPreview2() {
        screenStack = [.workoutPreview2]
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
        activeWorkoutSessionId = nil
        activeWorkoutSource = .phone
        activeWorkoutSaveState = .idle
        workoutRuntime?.stop()
        workoutRuntime = nil
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

    func openWeeklyReportDetail(startAt: String) {
        Task {
            await loadWeeklyReportDetail(startAt: startAt)
            if currentWeeklyReport?.periodStart == startAt {
                push(.reportDetail)
            }
        }
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
            guard weightValue > 0, repsValue > 0 else { return }
            setHistory.append(WorkoutSetEntry(weight: String(weightValue), reps: String(repsValue)))

            if currentSetIndex >= totalSets {
                if currentExerciseIndex + 1 >= totalExercises {
                    endWorkout()
                } else {
                    // Keep a full 60s rest between exercises as well.
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

            // Auto-advance as soon as rest reaches 00:00.
            if restRemaining <= 0 {
                completeSet()
            } else {
                sendSnapshotIfNeeded()
            }
        } else {
            workoutElapsedSeconds += 1
        }
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
