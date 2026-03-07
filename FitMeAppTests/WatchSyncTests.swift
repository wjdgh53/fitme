import XCTest
#if canImport(XCTest)
import XCTest

@testable import FitMeApp

final class WatchSyncTests: XCTestCase {
    @MainActor
    func testProcessWatchEventsEndNavigatesToSummary() {
        let viewModel = AppViewModel()
        let event = FitMeWatchEvent(
            sessionId: "ses_end_001",
            type: .end,
            timestamp: Date(timeIntervalSince1970: 1_700_000_100),
            dedupeKey: "end_1"
        )

        viewModel.processWatchEvents([event])

        XCTAssertEqual(viewModel.currentScreen, .summary)
        XCTAssertEqual(viewModel.activeWorkoutSessionId, event.sessionId)
    }

    func testWorkoutStateSnapshotCodableRoundTrip() throws {
        let snapshot = FitMeWorkoutStateSnapshot(
            sessionId: "ses_123",
            status: .resting,
            exerciseName: "Bench Press",
            currentExerciseIndex: 2,
            totalExercises: 6,
            currentSetIndex: 2,
            totalSets: 4,
            restRemainingSeconds: 45,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try FitMeWatchCodec.encoder().encode(snapshot)
        let decoded = try FitMeWatchCodec.decoder().decode(FitMeWorkoutStateSnapshot.self, from: data)
        XCTAssertEqual(decoded, snapshot)
    }

    func testEventBatchCodableRoundTrip() throws {
        let events = [
            FitMeWatchEvent(sessionId: "ses_123", type: .start, timestamp: Date(timeIntervalSince1970: 1), dedupeKey: "k1"),
            FitMeWatchEvent(sessionId: "ses_123", type: .completeSet, timestamp: Date(timeIntervalSince1970: 2), dedupeKey: "k2"),
            FitMeWatchEvent(sessionId: "ses_123", type: .adjustRest, timestamp: Date(timeIntervalSince1970: 3), dedupeKey: "k3", payload: ["seconds": "90"])
        ]

        let batch = FitMeWatchEventBatch(events: events)
        let data = try FitMeWatchCodec.encoder().encode(batch)
        let decoded = try FitMeWatchCodec.decoder().decode(FitMeWatchEventBatch.self, from: data)
        XCTAssertEqual(decoded, batch)
    }
}

#endif
