---
name: async-logger-log
group: api
category: async
update-time: 20260614
description: Enqueue a record into the async logger with an explicit level, message, optional fields, and optional target override.
key-word:
    - async
    - logger
    - log
    - public
---

## Async-logger-log

Enqueue a record into the async logger with an explicit level and message. This is the core write API behind all async level-specific convenience methods and the only built-in async write API that accepts a per-call target override.

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

- Compatibility runtimes that guard closed writes first can return immediately when `is_closed()` is already `true`, before level checks, record construction, patch logic, filter logic, or queue work.
- Otherwise the logger checks `is_enabled(level)` before building a record.
- If `target` is empty, the logger uses its stored default target. If `target` is non-empty, that value overrides the stored target for this call only.
- Context fields, patch logic, and filter logic are applied before enqueue.
- If timestamping is enabled, `@env.now()` is captured before the record enters the queue.
- Overflow behavior depends on the configured `AsyncOverflowPolicy`.
- Closed-on-log behavior is runtime-dependent: compatibility runtimes short-circuit before record-building work, while native-worker runtimes may still build, patch, and filter the record before queue operations treat a closed queue as a non-accepted write.
- In the tested blocking-policy path, a late write against an already closed logger does not become a newly accepted pending record and does not add another dropped record; it simply fails to enter the queue after any runtime-specific pre-queue work finishes.

### How to Use

Here are some specific examples provided.

#### When Need A Fully Explicit Async Log Call

When code should choose level, fields, and target per event:
```moonbit
logger.log(
  @bitlogger.Level::Info,
  "worker started",
  fields=[@bitlogger.field("job", "sync")],
  target="service.worker",
)
```

In this example, the record overrides the logger's stored target only for this call.

#### When Reuse The Stored Async Target

When a call should keep the logger's existing target:
```moonbit
logger.log(@bitlogger.Level::Warn, "slow request")
```

In this example, the logger falls back to its stored target because no `target=` override is provided.

#### When Build Higher-level Async Logging Helpers

When application code wants a custom wrapper around the base API:
```moonbit
logger.log(@bitlogger.Level::Warn, "slow request")
```

In this example, `log(...)` acts as the common primitive under custom wrappers or convenience methods.

### Error Case

e.g.:
- If the level is below the current minimum threshold, the record is skipped before queue insertion.

- If the logger is closed or overflow policy rejects the record, enqueue may not proceed as a normal accepted write.

- A closed queue does not count as a newly accepted pending record.

- On compatibility runtimes, a late call after close can be skipped before patch or filter logic runs at all.

- On native-worker runtimes, a late call after close can still execute patch and filter logic before the queue rejects the write.

### Notes

1. Use this API when the call site needs full control instead of a fixed severity helper.

2. Prefer `info()`, `warn()`, and the other shortcuts when only the level differs and no per-call target override is needed.
