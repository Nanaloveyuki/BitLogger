---
name: library-logger-warn
group: api
category: facade
update-time: 20260613
description: Emit a warn-level record through a LibraryLogger facade by delegating to the wrapped logger's warn shortcut.
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

- This helper delegates to `warn(...)` on the wrapped logger, which in turn uses `log(Level::Warn, ...)`.
- Warning records are useful for abnormal but non-fatal conditions.
- This helper does not accept a per-call target override. It uses the facade's stored target unless the facade was derived earlier with `with_target(...)` or `child(...)`.
- All sink-side wrappers still participate normally in the write path.
- Broader composition helpers remain on the underlying `Logger[S]` and require `to_logger()` first.

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

And any shared context already carried by the facade still participates through the wrapped logger pipeline.

And the write still uses the facade's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger minimum level is above `Warn`, the call returns without writing a record.

- If a target override is needed at this call site, use `log(...)` instead of this shortcut.

- If callers need broader composition helpers after logging, they must unwrap first with `to_logger()`.

### Notes

1. Use this helper for degraded or suspicious states that do not stop execution.

2. Warning logs are often a practical signal threshold for alerting or separate routing.

3. Use `log(...)` instead when the call site needs a per-call target override or a dynamic level.
