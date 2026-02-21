## 2026-02-04
- Swift LSP diagnostics can be noisy/missing types for watch targets even when `xcodebuild` succeeds; prefer build output as source of truth.

## 2026-02-04
- `lsp_diagnostics` still reports unresolved watch model types in `FitMeWatchApp/WatchWorkoutController.swift` despite successful watch build.

## 2026-02-04
- `lsp_diagnostics` reports missing project types (e.g., `AppFonts`, `WatchContentPadding`) in UI files even though builds/tests succeed.
