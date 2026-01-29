# fitme 기술 스택 결정 문서 (v1)

> 결론부터: **Swift / SwiftUI 네이티브가 정답**
> Apple Health, Apple Watch, 백그라운드, 안정성까지 고려하면 다른 선택지는 리스크가 큼.

---

## 1. 최종 결론 요약

- **iOS 앱**: Swift + SwiftUI
- **Apple Watch 앱**: Swift + SwiftUI (WatchKit)
- **Health 연동**: HealthKit (네이티브)
- **폰–워치 통신**: WatchConnectivity

👉 이유: *헬스/워치 연동은 네이티브가 아니면 항상 문제 생김*

---

## 2. 왜 Swift 네이티브가 필수인가

### 2.1 Apple Health / Activity 링
- HealthKit은 **네이티브 API 우선 설계**
- 쓰기(write) 안정성, source 구분, 백그라운드 권한
- 크로스플랫폼(React Native, Flutter)은
  - write 누락
  - 백그라운드 실패
  - 워치 연동 불안정 사례 많음

➡️ *운동 앱에서는 치명적*

---

### 2.2 Apple Watch 연동

Watch 앱은:
- 독립 프로세스
- 배터리/메모리 제약 심함
- 오프라인 이벤트 큐 필요

Swift + WatchKit에서는:
- WatchConnectivity로 세션 공유
- 로컬 저장(CoreData/파일) 안정적
- 햅틱, Digital Crown 제어 완전 지원

➡️ JS 브릿지 기반은 UX 붕괴 위험

---

## 3. 권장 클라이언트 기술 스택

### 3.1 iOS
- Language: **Swift**
- UI: **SwiftUI**
- Architecture: MVVM (간단하게)
- State: ObservableObject / @State

### 3.2 Apple Watch
- Language: **Swift**
- UI: **SwiftUI for Watch**
- Storage: 로컬 파일 or CoreData (이벤트 큐)
- Communication: WatchConnectivity

---

## 4. 서버 & 백엔드 (가볍게)

> 서버는 "기록 저장 + AI 중계" 역할만

- API: REST (JSON)
- Auth: Apple / Google OAuth
- DB: PostgreSQL
- Queue/Job:
  - 리포트 생성
  - AI 호출

(이 부분은 언어 자유도 높음)

---

## 5. 피해야 할 선택지 (명확히)

- ❌ React Native + HealthKit wrapper
- ❌ Flutter + Watch 연동
- ❌ Watch 앱을 iOS 앱에 종속

이유:
- 운동 중 끊김
- Health write 누락
- 워치 독립 동작 불가

---

## 6. 현실적인 개발 전략

### MVP 단계
- iOS + Watch 모두 SwiftUI
- 기능 최소, 안정성 최우선

### 이후 확장
- Android는 **별도 네이티브** (Kotlin)
- 공통 로직은 서버에서 해결

---

## 7. 개발자 전달용 한 줄 결론

> fitme는 운동 앱이다.
> 운동 앱은 **네이티브 아니면 안 된다**.
> Swift는 선택이 아니라 전제다.
