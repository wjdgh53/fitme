## Watch Workout Sync Fallback Implementation
- Updated sendMessage calls to handle errors by falling back to transferUserInfo.
- This ensures critical workout transitions (state, ack, summary) are delivered even if immediate messaging fails.
- Added light deduplication for ack and summary using private properties to avoid userInfo spam during fallback.
- Verified that all types involved (FitMeWorkoutStateSnapshot, FitMeWatchAck, FitMeWatchWorkoutSummary) are Equatable for deduplication.

