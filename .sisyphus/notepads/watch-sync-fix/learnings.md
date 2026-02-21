## Watch Sync Fix - Race Condition in Workout State Generation

### Learnings
- WCSession activation and reachability can be delayed, causing the watch to miss the initial 'active' state if sent too early.
- Using a 'flush' mechanism in `activationDidCompleteWith` and `sessionReachabilityDidChange` ensures the latest state is eventually delivered.
- To avoid message spam, we should track the latest state sent via `transferUserInfo` and only re-queue if the state has actually changed.
- `updateApplicationContext` is eventually consistent, but `sendMessage` and `transferUserInfo` are better for immediate status transitions.

### Decisions
- Added `lastOutgoingState` to cache the latest workout state snapshot.
- Added `lastQueuedUserInfoState` to deduplicate `transferUserInfo` calls.
- Implemented `flushLatestState()` which simply re-triggers `sendWorkoutState` with the cached state.
- Hooked into `WCSessionDelegate` reachability and activation callbacks to trigger the flush.
