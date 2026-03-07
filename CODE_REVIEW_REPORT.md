# FitMe 코드베이스 종합 리뷰 리포트

> 작성일: 2026-02-26
> 리뷰 방법: 5개 병렬 에이전트 팀 (아키텍처 / 서비스 / UI / Watch / 디자인)

---

## 종합 점수

| 도메인 | 점수 | 팀원 |
|--------|------|------|
| 아키텍처 & AppState | 6.5 / 10 | arch-reviewer |
| Services & API | 7.5 / 10 | services-reviewer |
| UI / Views | 5.2 / 10 | views-reviewer |
| Apple Watch App | 5.0 / 10 | watch-reviewer |
| 디자인 시스템 | 5.5 / 10 | design-reviewer |
| **전체 평균** | **5.9 / 10** | |

---

## Critical 이슈 (즉시 수정 필요)

### [C-1] HealthKit 완전 미구현 — `WatchWorkoutController.swift`
BPM이 항상 `"—"` 하드코딩. `HKWorkoutSession` / `HKLiveWorkoutBuilder` 부재.
Extended Runtime Session 없어 화면이 꺼지면 타이머 멈춤.
→ App Store 심사 거절 가능, 칼로리 추정 불가

### [C-2] GoalEditView — 저장 버튼이 실제 저장 안 함 — `GoalEditView.swift`
"Save Goal" 버튼이 `viewModel.onBack()`만 호출하고 저장 로직 없음.
→ 사용자가 입력한 목표가 버려짐

### [C-3] ExerciseDetailView — 시작 버튼 action 빈 클로저 — `ExerciseDetailView.swift`
"Start Workout!" 버튼의 action이 `{}`.
→ 핵심 기능 동작 불가

### [C-4] 강제 언래핑 3곳 — 크래시 위험
- `AppViewModel.swift:57` — `FileManager.urls.first!`
- `FitMeApp.swift:306` — `user.displayName!` (옵셔널 체이닝 후 강제 언래핑)
- `ViewModels.swift:453,524` — `Calendar.date(...)!`

### [C-5] AppRootView — 화면 전환마다 ViewModel 재생성 — `AppRootView.swift`
`switch` 분기에서 매 전환 시 `HomeDashboardViewModel(...)` 등 새 인스턴스 생성.
→ 진행 중 데이터 손실, 불필요한 API 재호출

### [C-6] 다크 모드 완전 미지원 — `DesignTokens.swift`
모든 색상이 정적 hex 하드코딩. 다크 모드에서 UI 완전히 깨짐.

### [C-7] 401 재시도 시 토큰 갱신 보장 없음 — `APIClient.swift:248`
만료 토큰으로 재시도될 수 있음. `forceRefresh` 파라미터 없음.

### [C-8] AppleHealthView / AppSettingsView — Toggle이 실제 권한/설정과 미연동
- HealthKit Toggle이 로컬 `@State`만 변경
- 알림 설정 Toggle이 재시작 시 초기화 (저장 없음)

### [C-9] WatchConnectivity 활성화 에러 무시 — `WatchWorkoutSync.swift:244`
`session(_:activationDidCompleteWith:error:)` 에서 에러를 완전히 무시.

---

## High 이슈 (가능한 빨리 수정)

### [H-1] AppViewModel God Object — `AppViewModel.swift` (1026줄)
네비게이션 + API + Watch 연동 + 파일 I/O + 포인트 계산을 단일 클래스에 혼재.
제안 분리: `NavigationCoordinator`, `MissionRepository`, `SessionRepository`, `UserProfileStore`

### [H-2] LibraryView — searchBar가 `Text`라 검색 불가 — `LibraryView.swift`
`TextField`가 아닌 장식용 `Text`. 검색 기능 동작 불가.

### [H-3] WorkoutSessionView — 이전/다음 버튼이 `Button`이 아닌 장식용 Circle
버튼처럼 생겼지만 탭이 불가능.

### [H-4] URL 쿼리 파라미터 미인코딩 — `APIClient.swift:170,196`
`"?period=\(period)"` 문자열 직접 삽입 → 공백/특수문자 시 URL 깨짐.
경로 주입 가능: `/sessions/\(id)` 미인코딩.

### [H-5] Dynamic Type 미지원 — `DesignTokens.swift:47`
모든 폰트 크기 고정 `CGFloat`. `relativeTo:` 파라미터 없음.

### [H-6] External Image URL 하드코딩 — `WatchMainView.swift:16`, `MockDataProvider.swift`
Google aida-public CDN URL이 Watch 화면에 직접 사용. URL 만료 시 영구 깨짐.

