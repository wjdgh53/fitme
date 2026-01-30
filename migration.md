fitme iOS App – Frontend Contract

기술

Swift + SwiftUI

MVVM

async/await

API Service Interface 패턴

원칙

UI는 절대 user_id, calories 계산 안 함

UI는 MockService → APIService 교체 가능 구조

서버가 단일 진실(Source of Truth)

백엔드 책임

유저 식별: Bearer Token

calories 계산

미션 진행 계산

AI 호출

프론트 책임

화면 렌더링

유저 입력 수집

API 호출

상태 표시

2️⃣ 프론트엔드 API Service 구조 (필수)
protocol FitmeAPI {
    func getDashboard() async throws -> DashboardResponse
    func createMissions(request: CreateMissionRequest) async throws -> MissionsResponse
    func generateWorkoutPlan(request: WorkoutPlanRequest) async throws -> WorkoutPlan
    func createSession(request: CreateSessionRequest) async throws -> SessionSummary
    func getSessions(period: SessionPeriod) async throws -> [SessionSummary]
    func getSessionDetail(id: String) async throws -> SessionDetail
}

구현체
final class MockFitmeAPI: FitmeAPI { ... }
final class RealFitmeAPI: FitmeAPI { ... }


👉 ViewModel은 FitmeAPI만 의존

3️⃣ DTO 기준 (OpenAPI랑 1:1 매칭)
Workout Plan
struct WorkoutPlan {
    let title: String
    let estimatedMinutes: Int
    let estimatedCalories: Int
    let coachMessage: String
    let exercises: [PlannedExercise]
}

struct PlannedExercise {
    let exerciseId: String
    let sets: [ExerciseSet]
}

struct ExerciseSet {
    let weight: Double
    let reps: Int
}

Session Create (프론트 → 서버)
struct CreateSessionRequest {
    let source: SessionSource
    let durationMinutes: Int
    let exercises: [PerformedExercise]
}

struct PerformedExercise {
    let exerciseId: String
    let sets: [ExerciseSet]
}

Session Summary (POST / GET 공통)
struct SessionSummary {
    let id: String
    let date: String
    let source: SessionSource
    let durationMinutes: Int
    let calories: Int
    let totalExercises: Int
}

4️⃣ ViewModel 수정 가이드 (핵심)
❌ 하지 말 것

calories 계산

미션 진행 계산

exercise 필터링

AI 로직

⭕️ 할 것

버튼 → API 호출

로딩/에러 상태 관리

API 응답 그대로 바인딩