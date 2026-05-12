---
name: async-logger-log
group: api
category: async
update-time: 20260512
description: Enqueue a record into the async logger with an explicit level, message, optional fields, and optional target override.
key-word:
    - async
    - logger
    - log
    - public
---

## Async-logger-log

Enqueue a record into the async logger with an explicit level and message. This is the core write API behind all async level-specific convenience methods.

### Interface

```moonbit
pub async fn[S] AsyncLogger::log(
  self : AsyncLogger[S],
  level : @bitlogger.Level,
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
  target? : String = "",
) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should receive the record.
- `level : Level` - Severity level for the record.
- `message : String` - Log message text.
- `fields : Array[Field]` - Optional structured fields added to the record.
- `target : String` - Optional per-call target override.

#### output

- `Unit` - No return value. The record is either skipped, enqueued, or dropped according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- The logger checks `is_enabled(level)` before building a record.
- Context fields, patch logic, and filter logic are applied before enqueue.
- If timestamping is enabled, `@env.now()` is captured before the record enters the queue.
- Overflow behavior depends on the configured `AsyncOverflowPolicy`.

### How to Use

Here are some specific examples provided.

#### When Need A Fully Explicit Async Log Call

When code should choose level, fields, and target per event:
```moonbit
await logger.log(
  @bitlogger.Level::Info,
  "worker started",
  fields=[@bitlogger.field("job", "sync")],
  target="service.worker",
)
```

In this example, all per-record inputs are supplied explicitly.

#### When Build Higher-level Async Logging Helpers

When application code wants a custom wrapper around the base API:
```moonbit
await logger.log(@bitlogger.Level::Warn, "slow request")
```

In this example, `log(...)` acts as the common primitive under custom wrappers or convenience methods.

### Error Case

e.g.:
- If the level is below the current minimum threshold, the record is skipped before queue insertion.

- If the logger is closed or overflow policy rejects the record, enqueue may not proceed as a normal accepted write.

### Notes

1. Use this API when the call site needs full control instead of a fixed severity helper.

2. Prefer `info()`, `warn()`, and the other shortcuts when only the level differs.
