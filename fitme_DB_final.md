# fitme Database Schema v1 (Final)

## users
```sql
users
- id (uuid, pk)
- email (string)
- display_name (string)

- total_points (int)
- rank (string)                     -- bronze / silver / gold / diamond

- preferred_workout_minutes (int)
- preferred_location (string)       -- gym / home / outdoor
- equipment_json (jsonb)

- created_at (timestamp)
- updated_at (timestamp)
mission
mission
- id (uuid, pk)
- user_id (uuid, fk -> users.id)

- type (string)                     -- calories | minutes | sessions
- target_value (int)

- difficulty (string)               -- easy | medium | hard

- start_at (date)
- end_at (date)                     -- start_at + 7 days

- created_at (timestamp)
exercises
exercises
- id (string, pk)                   -- bench_press, squat, etc
- name (string)

- muscle_group (string)
- equipment_type (string)

- description (text, nullable)
- image_url (string, nullable)
- animation_url (string, nullable)

- created_at (timestamp)
sessions
sessions
- id (uuid, pk)
- user_id (uuid, fk -> users.id)

- date (date)                       -- 운동한 날짜
- source (string)                   -- fitme | apple_health | other

- duration_minutes (int)            -- 실제 운동 시간
- calories (int)                    -- backend 계산 값

- exercises_json (jsonb)            -- 실제 수행한 운동/세트

- created_at (timestamp)
reports
reports
- id (uuid, pk)
- user_id (uuid, fk -> users.id)

- period_type (string)              -- week | month
- start_at (date)
- end_at (date)

- data_json (jsonb)
- ai_comment (text)

- created_at (timestamp)