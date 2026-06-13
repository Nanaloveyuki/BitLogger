---
name: library-async-logger-log
group: api
category: facade
update-time: 20260613
description: Enqueue a record through a LibraryAsyncLogger facade with explicit level, message, fields, and optional target override.
key-word:
    - async
    - library
    - log
    - public
---

## Library-async-logger-log

Enqueue a record through the library-facing async logger with an explicit level and message. This is the core write API behind the level-specific `LibraryAsyncLogger` convenience methods.

### Interface

```moonbit
pub async fn[S] LibraryAsyncLogger::log(
  self : LibraryAsyncLogger[S],
  level : @bitlogger.Level,
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
  target? : String = "",
) -> Unit {
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger that should receive the record.
- `level : @bitlogger.Level` - Severity level for the record.
- `message : String` - Log message text.
- `fields : Array[@bitlogger.Field]` - Optional structured fields added to the record.
- `target : String` - Optional per-call target override.

#### output

- `Unit` - No return value. The record is either skipped, enqueued, or dropped according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates directly to the wrapped async logger's `log(...)` behavior.
- The logger checks `is_enabled(level)` before building a record.
- Context fields, patch logic, and filter logic are applied before enqueue.
- The narrower library facade does not change enqueue semantics; it only limits the visible API surface.

### How to Use

Here are some specific examples provided.

#### When Need Full Per-call Control Through The Async Facade

When library code should choose level, fields, and target per event:
```moonbit
await logger.log(
  @bitlogger.Level::Info,
  "worker started",
  fields=[@bitlogger.field("job", "sync")],
  target="service.worker",
)
```

In this example, the call site controls every major record property while keeping the narrower facade type.

#### When Build Higher-level Async Library Wrappers

When package code defines its own logging helpers:
```moonbit
await logger.log(@bitlogger.Level::Warn, "slow request")
```

In this example, `log(...)` acts as the shared primitive under custom library-facing wrappers.

### Error Case

e.g.:
- If the level is below the current minimum threshold, the record is skipped before queue insertion.

- If the logger is closed or overflow policy rejects the record, enqueue may not proceed as a normal accepted write.

### Notes

1. Use this API when the call site needs full control instead of a fixed severity helper.

2. Prefer `info()`, `warn()`, `error()`, and the other shortcuts when only the level differs.
