import Foundation

enum FitMeWatchWorkoutStatus: String, Codable {
    case idle
    case generating
    case active
    case resting
    case paused
    case ended
    case error
}

enum FitMeWatchEventType: String, Codable {
    case start
    case completeSet = "complete_set"
    case pause
    case resume
    case skipSet = "skip_set"
    case changeExercise = "change_exercise"
    case end
    case skipRest = "skip_rest"
    case adjustRest = "adjust_rest"
    case adjustWeight = "adjust_weight"
    case adjustReps = "adjust_reps"
}

struct FitMeWorkoutStateSnapshot: Codable, Equatable {
    let sessionId: String
    let status: FitMeWatchWorkoutStatus
    let exerciseName: String
    let currentExerciseIndex: Int
    let totalExercises: Int
    let currentSetIndex: Int
    let totalSets: Int
    let currentWeight: Int?
    let currentReps: Int?
    let weightUnit: String?
    let restRemainingSeconds: Int
    let isBodyweight: Bool
    let updatedAt: Date

    init(
        sessionId: String,
        status: FitMeWatchWorkoutStatus,
        exerciseName: String,
        currentExerciseIndex: Int,
        totalExercises: Int,
        currentSetIndex: Int,
        totalSets: Int,
        currentWeight: Int? = nil,
        currentReps: Int? = nil,
        weightUnit: String? = nil,
        restRemainingSeconds: Int,
        isBodyweight: Bool = false,
        updatedAt: Date
    ) {
        self.sessionId = sessionId
        self.status = status
        self.exerciseName = exerciseName
        self.currentExerciseIndex = currentExerciseIndex
        self.totalExercises = totalExercises
        self.currentSetIndex = currentSetIndex
        self.totalSets = totalSets
        self.currentWeight = currentWeight
        self.currentReps = currentReps
        self.weightUnit = weightUnit
        self.restRemainingSeconds = restRemainingSeconds
        self.isBodyweight = isBodyweight
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        status = try container.decode(FitMeWatchWorkoutStatus.self, forKey: .status)
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        currentExerciseIndex = try container.decode(Int.self, forKey: .currentExerciseIndex)
        totalExercises = try container.decode(Int.self, forKey: .totalExercises)
        currentSetIndex = try container.decode(Int.self, forKey: .currentSetIndex)
        totalSets = try container.decode(Int.self, forKey: .totalSets)
        currentWeight = try container.decodeIfPresent(Int.self, forKey: .currentWeight)
        currentReps = try container.decodeIfPresent(Int.self, forKey: .currentReps)
        weightUnit = try container.decodeIfPresent(String.self, forKey: .weightUnit)
        restRemainingSeconds = try container.decode(Int.self, forKey: .restRemainingSeconds)
        isBodyweight = try container.decodeIfPresent(Bool.self, forKey: .isBodyweight) ?? false
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct FitMeWatchEvent: Codable, Equatable {
    let sessionId: String
    let type: FitMeWatchEventType
    let timestamp: Date
    let dedupeKey: String
    let payload: [String: String]?

    init(
        sessionId: String,
        type: FitMeWatchEventType,
        timestamp: Date = Date(),
        dedupeKey: String = UUID().uuidString,
        payload: [String: String]? = nil
    ) {
        self.sessionId = sessionId
        self.type = type
        self.timestamp = timestamp
        self.dedupeKey = dedupeKey
        self.payload = payload
    }
}

enum FitMeWatchWireKey {
    static let workoutState = "fitme.workoutState"
    static let eventBatch = "fitme.eventBatch"
    static let ack = "fitme.ack"
    static let workoutSummary = "fitme.workoutSummary"
}

enum FitMeWatchSaveStatus: String, Codable {
    case notSaved = "not_saved"
    case saving
    case saved
    case failed
}

struct FitMeWatchWorkoutSummary: Codable, Equatable {
    let sessionId: String
    let planTitle: String?
    let estimatedMinutes: Int?
    let estimatedCalories: Int?
    let totalExercises: Int
    let totalSets: Int
    let saveStatus: FitMeWatchSaveStatus
    let savedSessionRecordId: String?
    let saveErrorMessage: String?
    let updatedAt: Date
}

struct FitMeWatchEventBatch: Codable, Equatable {
    let events: [FitMeWatchEvent]
}

struct FitMeWatchAck: Codable, Equatable {
    let sessionId: String
    let dedupeKeys: [String]
}

enum FitMeWatchCodec {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
