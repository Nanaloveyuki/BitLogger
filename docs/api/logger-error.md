---
name: logger-error
group: api
category: logging
update-time: 20260512
description: Emit an error-level record through the logger using the highest built-in severity shortcut.
key-word:
    - logger
    - error
    - sync
    - public
---

## Logger-error

Emit an error-level record through the synchronous logger. This is the convenience wrapper for `log(Level::Error, ...)`.

### Interface

```moonbit
pub fn[S : Sink] Logger::error(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `self : Logger[S]` - Logger that should emit the error record.
- `message : String` - Error message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the logger threshold and sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Error, ...)`.
- `Error` is the highest built-in severity in this sync logger API.
- Per-call target override is not exposed here; use `log(...)` when explicit target control is required.
- Sink composition, filtering, patching, and queue wrappers still apply normally.

### How to Use

Here are some specific examples provided.

#### When Report A Failing Operation

When an operation should emit a high-severity failure event:
```moonbit
logger.error("worker execution failed")
```

In this example, the call site clearly communicates failure severity.

#### When Attach Structured Error Context

When an error event should include diagnostic fields:
```moonbit
logger.error("dispatch failed", fields=[field("job_id", "42")])
```

In this example, the record carries machine-readable context without dropping to the generic `log(...)` form.

### Error Case

e.g.:
- If the logger minimum level is above `Error`, the call still returns without writing, though this configuration is unusual.

- If a target override is required, use `log(...)` instead of this severity shortcut.

### Notes

1. Use this helper for high-severity application failures.

2. Emitting an error record is separate from throwing or handling program exceptions.

