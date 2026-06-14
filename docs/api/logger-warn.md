---
name: logger-warn
group: api
category: logging
update-time: 20260512
description: Emit a warn-level record through the logger using the warning severity shortcut.
key-word:
    - logger
    - warn
    - sync
    - public
---

## Logger-warn

Emit a warn-level record through the synchronous logger. This is the convenience wrapper for `log(Level::Warn, ...)`.

### Interface

```moonbit
pub fn[S : Sink] Logger::warn(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `self : Logger[S]` - Logger that should emit the warning record.
- `message : String` - Warning message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the logger threshold and sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Warn, ...)`.
- Warning records are useful for abnormal but non-fatal conditions.
- This helper does not accept a per-call target override. It uses the logger's stored target unless the logger was derived earlier with `with_target(...)` or `child(...)`.
- All logger wrappers still participate normally in the write path.

### How to Use

Here are some specific examples provided.

#### When Signal A Recoverable Problem

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

And any shared context already carried by the logger still participates through the sink pipeline.

The write still uses the logger's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger minimum level is above `Warn`, the call returns without writing a record.

- If a target override is needed at this call site, use `log(...)` instead of this shortcut.

### Notes

1. Use this helper for degraded or suspicious states that do not stop execution.

2. Warning logs are often a practical signal threshold for alerting or separate routing.

