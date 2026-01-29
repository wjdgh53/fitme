# fitme Apple Watch 앱 상세 개발 문서 (v1)

> 목적: **iPhone 보조가 아닌, 실제 운동 중 주 컨트롤러**로 사용 가능한 Watch 앱을 구현한다.
> 원칙: 입력 최소화 / 오프라인 우선 / 실수 방지 / 한 손 조작

---

## 0. Watch 앱 설계 원칙 (핵심)

- Watch는 **체크 장치**, Phone은 **편집 장치**
- 숫자 입력 ❌
- 한 화면 = 한 행동
- 항상 다음 행동이 명확해야 함
- 네트워크 상태에 의존하지 않음

---

## 1. Watch 앱 역할 정의

### Watch에서 할 수 있는 것
- 운동 시작
- 세트 완료 체크
- 휴식 타이머 확인
- 운동 일시정지 / 종료

### Watch에서 하지 않는 것
- 무게 / 횟수 직접 입력
- 루틴 탐색 / 수정
- 통계/히스토리 탐색

---

## 2. Watch 앱 화면 스택

### 2.1 Idle / Ready 화면

**상태**
- 운동 중 세션 없음

**구성**
- 큰 버튼: Start Workout

---

### 2.2 Active Workout (메인)

**상단**
- 현재 운동 이름
- 현재 세트 인덱스 (예: Set 2 / 4)

**중앙 (가장 중요)**
- **Complete Set 버튼** (최대 크기)

**하단**
- Pause 버튼
- Skip / Change 버튼 (secondary)

---

### 2.3 Rest 화면

**전환 조건**
- Complete Set 누른 직후 자동 전환

**구성**
- 큰 휴식 타이머
- Digital Crown으로 남은 시간 조절 가능
- Skip Rest 버튼

---

### 2.4 Pause 상태

**구성**
- Resume 버튼
- End Workout 버튼

---

### 2.5 End Confirmation

**구성**
- "운동을 끝낼까요?"
- Confirm / Cancel

---

## 3. 입력 방식 상세

### 3.1 버튼
- 모든 주요 버튼은 **원형 + 풀폭 터치 영역**

### 3.2 Digital Crown
- 휴식 시간 ± 조절
- 스크롤/리스트 ❌

### 3.3 햅틱
- 세트 완료 시
- 휴식 종료 시

---

## 4. 세션 이벤트 처리

### Watch에서 발생하는 이벤트
- start
- complete_set
- pause
- resume
- skip_set
- change_exercise
- end

모든 이벤트는:
- 로컬 큐에 append
- timestamp 포함
- 네트워크 무관

---

## 5. 오프라인 동작 규칙

- 네트워크 없어도 모든 기능 동작
- 이벤트는 Watch 로컬에 저장
- iPhone 연결 시 일괄 전송
- 중복 이벤트는 dedupe_key로 제거

---

## 6. Phone ↔ Watch 세션 이어받기 규칙

- 단일 sessionId 공유
- 어디서 시작했든 동일 세션
- 별도 "워치로 이동" 버튼 없음
- 마지막 이벤트 기준 상태 동기화

---

## 7. Apple Health 연동 (Watch 기준)

- 운동 종료 시
  - Watch → Phone
  - Phone → HealthKit write
- Watch 단독으로 Health write ❌
  (충돌/중복 방지)

---

## 8. 실패 / 엣지 케이스

### 배터리 종료
- 마지막 이벤트까지 보존
- 다음 실행 시 이어서 할지 1회 질문

### 강제 종료
- abandoned 처리
- 데이터 손실 없음

---

## 9. 개발 체크리스트

- [ ] Watch 로컬 이벤트 큐 구현
- [ ] Complete Set 버튼 햅틱
- [ ] Rest 타이머 정확성
- [ ] Phone 재연결 시 병합
- [ ] 배터리/백그라운드 테스트

---

## 10. 디자이너/개발자 공통 한 줄 요약

> Watch 앱은 "운동 중 방해하지 않는 버튼"이다.
> 보고, 누르고, 끝낸다.
