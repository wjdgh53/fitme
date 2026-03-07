import Foundation

@MainActor
final class SessionRepository: ObservableObject {
    // MARK: - Published State
    @Published private(set) var sessions: [SessionSummary] = []
    @Published private(set) var currentSessionDetail: SessionDetail?
    @Published private(set) var weeklyReports: [WeeklyReport] = []
    @Published private(set) var currentWeeklyReport: WeeklyReport?
    @Published private(set) var errorMessage: String?

    var completedWorkoutsCount: Int {
        sessions.count
    }

    // MARK: - API Calls

    func loadSessions(period: String? = nil) async {
        do {
            sessions = try await APIClient.shared.getSessions(period: period)
        } catch {
            #if DEBUG
            print("Sessions load error: \(error)")
            #endif
        }
    }

    func loadSessionDetail(id: String) async {
        do {
            currentSessionDetail = try await APIClient.shared.getSession(id: id)
        } catch {
            #if DEBUG
            print("Session detail load error: \(error)")
            #endif
        }
    }

    func loadWeeklyReports() async {
        do {
            weeklyReports = try await APIClient.shared.getWeeklyReports()
        } catch {
            #if DEBUG
            print("Weekly reports load error: \(error)")
            #endif
        }
    }

    func loadWeeklyReportDetail(startAt: String) async {
        do {
            currentWeeklyReport = try await APIClient.shared.getWeeklyReport(startAt: startAt)
        } catch {
            #if DEBUG
            print("Weekly report detail load error: \(error)")
            #endif
        }
    }

    func saveWorkoutSessionInternal(durationMinutes: Int, exercises: [SessionExercise]) async -> Result<SessionSummary, Error> {
        #if DEBUG
        print("[SessionRepository] saveWorkoutSession: \(durationMinutes)min, \(exercises.count) exercises")
        #endif
        do {
            let session = try await APIClient.shared.saveSession(
                source: .fitme,
                durationMinutes: durationMinutes,
                exercises: exercises
            )
            #if DEBUG
            print("[SessionRepository] Session saved: id=\(session.id), calories=\(session.calories)")
            #endif
            sessions.insert(session, at: 0)
            return .success(session)
        } catch {
            #if DEBUG
            print("[SessionRepository] Save failed: \(error)")
            #endif
            return .failure(error)
        }
    }
}
