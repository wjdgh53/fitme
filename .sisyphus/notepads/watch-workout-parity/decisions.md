## 2026-02-05
- Move workout runtime state into an `ObservableObject` owned by `AppViewModel` so watch events can mutate state even when the workout view isn't mounted.
