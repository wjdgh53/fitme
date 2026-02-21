## 2026-02-05
- Goal: watch start triggers iPhone AI plan generation and iPhone becomes canonical state source; watch renders via snapshots and sends control events.
- 2026-02-05 02:24: Canonical workout runtime lives in `AppViewModel` as `WorkoutRuntime`; snapshots are sent on runtime start, every state mutation (set completion, weight/reps/rest/phase/pause changes), timer rest countdown ticks, and end.

## [2026-02-05] Immediate Watch Delivery Strategy
- Implemented immediate state delivery for new workout sessions using `WCSession.sendMessage`.
- Added `lastImmediateSentSessionId` to track session transitions and avoid redundant `sendMessage` calls (which can be expensive or fail if too frequent).
- Maintained `updateApplicationContext` for background/efficient state updates (e.g., during rest countdown).
- This ensures the watch UI updates promptly when a workout starts on the iPhone, preventing it from showing hardcoded/placeholder data.
