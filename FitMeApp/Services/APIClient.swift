import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message): return message
        case .unauthorized: return "Unauthorized"
        case .unknown: return "Unknown error"
        }
    }
}

actor APIClient {
    static let shared = APIClient()
    
    #if DEBUG
    private let baseURL = "http://localhost:3000"
    #else
    private let baseURL = "https://api.fitme.app/v1"
    #endif
    
    private var authToken: String?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    // MARK: - Dashboard
    
    func getDashboard() async throws -> DashboardResponse {
        return try await request(endpoint: "/dashboard", method: "GET")
    }
    
    // MARK: - Missions
    
    func getMissions() async throws -> MissionsResponse {
        return try await request(endpoint: "/missions", method: "GET")
    }
    
    func createMissions(mode: String, type: MissionType? = nil, difficulty: MissionDifficulty? = nil, targetValue: Int? = nil, startAt: String? = nil, aiSingle: Bool = false) async throws -> MissionsResponse {
        let body = CreateMissionRequest(
            mode: mode,
            type: type?.rawValue,
            difficulty: difficulty?.rawValue,
            targetValue: targetValue,
            startAt: startAt,
            aiSingle: aiSingle
        )
        return try await request(endpoint: "/missions", method: "POST", body: body)
    }
    
    func deleteMission(id: String) async throws {
        let _: DeleteMissionResponse = try await request(endpoint: "/missions/\(id)", method: "DELETE")
    }
    
    // MARK: - Workout Plan
    
    func generateWorkoutPlan(condition: String, targetMinutes: Int, equipment: [String]) async throws -> WorkoutPlan {
        let body = GenerateWorkoutPlanRequest(
            condition: condition,
            targetMinutes: targetMinutes,
            equipment: equipment
        )
        return try await request(endpoint: "/workout-plan", method: "POST", body: body)
    }
    
    // MARK: - Sessions
    
    func getSessions(period: String? = nil) async throws -> [SessionSummary] {
        var endpoint = "/sessions"
        if let period = period {
            endpoint += "?period=\(period)"
        }
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func getSession(id: String) async throws -> SessionDetail {
        return try await request(endpoint: "/sessions/\(id)", method: "GET")
    }
    
    func saveSession(source: SessionSource, durationMinutes: Int, exercises: [SessionExercise]) async throws -> SessionSummary {
        let body = SaveSessionRequest(
            source: source.rawValue,
            durationMinutes: durationMinutes,
            exercises: exercises
        )
        return try await request(endpoint: "/sessions", method: "POST", body: body)
    }
    
    // MARK: - Private
    
    private func request<T: Decodable>(endpoint: String, method: String) async throws -> T {
        return try await request(endpoint: endpoint, method: method, body: Optional<EmptyBody>.none)
    }
    
    private func request<T: Decodable, B: Encodable>(endpoint: String, method: String, body: B?) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 400...499, 500...599:
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error.message)
            }
            throw APIError.serverError("Server error: \(httpResponse.statusCode)")
        default:
            throw APIError.unknown
        }
    }
}

private struct EmptyBody: Encodable {}
