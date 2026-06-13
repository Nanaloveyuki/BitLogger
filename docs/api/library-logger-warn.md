---
name: library-logger-warn
group: api
category: facade
update-time: 20260613
description: Emit a warn-level record through a LibraryLogger facade using the warning severity shortcut.
key-word:
    - library
    - facade
    - warn
    - public
---

## Library-logger-warn

Emit a warn-level record through the library-facing sync logger. This is the convenience wrapper for `log(Level::Warn, ...)` on `LibraryLogger[S]`.

### Interface

```moonbit
pub fn[S : Sink] LibraryLogger::warn(
  self : LibraryLogger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
```

#### input

- `self : LibraryLogger[S]` - Library-facing logger that should emit the warning record.
- `message : String` - Warning message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the current threshold and wrapped sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Warn, ...)` on the wrapped logger.
- Warning records are useful for abnormal but non-fatal conditions.
- Per-call target override is not exposed here; use `log(...)` when that is required.
- All logger wrappers still participate normally in the write path.

### How to Use

Here are some specific examples provided.

#### When Signal A Recoverable Library Problem

When an operation degraded but still continued:
```moonbit
logger.warn("cache miss ratio increased")
```

In this example, the event is elevated above normal information without being treated as a hard failure.

#### When Attach Structured Warning Context

When a warning should include machine-readable detail:
```moonbit
logger.warn("retry scheduled", fields=[field("attempt", "3")])
```

In this example, the warning remains easy to filter and inspect later.

### Error Case

e.g.:
- If the logger minimum level is above `Warn`, the call returns without writing a record.

- If a target override is needed at this call site, use `log(...)` instead of this shortcut.

### Notes

1. Use this helper for degraded or suspicious states that do not stop execution.

2. Warning logs are often a practical signal threshold for alerting or separate routing.
