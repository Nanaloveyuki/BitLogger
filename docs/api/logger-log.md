---
name: logger-log
group: api
category: logging
update-time: 20260512
description: Emit a record through the logger with an explicit level, message, optional fields, and optional target override.
key-word:
    - logger
    - log
    - sync
    - public
---

## Logger-log

Emit a record through the synchronous logger with an explicit level and message. This is the core write API behind all level-specific convenience methods.

### Interface

```moonbit
pub fn[S : Sink] Logger::log(
  self : Logger[S],
  level : Level,
  message : String,
  fields~ : Array[Field] = [],
  target? : String = "",
) -> Unit {}
```

#### input

- `self : Logger[S]` - Logger that should emit the record.
- `level : Level` - Severity level for the record.
- `message : String` - Log message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.
- `target : String` - Optional per-call target override.

#### output

- `Unit` - No return value. The record is either skipped by level gating or written to the sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- The logger checks `is_enabled(level)` before building and writing the record.
- If `target` is empty, the logger's stored default target is used.
- If timestamping is enabled, `@env.now()` is captured and stored in the emitted record.
- Context, filter, patch, and queue wrappers act through the sink pipeline after the record is constructed.

### How to Use

Here are some specific examples provided.

#### When Need Full Per-call Control

When code should choose level, fields, and target explicitly:
```moonbit
logger.log(
  Level::Info,
  "worker started",
  fields=[field("job", "sync")],
  target="service.worker",
)
```

In this example, the call site controls every major record property.

#### When Build Higher-level Wrappers

When application code defines its own logging helpers:
```moonbit
fn log_retry(logger : Logger[ConsoleSink], attempt : Int) -> Unit {
  logger.log(Level::Warn, "retry scheduled", fields=[field("attempt", attempt.to_string())])
}
```

In this example, `log(...)` acts as the shared primitive under custom wrappers.

### Error Case

e.g.:
- If `level` is below the current minimum threshold, the method returns without writing a record.

- If `target` is empty and the logger default target is also empty, the emitted record simply has no target label.

### Notes

1. Use this API when the call site needs full control instead of a fixed severity helper.

2. This method is synchronous; any buffering behavior only comes from the wrapped sink type.

