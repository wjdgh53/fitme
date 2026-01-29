📄 iOS 앱 구현 디렉션 문서 (Design 고정 + Mock 기반)
0. 목표

Stitch에서 완성한 디자인을 1px도 변경하지 않고

iPhone 앱을 Mock 데이터로 전 화면 실제처럼 동작하게 구현

추후 서버/AI/Health/Watch 연결을 고려한 구조만 확보

1. 절대 원칙 (가장 중요)
❌ 금지

디자인 재해석 / 추측 / 간소화

View 안에서 임시 값 직접 작성

화면마다 네비게이션 바 개별 구현

“일단 이렇게” 식의 UI 수정

⭕ 필수

View는 데이터만 렌더링

모든 데이터는 Mock Provider에서 공급

네비게이션 바는 항상 보이는 공통 컨테이너

2. 네비게이션 바 정책 (고정)
탭 구성

Home

Report

History

Profile

공통 규칙

모든 화면에서 네비게이션 바는 항상 표시

위치/높이/스타일 완전 동일

상태별 동작

일반 화면(Home/Report/History/Profile)

네비바 활성

운동 플로우 화면

Workout Preview

Workout Active

Rest

Summary

👉 네비바 보이지만 비활성

Summary(운동 종료) 진입 시

네비바 다시 활성

네비바는 “이동 수단”이 아니라 앱의 프레임

3. 화면 구조 (변경 금지)
운동 플로우

Home → Start Workout

Preset Check (컨디션/장소/시간)

Workout Preview (루틴 리스트)

Workout Active

Rest

Summary

Home 복귀

화면 전환, 순서, 레이아웃 절대 변경 금지

4. 데이터 전략 (Step A: Mock Only)
데이터 원칙

서버 ❌

로컬 저장 ❌

Health ❌

AI ❌

Mock 데이터는:

화면 단위 구조체

실제 API 응답처럼 설계

예:

struct WorkoutActiveMock {
  let exerciseName: String
  let currentSet: Int
  let totalSets: Int
  let weight: Int
  let reps: Int
  let lastSetSummary: String
  let workoutElapsedTime: String
}

5. View / ViewModel 책임 분리
View

상태 판단 ❌

계산 ❌

단순 렌더링만

ViewModel

Mock 데이터 소유

버튼 액션 시 값만 변경

실제처럼 상태 전이 흉내

6. 완성 기준 (Step A 종료 조건)

모든 화면 네비게이션 연결됨

운동 시작 → 종료까지 끊김 없이 흐름 완주 가능

버튼 누를 때 화면 값이 자연스럽게 변경됨

디자인 변경 0