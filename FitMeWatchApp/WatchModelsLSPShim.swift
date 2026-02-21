#if !canImport(WatchConnectivity)
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
    let updatedAt: Date
}

struct FitMeWatchEvent: Codable, Equatable {
    let sessionId: String
    let type: FitMeWatchEventType
    let timestamp: Date
    let dedupeKey: String
    let payload: [String: String]?
}

struct FitMeWatchEventBatch: Codable, Equatable {
    let events: [FitMeWatchEvent]
}

struct FitMeWatchAck: Codable, Equatable {
    let sessionId: String
    let dedupeKeys: [String]
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
#endif
