## 2026-02-04
- watchOS workout state updates: keep `updateApplicationContext` for background delivery, but use `WCSession.sendMessage` for terminal/latency-sensitive states when `isReachable`.
- Include `updatedAt` in snapshots and ignore stale states on the watch to prevent regressing from `.ended`.

## 2026-02-04
- Exercise progress can be sent via workout state snapshots to keep watch header in sync with phone state.

## 2026-02-04
- End-on-watch uses total exercise/set bounds to decide terminal completion and skips rest when sending `.end`.

## 2026-02-04
- Moved watch event processing into `AppViewModel` to enable unit tests for `.end` -> summary navigation.

## [Wed Feb  4 21:56:18 EST 2026] Watch Active Screen Padding Adjustment
- Reduced horizontal padding in `WatchContentPadding` to 12pt (was default ~16pt) to make content feel less inset.
- Reduced `headerTopInset` in `activeLayout` by 2pt (8->6 for compact, 10->8 for regular) to pull content up and ensure bottom CTA is visible.

## [Wed Feb  4 22:05:00 EST 2026] Watch Active Screen Top Padding Removal
- Removed `active` view top padding (was 2pt, now 0).
- Reduced `activeLayout` header top inset (compact: 6->0, regular: 8->2) and vertical content padding (compact: 1->0, regular: 2->1) to minimize top margin while preserving horizontal padding.

## 2026-02-04
- Tuned `activeLayout` `headerTopInset` regular to 0.5pt (compact stays 0) for a slight top margin without dropping the header.
