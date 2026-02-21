# Learnings

- ConnectivityStatus can read WCSession state without owning the delegate or activating the session.
- Workout pause on iOS is handled in WorkoutSessionView via handlePause/pauseOverlay; watch UI lacks a pause trigger despite WatchWorkoutController supporting onPause.
- Summary screen is driven by AppViewModel.screenStack = [.summary] via goToSummary, triggered from WorkoutSessionView (onComplete/endWorkoutEarly), RestView (onContinue), or AppRootView watch .end event.
- The workout set UI with FitCoach header, LB/REPS steppers, BPM/Time tiles, and Complete Set button is implemented in WatchMainView activeLayout.
- Adjusted watch active workout screen top margin from 2pt to 0.5pt in `WatchMainView.swift` (activeLayout).
- 2026-02-05: Added a quick workout start path that skips preset check and immediately generates a plan from stored defaults.
- 2026-02-05: WorkoutPreviewViewModel now mirrors AppViewModel errorMessage for preview alerts with a retry action.
