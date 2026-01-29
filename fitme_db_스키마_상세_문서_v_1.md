# fitme DB 스키마 상세 문서 (v1)

> 목표: iOS + Watch + Apple Health 연동을 포함한 MVP를 **지어내지 않고** 구현할 수 있는 최소/충분한 데이터 모델.
> 원칙: **세션은 이벤트 로그 기반(SessionEvent)**, 화면/리포트는 스냅샷 기반(Session/Report).

---

## 0. 공통 규칙

### 0.1 ID / 시간
- 모든 엔티티는 `id`(UUID) 사용
- 시간은 `created_at`, `updated_at`(ISO8601, UTC 권장)
- 주간 기준일: **일요일 시작 ~ 토요일 종료**

### 0.2 Soft delete
- 사용자 삭제/탈퇴가 아니라면 soft delete 우선
  - `deleted_at` nullable

### 0.3 인덱스 기본
- 사용자 범위 조회가 대부분이므로 `(user_id, created_at)` 또는 `(user_id, start_at)` 복합 인덱스 필수

---

## 1. User

### 1.1 users
- `id` (PK)
- `auth_provider` (enum: apple, google)
- `auth_subject` (string, provider user id)
- `email` (nullable)
- `display_name` (nullable)
- `avatar_url` (nullable)
- `created_at`
- `updated_at`
- `deleted_at` (nullable)

**Indexes**
- unique(`auth_provider`, `auth_subject`)

---

## 2. Profile (온보딩/설정)

### 2.1 profiles
- `user_id` (PK/FK -> users.id)
- `age` (int, nullable)
- `height_cm` (int, nullable)
- `weight_kg` (float, nullable)
- `experience_level` (enum: beginner, intermediate, advanced)
- `preferred_location` (enum: home, gym, mixed)
- `equipment_json` (jsonb)
- `goals_pref_json` (jsonb)
- `timezone` (string, default America/New_York)
- `units` (jsonb: kg/lb, cm/in)
- `created_at`
- `updated_at`

---

## 3. Health 연결 상태

### 3.1 health_connections
- `user_id` (PK/FK)
- `status` (enum: not_connected, connected, denied)
- `last_sync_at` (datetime, nullable)
- `read_permissions_json` (jsonb)
- `write_permissions_json` (jsonb)
- `created_at`
- `updated_at`

> 실제 권한은 OS가 소유. DB에는 **앱 UX용 상태/마지막 동기화 시점**만 저장.

---

## 4. Exercise 카탈로그 (선택)

MVP에서 운동 이름/부위 매핑을 위해 최소 테이블을 둔다.

### 4.1 exercises
- `id` (PK)
- `name_ko` (string)
- `name_en` (string, nullable)
- `muscle_group` (enum: chest, back, legs, shoulders, arms, core, full_body, cardio)
- `equipment_type` (enum: machine, freeweight, bodyweight, cable, cardio, other)
- `default_rest_sec` (int, nullable)
- `default_rep_range_json` (jsonb, nullable)  
  - 예: {"min":8,"max":12}
- `created_at`
- `updated_at`

**Indexes**
- index(`muscle_group`)

> 필요시 2차에 세분화.

---

## 5. Plan (AI 플랜 스냅샷)

### 5.1 plans
- `id` (PK)
- `user_id` (FK)
- `week_start_date` (date, 일요일)
- `status` (enum: active, archived)
- `plan_payload_json` (jsonb)
  - 포함 권장: workouts(일자별), exercise ids, set targets, suggested weight/reps
- `ai_model` (string)
- `ai_version` (string)
- `prompt_hash` (string)
- `created_at`
- `updated_at`

**Indexes**
- unique(`user_id`, `week_start_date`)

---

## 6. Session (운동 1회)

### 6.1 sessions
- `id` (PK)
- `user_id` (FK)
- `plan_id` (FK -> plans.id, nullable)

#### 출처/연동
- `source` (enum: fitme_phone, fitme_watch, apple_health_external)
- `external_source_bundle_id` (string, nullable)  
  - 외부 운동의 source 앱 식별자(가능한 경우)
- `external_workout_uuid` (string, nullable)  
  - HealthKit workout UUID 등

#### 시간/상태
- `start_at` (datetime)
- `end_at` (datetime, nullable)
- `status` (enum: in_progress, completed, ended_early, abandoned)

#### 메타
- `location` (enum: home, gym, unknown)
- `energy_kcal` (float, nullable)
- `duration_sec` (int, nullable)

#### 스냅샷
- `summary_payload_json` (jsonb, nullable)
  - 화면에 보여줄 운동 요약(운동 리스트/세트 결과/총합 등)
- `ai_comment` (text, nullable)

#### 동기화
- `last_event_ts` (datetime, nullable)
- `created_at`
- `updated_at`

**Indexes**
- index(`user_id`, `start_at` DESC)
- index(`user_id`, `status`)
- unique(`user_id`, `external_workout_uuid`) where external_workout_uuid is not null

> 외부 운동은 `summary_payload_json`에 “읽기 전용 요약”만 보관.

