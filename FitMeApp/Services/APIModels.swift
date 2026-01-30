import Foundation

// MARK: - API Response Models

struct Mission: Codable, Identifiable, Equatable {
    let id: String
    let type: MissionType
    let targetValue: Int
    let difficulty: MissionDifficulty
    let startAt: String
    let endAt: String
    let progressValue: Int
    
    enum CodingKeys: String, CodingKey {
        case id, type, difficulty
        case targetValue = "target_value"
        case startAt = "start_at"
        case endAt = "end_at"
        case progressValue = "progress_value"
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
        switch type {
        case .sessions: return "\(progressValue)"
        default: return "\(progressValue)"
        }
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

struct DashboardResponse: Codable {
    let missions: [Mission]
    let totalPoints: Int
    let rank: String
    
    enum CodingKeys: String, CodingKey {
        case missions
        case totalPoints = "total_points"
        case rank
    }
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
    
    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case sets
    }
}

struct WorkoutPlan: Codable, Equatable {
    let title: String
    let estimatedMinutes: Int
    let estimatedCalories: Int
    let coachMessage: String
    let exercises: [WorkoutPlanExercise]
    
    enum CodingKeys: String, CodingKey {
        case title
        case estimatedMinutes = "estimated_minutes"
        case estimatedCalories = "estimated_calories"
        case coachMessage = "coach_message"
        case exercises
    }
}

struct SessionExercise: Codable, Equatable {
    let exerciseId: String
    let sets: [ExerciseSet]
    
    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case sets
    }
}

struct SessionSummary: Codable, Identifiable, Equatable {
    let id: String
    let date: String
    let source: SessionSource
    let durationMinutes: Int
    let calories: Int
    let totalExercises: Int
    
    enum CodingKeys: String, CodingKey {
        case id, date, source, calories
        case durationMinutes = "duration_minutes"
        case totalExercises = "total_exercises"
    }
}

struct SessionDetail: Codable, Identifiable, Equatable {
    let id: String
    let date: String
    let source: SessionSource
    let durationMinutes: Int
    let calories: Int
    let exercises: [SessionExercise]
    
    enum CodingKeys: String, CodingKey {
        case id, date, source, calories, exercises
        case durationMinutes = "duration_minutes"
    }
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
    
    enum CodingKeys: String, CodingKey {
        case condition, equipment
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
