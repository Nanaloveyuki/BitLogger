---
name: library-logger-error
group: api
category: facade
update-time: 20260613
description: Emit an error-level record through a LibraryLogger facade by delegating to the wrapped logger's error shortcut.
key-word:
    - library
    - facade
    - error
    - public
---

## Library-logger-error

Emit an error-level record through the library-facing sync logger. This is the convenience wrapper for `log(Level::Error, ...)` on `LibraryLogger[S]`.

### Interface

```moonbit
pub fn[S : Sink] LibraryLogger::error(
  self : LibraryLogger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
```

#### input

- `self : LibraryLogger[S]` - Library-facing logger that should emit the error record.
- `message : String` - Error message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the current threshold and wrapped sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `error(...)` on the wrapped logger, which in turn uses `log(Level::Error, ...)`.
- `Error` is the highest built-in severity in this sync facade API.
- Per-call target override is not exposed here; use `log(...)` when explicit target control is required.
- Sink composition, filtering, patching, and queue wrappers still apply normally.
- Broader composition helpers remain on the underlying `Logger[S]` and require `to_logger()` first.

### How to Use

Here are some specific examples provided.

#### When Report A Failing Library Operation

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

And any shared context already carried by the facade still participates through the wrapped logger pipeline.

### Error Case

e.g.:
- If the logger minimum level is above `Error`, the call still returns without writing, though this configuration is unusual.

- If a target override is required, use `log(...)` instead of this severity shortcut.

- If callers need broader composition helpers after logging, they must unwrap first with `to_logger()`.

### Notes

1. Use this helper for high-severity library failures.

2. Emitting an error record is separate from throwing or handling program exceptions.

3. Use `log(...)` instead when the call site needs a per-call target override or a dynamic level.
