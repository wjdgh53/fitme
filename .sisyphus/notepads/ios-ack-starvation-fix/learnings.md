## Patterns and Conventions
- Always persist or mark data as received before acknowledging it to the sender to prevent data loss on crash.
- Guard against empty collections before accessing indexed elements like `events[0]`.