### [H-7] LoopingVideoView 코드 중복 — HomeDashboard + WorkoutSession
동일 컴포넌트가 두 파일에 복붙. 공통 컴포넌트로 추출 필요.

### [H-8] ProcessedDedupeKeyStore O(n) 선형 탐색 — `WatchWorkoutSync.swift:219`
세션당 최대 2000개 키를 배열로 관리, 매 이벤트마다 `UserDefaults` 읽기+선형 탐색.

### [H-9] AvatarImageView — AsyncImage 실패 케이스 미처리 — `AvatarImageView.swift`
`.failure` 케이스 없어 로드 실패 시 로딩 스피너 무한 표시.

### [H-10] AppColors / AppTheme 중복 정의 — `DesignTokens.swift`
`AppColors.cream == AppTheme.appBackground` 등 동일 값이 두 곳에 정의.

---

## Medium 이슈 (중기 개선)

- **Mission 낙관적 업데이트 후 API 실패 시 불일치** (`AppViewModel.swift:568`)
- **SummaryView에 print 디버그 로그 4개** production 코드에 잔존
- **RestView Timer가 뷰 dismiss 후에도 실행** (리소스 누수)
- **DateFormatter/NumberFormatter를 body ForEach에서 매번 생성** (성능)
- **미션 생성 후 `loadMissions()` 이중 API 호출** (`AppViewModel.swift:625`)
- **APIClient 싱글톤 직접 사용** — DI 없어 단위 테스트 불가
- **FadeLiftInModifier에서 DispatchQueue.main.asyncAfter** — Task로 교체 권장
- **AppTabBar 탭 선택 애니메이션 없음** — 뚝뚝 끊기는 UX
- **WorkoutPreviewView1/2가 동일한 ViewModel 인스턴스를 별도 생성** (`AppRootView.swift:35`)
- **WatchEventQueueStore actor isolation 없음** — 향후 백그라운드 flush 시 race condition

---

## Low 이슈 (리팩터링 기회)

- `AppViewModel.swift:584` — `parseDate` 미사용 함수
- `ViewModels.swift:451,522` — 주간 날짜 계산 중복 (2 ViewModel)
- `AppViewModel.swift:793` — 이모지 포함 print 디버그 로그 (`📥`, `🏁`)
- `WatchMainView.swift:382` — `weightText` 데드 코드 (`weightValueText`가 대신 사용)
- `WatchMainView.swift:348` — `metricValue` 함수 데드 코드
- `WatchMainView.swift:1,3` — `import SwiftUI` 중복
- `WatchWorkoutController.swift:204` — 운동 종료 시 `.failure` 햅틱 (`.stop` 권장)
- `HistoryListView.swift` — 미사용 computed property 2개
- `MockDataProvider.swift` — 한국어/영어 혼재, 이모지 포함

---

## 우선순위 수정 로드맵

### Sprint 1 (이번 주 — 배포 블로커)
1. ✅ `ExerciseDetailView` 시작 버튼 action 구현
2. ✅ `GoalEditView` 저장 로직 연결
3. ✅ 강제 언래핑 3곳 제거
4. ✅ `AppleHealthView` / `AppSettingsView` Toggle HealthKit/알림 실제 연동
5. ✅ `AppRootView` ViewModel 생명주기 수정 (@StateObject 또는 NavigationStack)

### Sprint 2 (다음 주 — 핵심 기능)
6. ✅ HealthKit 통합 (`HKWorkoutSession`, `HKLiveWorkoutBuilder`)
7. ✅ Extended Runtime Session 추가 (watchOS 백그라운드)
8. ✅ `LibraryView` searchBar → `TextField` 교체
9. ✅ `WorkoutSessionView` 이전/다음 버튼 `Button`으로 교체
10. ✅ URL 인코딩 수정 (`URLComponents` 사용)

### Sprint 3 (이후 — 품질 개선)
11. `AppViewModel` 분리 (God Object 해소)
12. 다크 모드 대응 (Asset Catalog Color Set)
13. Dynamic Type 지원 (`relativeTo:` 파라미터)
14. APIClient DI 도입 (테스트 가능성)
15. 외부 URL 이미지 → 번들 에셋으로 교체

---

## 잘 된 점

- `actor APIClient` — thread-safe API 레이어
- WatchSync 3단계 폴백 전략 (`updateApplicationContext` → `sendMessage` → `transferUserInfo`)
- `@MainActor` 일관 사용
- `WorkoutRuntime` 분리 (좋은 패턴)
- `FitMeWatchCodec` 캡슐화
- `reduceMotion` 고려한 애니메이션 설계
- `WKExtendedRuntimeSession` 제외하고 WatchConnectivity 양방향 채널 설계는 탄탄함
