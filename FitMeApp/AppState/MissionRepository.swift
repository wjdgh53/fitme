import Foundation

@MainActor
final class MissionRepository: ObservableObject {
    // MARK: - Published State
    @Published private(set) var missions: [Mission] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Computed Properties
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

    var hasMissions: Bool {
        !missions.isEmpty
    }

    var completedMissionsCount: Int {
        missions.filter { $0.status == .complete }.count
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

    func loadMissions() async {
        do {
            let response = try await APIClient.shared.getMissions()
            missions = response.missions
            recalculateMissionProgress()
        } catch {
            #if DEBUG
            print("Missions load error: \(error)")
            #endif
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

    // MARK: - Dashboard Integration

    /// Called by AppViewModel during dashboard load to bulk-update missions and points.
    func applyDashboardMissions(_ newMissions: [Mission]) {
        missions = newMissions
        recalculateMissionProgress()
    }

    // MARK: - Progress Recalculation

    func recalculateMissionProgress() {
        checkAndCompleteMissions()
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

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}
