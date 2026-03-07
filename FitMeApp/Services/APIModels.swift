import Foundation

// MARK: - API Response Models

struct Mission: Codable, Identifiable, Equatable {
    let id: String
    let type: MissionType
    let targetValue: Int
    let difficulty: MissionDifficulty
    let startAt: String
    let endAt: String
    var progressValue: Int
    var status: MissionStatus
    
    enum CodingKeys: String, CodingKey {
        case id, type, difficulty, status
        case targetValue = "target_value"
        case startAt = "start_at"
        case endAt = "end_at"
        case progressValue = "progress_value"
    }

    private struct AnyCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init(_ string: String) { self.stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let any = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MissionType.self, forKey: .type)
        targetValue =
            (try? container.decodeIfPresent(Int.self, forKey: .targetValue))
            ?? (try? any.decodeIfPresent(Int.self, forKey: AnyCodingKey("targetValue")))
            ?? 0
        difficulty =
            (try? container.decodeIfPresent(MissionDifficulty.self, forKey: .difficulty))
            ?? (try? any.decodeIfPresent(MissionDifficulty.self, forKey: AnyCodingKey("difficulty")))
            ?? .easy
        startAt =
            (try? container.decodeIfPresent(String.self, forKey: .startAt))
            ?? (try? any.decodeIfPresent(String.self, forKey: AnyCodingKey("startAt")))
            ?? ""
        endAt =
            (try? container.decodeIfPresent(String.self, forKey: .endAt))
            ?? (try? any.decodeIfPresent(String.self, forKey: AnyCodingKey("endAt")))
            ?? ""
        progressValue =
            (try? container.decodeIfPresent(Int.self, forKey: .progressValue))
            ?? (try? any.decodeIfPresent(Int.self, forKey: AnyCodingKey("progressValue")))
            ?? 0
        // status 없으면 기본값 active
        status =
            (try? container.decodeIfPresent(MissionStatus.self, forKey: .status))
            ?? (try? any.decodeIfPresent(MissionStatus.self, forKey: AnyCodingKey("status")))
            ?? .active
    }
    
    var isComplete: Bool {
        progress >= 1.0
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(progressValue) / Double(targetValue), 1.0)
    }
    
    var displayTitle: String {
        switch type {
        case .calories: return "Calories"
        case .minutes: return "Active"
        case .sessions: return "Workouts"
        }
    }
    
    var icon: String {
        switch type {
        case .calories: return "local_fire_department"
        case .minutes: return "timer"
        case .sessions: return "fitness_center"
        }
    }
    
    var colorHex: String {
        switch type {
        case .calories: return "#F97316"
        case .minutes: return "#60A5FA"
        case .sessions: return "#FF8577"
        }
    }
    
    var valueSuffix: String {
        switch type {
        case .calories: return "kcal"
        case .minutes: return "m"
        case .sessions: return "/\(targetValue)"
        }
    }
    
    var displayValue: String {
        String(progressValue)
    }
}

enum MissionType: String, Codable {
    case calories
    case minutes
    case sessions
}

enum MissionDifficulty: String, Codable {
    case easy
    case medium
    case hard
}

enum MissionStatus: String, Codable {
    case active
    case suspended
    case complete
}

struct DashboardResponse: Codable {
    let missions: [Mission]
    let totalPoints: Int
    let rank: String
}

struct MissionsResponse: Codable {
    let missions: [Mission]
}

struct ExerciseSet: Codable, Equatable {
    let weight: Double
    let reps: Int
}

struct WorkoutPlanExercise: Codable, Identifiable, Equatable {
    var id: String { exerciseId }
    let exerciseId: String
    let sets: [ExerciseSet]
    let isBodyweight: Bool
}

struct WorkoutPlan: Codable, Equatable {
    let title: String
    let estimatedMinutes: Int
    let estimatedCalories: Int
    let coachMessage: String
    let exercises: [WorkoutPlanExercise]
}

struct SessionExercise: Codable, Equatable {
    let exerciseId: String
    let sets: [ExerciseSet]
}

struct SessionSummary: Codable, Identifiable, Equatable {
    let id: String
    let date: String
    let source: SessionSource
    let durationMinutes: Int
    let calories: Int
    let totalExercises: Int
}

struct SessionDetail: Codable, Identifiable, Equatable {
    let id: String
    let date: String
    let source: SessionSource
    let durationMinutes: Int
    let calories: Int
    let exercises: [SessionExercise]
}

struct WeeklyReport: Codable, Identifiable, Equatable {
    let periodStart: String
    let periodEnd: String
    let totalWorkouts: Int
    let totalMinutes: Int
    let totalCalories: Int
    let averageMinutes: Int

    var id: String { periodStart }
}

struct WeeklyReportsResponse: Codable {
    let reports: [WeeklyReport]
}

enum SessionSource: String, Codable {
    case fitme
    case appleHealth = "apple_health"
    case other
}

// MARK: - Request Bodies

struct CreateMissionRequest: Encodable {
    let mode: String
    let type: String?
    let difficulty: String?
    let targetValue: Int?
    let startAt: String?
    
    enum CodingKeys: String, CodingKey {
        case mode, type, difficulty
        case targetValue = "target_value"
        case startAt = "start_at"
    }
}

struct GenerateWorkoutPlanRequest: Encodable {
    let condition: String
    let targetMinutes: Int
    let equipment: [String]
    let location: String

    enum CodingKeys: String, CodingKey {
        case condition, equipment, location
        case targetMinutes = "target_minutes"
    }
}

struct SaveSessionRequest: Encodable {
    let source: String
    let durationMinutes: Int
    let exercises: [SessionExercise]
    
    enum CodingKeys: String, CodingKey {
        case source, exercises
        case durationMinutes = "duration_minutes"
    }
}

// MARK: - Error Response

struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
}

struct DeleteMissionResponse: Codable {
    let success: Bool
}

struct UpdateMissionStatusRequest: Encodable {
    let status: String
}

struct UpdateMissionStatusResponse: Codable {
    let mission: Mission
}

// MARK: - User / Settings

struct MeResponse: Codable {
    let user: MeUser
    let profile: MeProfile
    let settings: MeSettings
}

struct MeUser: Codable {
    let id: String
    let firebaseUid: String
    let accountType: String
    let status: String
    let createdAt: String
    let updatedAt: String
}

struct MeProfile: Codable {
    let displayName: String?
    let email: String?
    let photoUrl: String?
    let timezone: String
    let locale: String
    let updatedAt: String
}

struct MeSettings: Codable {
    let workoutPreferences: [String: JSONValue]
    let units: [String: JSONValue]
    let notification: [String: JSONValue]
    let privacy: [String: JSONValue]
    let updatedAt: String
}

struct PersonalInfoResponse: Codable {
    let birthSex: String?
    let age: Int?
    let heightCm: Double?
    let weightKg: Double?
    let experienceLevel: String?
    let experienceDuration: String?
    let goal: String?
    let preferredLocation: String?
    let equipment: [String]?
    let weeklyTrainingDays: Int?
    let preferredSessionMinutes: Int?
    let onboardingCompletedAt: String?
}

struct PersonalInfoPatchRequest: Encodable {
    let age: Int?
    let heightCm: Double?
    let weightKg: Double?
}

struct UpdateProfileRequest: Encodable {
    let displayName: String?
    let timezone: String?
    let locale: String?
    let photoURL: String?
}

enum JSONValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}
