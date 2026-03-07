## Decisions
- Chose to use @MainActor via Task in errorHandler closures to safely update dedupe state properties.
- Implemented deduplication for all three message types to maintain consistency and prevent spam.

