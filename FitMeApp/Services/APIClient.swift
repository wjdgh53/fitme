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
        case .networkError(let error):
            let nsError = error as NSError
            let code = nsError.code
            let failingURLString = nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String ?? ""

            if code == NSURLErrorCannotConnectToHost {
                if failingURLString.contains("127.0.0.1:3000") || failingURLString.contains("localhost:3000") {
                    return "Cannot connect to local API server (127.0.0.1:3000). Start the backend server and try again."
                }
                return "Could not connect to the API server."
            }

            if code == NSURLErrorCannotFindHost {
                return "API hostname could not be resolved. Check the API base URL and network DNS."
            }

            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message): return message
        case .unauthorized: return "Unauthorized"
        case .unknown: return "Unknown error"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private static let debugFallbackBaseURL = "http://127.0.0.1:3000"
    private static let releaseFallbackBaseURL = "https://api.fitme.app/v1"
    
    private var authToken: String?
    private var tokenProvider: (() async -> String?)?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        baseURL = Self.resolveBaseURL()

        decoder = JSONDecoder()
        encoder = JSONEncoder()

        // Backend follows api_spec.yaml (snake_case).
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    private static func resolveBaseURL() -> String {
        if let configured = configuredBaseURLFromInfoPlist() {
            return configured
        }
        #if DEBUG
        return debugFallbackBaseURL
        #else
        return releaseFallbackBaseURL
        #endif
    }

    private static func configuredBaseURLFromInfoPlist() -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            return nil
        }
        return normalizedBaseURL(value)
    }

    private static func normalizedBaseURL(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // Ignore unresolved build-setting placeholders.
        guard !trimmed.contains("$(") else { return nil }
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else { return nil }
        return trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
    }
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    func setTokenProvider(_ provider: (() async -> String?)?) {
        self.tokenProvider = provider
    }
    
    // MARK: - Dashboard
    
    func getDashboard() async throws -> DashboardResponse {
        return try await request(endpoint: "/dashboard", method: "GET")
    }
    
    // MARK: - Missions
    
    func getMissions() async throws -> MissionsResponse {
        return try await request(endpoint: "/missions", method: "GET")
    }
    
    func createWeeklyMissions(startAt: String? = nil) async throws -> MissionsResponse {
        let body = CreateMissionRequest(
            mode: "ai",
            type: nil,
            difficulty: nil,
            targetValue: nil,
            startAt: startAt
        )
        return try await request(endpoint: "/missions", method: "POST", body: body)
    }

    func createAISingleMission(type: MissionType, startAt: String? = nil) async throws -> MissionsResponse {
        let body = CreateMissionRequest(
            mode: "ai",
            type: type.rawValue,
            difficulty: nil,
            targetValue: nil,
            startAt: startAt
        )
        return try await request(endpoint: "/missions", method: "POST", body: body)
    }

    func createCustomMission(type: MissionType, difficulty: MissionDifficulty, targetValue: Int, startAt: String? = nil) async throws -> MissionsResponse {
        let body = CreateMissionRequest(
            mode: "custom",
            type: type.rawValue,
            difficulty: difficulty.rawValue,
            targetValue: targetValue,
            startAt: startAt
        )
        return try await request(endpoint: "/missions", method: "POST", body: body)
    }
    
    func deleteMission(id: String) async throws {
        let _: DeleteMissionResponse = try await request(endpoint: "/missions/\(id)", method: "DELETE")
    }
    
    func updateMissionStatus(id: String, status: MissionStatus) async throws -> Mission {
        let body = UpdateMissionStatusRequest(status: status.rawValue)
        let response: UpdateMissionStatusResponse = try await request(endpoint: "/missions/\(id)", method: "PATCH", body: body)
        return response.mission
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

    // MARK: - Reports

    func getWeeklyReports(limit: Int? = nil) async throws -> [WeeklyReport] {
        var endpoint = "/reports/weekly"
        if let limit {
            endpoint += "?limit=\(limit)"
        }
        let response: WeeklyReportsResponse = try await request(endpoint: endpoint, method: "GET")
        return response.reports
    }

    func getWeeklyReport(startAt: String) async throws -> WeeklyReport {
        return try await request(endpoint: "/reports/weekly/\(startAt)", method: "GET")
    }

    // MARK: - Me

    func getMe() async throws -> MeResponse {
        return try await request(endpoint: "/me", method: "GET")
    }

    func updateProfile(_ input: UpdateProfileRequest) async throws -> MeProfile {
        return try await request(endpoint: "/me/profile", method: "PATCH", body: input)
    }

    func getSettings() async throws -> MeSettings {
        return try await request(endpoint: "/me/settings", method: "GET")
    }

    func updateWorkoutPreferences(_ data: [String: JSONValue]) async throws -> MeSettings {
        return try await request(endpoint: "/me/settings/workout-plan", method: "PUT", body: data)
    }
    
    // MARK: - Private
    
    private func request<T: Decodable>(endpoint: String, method: String) async throws -> T {
        return try await request(endpoint: endpoint, method: method, body: Optional<EmptyBody>.none)
    }
    
    private func request<T: Decodable, B: Encodable>(endpoint: String, method: String, body: B?) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        let requestBody = try body.map { try encoder.encode($0) }
        var request = try await makeRequest(url: url, method: method, body: requestBody)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        if httpResponse.statusCode == 401, tokenProvider != nil {
            request = try await makeRequest(url: url, method: method, body: requestBody)
            let retryData: Data
            let retryResponse: URLResponse
            do {
                (retryData, retryResponse) = try await URLSession.shared.data(for: request)
            } catch {
                throw APIError.networkError(error)
            }
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw APIError.unknown
            }
            return try decodeResponse(data: retryData, httpResponse: retryHTTP, endpoint: endpoint)
        }

        return try decodeResponse(data: data, httpResponse: httpResponse, endpoint: endpoint)
    }

    private func currentAuthorizationToken() async -> String? {
        if let tokenProvider {
            return await tokenProvider()
        }
        return authToken
    }

    private func makeRequest(url: URL, method: String, body: Data?) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = await currentAuthorizationToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }

    private func decodeResponse<T: Decodable>(data: Data, httpResponse: HTTPURLResponse, endpoint: String) throws -> T {
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                if let bodyString = String(data: data, encoding: .utf8) {
                    print("Decoding failed for \(endpoint). Status: \(httpResponse.statusCode). Body: \(bodyString)")
                } else {
                    print("Decoding failed for \(endpoint). Status: \(httpResponse.statusCode). Body: <non-utf8>")
                }
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
