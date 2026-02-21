## Architectural Decisions
- Moved the deduplication logic (which updates UserDefaults) before the `sendAck` call.
- Decided to send ACK for the entire batch even if it contains duplicates, following the specific instruction to use `batch.events[0].sessionId` and all `dedupeKey`s.
