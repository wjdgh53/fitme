# fitme AI 프롬프트 & JSON 응답 스펙 문서 (v1)

> 목적: AI 응답을 **100% 구조화(JSON)** 해서 바로 DB 저장 및 자동 플랜/리뷰/리포트 생성이 가능하도록 한다.
> 원칙: **자연어 출력 금지**, JSON Schema 강제, 재현 가능성 확보.

---

## 0. 공통 규칙

### 0.1 출력 형식
- AI의 **최종 응답은 반드시 JSON 하나만 반환**
- 자연어 설명, 마크다운, 코드블럭 ❌
- 모든 필드는 명시적으로 반환 (nullable 허용)

### 0.2 안전/톤 규칙 (콘텐츠 레벨)
- 비난/죄책감 유발 표현 ❌
- 실패 지적 ❌
- 긍정/격려/중립 톤만 허용

---

## 1. AI 운동 플랜 생성

### 1.1 사용 시점
- 온보딩 완료 직후
- 주간 플랜 갱신 시 (일요일)
- 이전 플랜 소진 후

---

### 1.2 입력(JSON)
```json
{
  "user_profile": {
    "age": 32,
    "height_cm": 175,
    "weight_kg": 78,
    "experience_level": "beginner",
    "preferred_location": "gym",
    "equipment": ["barbell", "machine"],
    "injuries": []
  },
  "recent_activity": {
    "last_week_sessions": 3,
    "last_week_minutes": 120,
    "last_week_kcal": 850
  },
  "constraints": {
    "max_session_minutes": 60,
    "days_per_week": 3
  }
}
```

---

### 1.3 출력(JSON) — **PLAN_PAYLOAD**
```json
{
  "plan_type": "weekly",
  "week_start": "2026-02-01",
  "days": [
    {
      "day_index": 1,
      "focus": "upper_body",
      "estimated_minutes": 45,
      "exercises": [
        {
          "exercise_id": "bench_press",
          "sets": 3,
          "target_reps": 10,
          "suggested_weight_kg": 40,
          "rest_sec": 90
        }
      ]
    }
  ],
  "notes": "Beginner-friendly volume"
}
```

---

### 1.4 강제 규칙
- `exercise_id`는 DB `exercises.id`에 존재해야 함
- `suggested_weight_kg`는 추정값이며 nullable 허용
- 하루 운동 시간은 `max_session_minutes` 초과 ❌

---

## 2. 세션 종료 AI 코멘트 생성

### 2.1 사용 시점
- 세션 종료 직후

---

### 2.2 입력(JSON)
```json
{
  "session_summary": {
    "total_sets": 12,
    "completed_sets": 10,
    "duration_minutes": 42,
    "energy_kcal": 280,
    "ended_early": false
  },
  "user_context": {
    "experience_level": "beginner",
    "streak_days": 3
  }
}
```

---

### 2.3 출력(JSON)
```json
{
  "comment": "오늘은 꾸준한 페이스로 잘 마무리했어요. 이 흐름이면 다음 운동도 부담 없이 이어갈 수 있어요.",
  "tone": "encouraging",
  "line_count": 2
}
```

---

### 2.4 강제 규칙
- `comment`는 **1~3문장**
- 실패/조기종료여도 긍정 유지

---

## 3. 리포트 AI 코멘트 생성

### 3.1 사용 시점
- 주/월/연 리포트 생성 시

---

### 3.2 입력(JSON)
```json
{
  "period": {
    "type": "week",
    "start": "2026-01-25",
    "end": "2026-01-31"
  },
  "metrics": {
    "sessions": 3,
    "minutes": 120,
    "kcal": 850,
    "goal_completion_rate": 0.8
  },
  "previous_period": {
    "sessions": 2,
    "minutes": 90
  }
}
```

---

### 3.3 출력(JSON)
```json
{
  "summary": "이번 주는 지난주보다 운동 빈도가 늘었어요.",
  "insight": "짧은 운동을 자주 가져간 점이 특히 좋아요.",
  "suggestion": "다음 주도 비슷한 리듬을 유지해보세요."
}
```

---

### 3.4 강제 규칙
- 각 필드는 최대 1문장
- 총 길이 3문장 초과 ❌

---

## 4. 오류 처리 규칙

### 4.1 생성 불가 시
```json
{
  "error": {
    "code": "PLAN_GENERATION_FAILED",
    "reason": "INSUFFICIENT_INPUT_DATA"
  }
}
```

- 이 경우 서버는 재시도 또는 fallback 플랜 사용

---

## 5. 버전 관리

- 모든 AI 요청은 다음 메타를 함께 저장
  - `ai_model`
  - `ai_version`
  - `prompt_hash`

---

## 6. 핵심 원칙 요약

> AI는 생각한다.
> 앱은 저장한다.
> 유저는 누르기만 한다.

