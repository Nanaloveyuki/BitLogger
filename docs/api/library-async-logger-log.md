---
name: library-async-logger-log
group: api
category: facade
update-time: 20260614
description: Enqueue a record through a LibraryAsyncLogger facade with explicit level, message, fields, and optional target override by delegating to the wrapped async logger.
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
- Stored shared context fields are prepended ahead of per-call `fields`, then patch and filter logic are applied before enqueue.
- If `target` is empty, the logger uses its current default target; otherwise the provided per-call target overrides that default for this one write.
- The narrower library facade does not change enqueue semantics, overflow handling, or runtime-dependent closed-on-log behavior; it only limits the visible API surface.
- Async state helpers such as `pending_count()`, `dropped_count()`, `state()`, `has_failed()`, and `last_error()` remain on the underlying `AsyncLogger[S]` and require `to_async_logger()` first.

### How to Use

Here are some specific examples provided.

#### When Need Full Per-call Control Through The Async Facade

When library code should choose level, fields, and target per event:
```moonbit
logger.log(
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
logger.log(@bitlogger.Level::Warn, "slow request")
```

In this example, `log(...)` acts as the shared primitive under custom library-facing wrappers.

#### When Need Shared Context Plus Event-specific Fields

When a facade already carries shared metadata but a single write needs additional detail:
```moonbit
let logger = base.with_context_fields([@bitlogger.field("service", "cache")])
logger.log(
  @bitlogger.Level::Info,
  "entry refreshed",
  fields=[@bitlogger.field("key", "user:42")],
)
```

In this example, the stored shared fields remain in front of the per-call fields when the record is built.

### Error Case

e.g.:
- If the level is below the current minimum threshold, the record is skipped before queue insertion.

- If the logger is closed or overflow policy rejects the record, enqueue may not proceed as a normal accepted write.

- If callers need to inspect queue or failure state after writing, they must unwrap first with `to_async_logger()`.

### Notes

1. Use this API when the call site needs full control instead of a fixed severity helper.

2. Prefer `info()`, `warn()`, `error()`, and the other shortcuts when only the level differs.

3. Use the optional `target` argument when one write should temporarily override the facade's default target without rebuilding or rewrapping it.
