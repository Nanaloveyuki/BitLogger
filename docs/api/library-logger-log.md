---
name: library-logger-log
group: api
category: facade
update-time: 20260613
description: Emit a record through a LibraryLogger facade with explicit level, message, fields, and optional target override by delegating to the wrapped logger.
key-word:
    - library
    - facade
    - log
    - public
---

## Library-logger-log

Emit a record through the library-facing sync logger with an explicit level and message. This is the core write API behind the level-specific `LibraryLogger` convenience methods.

### Interface

```moonbit
pub fn[S : Sink] LibraryLogger::log(
  self : LibraryLogger[S],
  level : Level,
  message : String,
  fields~ : Array[Field] = [],
  target? : String = "",
) -> Unit {
```

#### input

- `self : LibraryLogger[S]` - Library-facing logger that should emit the record.
- `level : Level` - Severity level for the record.
- `message : String` - Log message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.
- `target : String` - Optional per-call target override.

#### output

- `Unit` - No return value. The record is either skipped by level gating or written to the wrapped sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates directly to the wrapped logger's `log(...)` behavior.
- The logger checks `is_enabled(level)` before building and writing the record.
- If `target` is empty, the facade's stored default target is used.
- Any existing sink wrappers already inside the wrapped logger, such as `ContextSink`, `FilterSink`, `PatchSink`, or queued/runtime sink variants, still participate normally in the write path.
- The narrower library facade does not change record construction semantics; it only limits the visible API surface.
- Broader composition helpers remain on the underlying `Logger[S]` and require `to_logger()` first.

### How to Use

Here are some specific examples provided.

#### When Need Full Per-call Control Through The Library Facade

When library code should choose level, fields, and target explicitly:
```moonbit
logger.log(
  Level::Info,
  "worker started",
  fields=[field("job", "sync")],
  target="service.worker",
)
```

In this example, the call site controls every major record property while keeping the narrower facade type.

#### When Build Higher-level Library Wrappers

When package code defines its own logging helpers:
```moonbit
fn log_retry(logger : LibraryLogger[ConsoleSink], attempt : Int) -> Unit {
  logger.log(Level::Warn, "retry scheduled", fields=[field("attempt", attempt.to_string())])
}
```

In this example, `log(...)` acts as the shared primitive under custom library-facing wrappers.

#### When Need Shared Context Plus Event-specific Fields

When a facade already carries shared context but one write needs extra detail:
```moonbit
let logger = base.with_context_fields([field("service", "cache")])
logger.log(
  Level::Info,
  "entry refreshed",
  fields=[field("key", "user:42")],
)
```

In this example, both the stored shared context and the per-call fields still flow through the wrapped logger pipeline.

### Error Case

e.g.:
- If `level` is below the current minimum threshold, the method returns without writing a record.

- If `target` is empty and the logger default target is also empty, the emitted record simply has no target label.

- If callers need broader composition helpers after writing, they must unwrap first with `to_logger()`.

### Notes

1. Use this API when the call site needs full control instead of a fixed-severity helper.

2. The facade remains synchronous; any buffering behavior only comes from the wrapped sink type.

3. Use the optional `target` argument when one write should temporarily override the facade's default target without rebuilding or rewrapping it.