---

## 7. SessionEvent (폰↔워치 동기화 핵심)

### 7.1 session_events
- `id` (PK)
- `session_id` (FK)
- `user_id` (FK)
- `ts` (datetime)
- `type` (enum)
  - start
  - pause
  - resume
  - rest_start
  - rest_end
  - complete_set
  - skip_set
  - change_exercise
  - end

- `device` (enum: phone, watch)
- `dedupe_key` (string)  
  - 예: `${device}:${ts}:${type}:${seq}`
- `payload_json` (jsonb)

**Indexes**
- index(`session_id`, `ts` ASC)
- unique(`session_id`, `dedupe_key`)

#### payload 규격 (권장 최소)
- `complete_set`:
  - `exercise_id`
  - `set_index`
  - `reps` (int, nullable)
  - `weight_kg` (float, nullable)
  - `auto_filled` (bool)

- `skip_set`:
  - `exercise_id`
  - `set_index`

- `change_exercise`:
  - `from_exercise_id`
  - `to_exercise_id`
  - `muscle_group`

- `rest_start/rest_end`:
  - `rest_sec`

> 워치는 숫자 입력을 하지 않으므로 reps/weight는 auto_filled 또는 nullable로 처리 가능.

---

## 8. Goal (위클리 미션)

### 8.1 goal_weeks
- `id` (PK)
- `user_id` (FK)
- `week_start_date` (date, 일요일)
- `week_end_date` (date, 토요일)

#### 목표
- `target_kcal` (float)
- `target_minutes` (int)
- `target_sessions` (int)

#### 진행
- `progress_kcal` (float)
- `progress_minutes` (int)
- `progress_sessions` (int)

- `status` (enum: active, completed, ended)
- `ai_recommendation_json` (jsonb, nullable)
- `created_at`
- `updated_at`

**Indexes**
- unique(`user_id`, `week_start_date`)

> 목표는 **고정**이며, 진행은 세션/헬스 기록 집계로 자동 반영.

---

## 9. Points Ledger (점수 원장)

### 9.1 points_ledger
- `id` (PK)
- `user_id` (FK)
- `ts` (datetime)
- `type` (enum: session_complete, goal_partial, goal_bonus)
- `amount` (int)

- `ref_type` (enum: session, goal_week, report)
- `ref_id` (UUID)

- `created_at`

**Indexes**
- index(`user_id`, `ts` DESC)
- index(`user_id`, `type`)

> 포인트는 **세션 종료 시 즉시 지급**, 목표 달성 시 즉시 보너스.

---

## 10. Rank (등급)

### 10.1 user_ranks (캐시)
- `user_id` (PK/FK)
- `total_points` (int)
- `tier` (enum: bronze, silver, gold, black, diamond)
- `tier_updated_at` (datetime)

> 등급은 `total_points` 구간으로 계산. 자주 쓰이므로 캐시 테이블 권장.

---

## 11. Report (주/월/연 공통)

### 11.1 reports
- `id` (PK)
- `user_id` (FK)

- `period_type` (enum: week, month, year)
- `period_start` (date)
- `period_end` (date)

- `metrics_json` (jsonb)
  - 예: {"sessions":3,"minutes":120,"kcal":850,"top_muscle":"legs"}

- `ai_comment` (text)
- `created_at`

**Indexes**
- unique(`user_id`, `period_type`, `period_start`)

> 운동 없는 주는 report 생성 안 함.

---

## 12. Apple Health Write 매핑 저장(선택)

### 12.1 health_writes
- `id` (PK)
- `user_id` (FK)
- `session_id` (FK)
- `workout_activity_type` (string)
- `workout_uuid` (string)
- `written_at` (datetime)

**Indexes**
- unique(`session_id`)

> 디버깅/중복 방지에 도움. (MVP에서는 선택)

---

## 13. 주요 조회 패턴

1) 홈 대시보드
- user_ranks(점수/등급)
- goal_weeks(이번 주 목표/진행)

2) 히스토리
- sessions where user_id = ? order by start_at desc limit/offset(또는 cursor)

3) 세션 상세
- session + session_events(ts asc)

4) 리포트
- reports by period_type + period_start desc

---

## 14. 동기화/중복 방지 규칙 (DB 관점)

- 모든 이벤트는 `session_events`에 append-only
- 중복 이벤트는 `dedupe_key` unique로 차단
- 외부 운동은 `external_workout_uuid` unique로 중복 차단
- fitme가 Health에 쓴 기록은 read 시 source 식별자로 제외

---

## 15. 캘린더 기간 계산 규칙

- 주간(week): 일요일 00:00 ~ 토요일 23:59:59
- 월간(month): 해당 월 1일 ~ 말일
- 연간(year): 1월 1일 ~ 12월 31일

---

## 16. 남은 결정 포인트(나중)

- MET 기반 칼로리 fallback 공식/테이블 (워치/헬스 값 없을 때만)
- reports/goal 집계 시 외부 운동의 type별 분류(선택)
- 세션 5분 미만 Health write 제외 기준(현재 제안값)

