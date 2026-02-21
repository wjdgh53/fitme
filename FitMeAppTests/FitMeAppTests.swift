import XCTest
@testable import FitMeApp

final class FitMeAppTests: XCTestCase {
    func testMissionProgressAndCompletion() throws {
        let json = """
        {"id":"m1","type":"minutes","target_value":100,"difficulty":"easy","start_at":"2026-02-01","end_at":"2026-02-07","progress_value":50,"status":"active"}
        """
        let mission = try JSONDecoder().decode(Mission.self, from: Data(json.utf8))
        XCTAssertEqual(mission.progress, 0.5, accuracy: 0.001)
        XCTAssertFalse(mission.isComplete)
    }

    func testMissionCompletionCapsProgress() throws {
        let json = """
        {"id":"m2","type":"calories","target_value":300,"difficulty":"medium","start_at":"2026-02-01","end_at":"2026-02-07","progress_value":450,"status":"active"}
        """
        let mission = try JSONDecoder().decode(Mission.self, from: Data(json.utf8))
        XCTAssertEqual(mission.progress, 1.0, accuracy: 0.001)
        XCTAssertTrue(mission.isComplete)
    }

    @MainActor
    func testGenerateWorkoutPlanLiveAPI() async throws {
        let viewModel = AppViewModel()
        viewModel.workoutCondition = "normal"
        viewModel.workoutTargetMinutes = 30
        viewModel.workoutEquipment = ["dumbbell"]

        await viewModel.generateWorkoutPlan()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isGeneratingPlan)
        XCTAssertNotNil(viewModel.currentWorkoutPlan)
        XCTAssertEqual(viewModel.currentWorkoutPlan?.estimatedMinutes, 30)
        XCTAssertFalse(viewModel.currentWorkoutPlan?.exercises.isEmpty ?? true)
    }
}
