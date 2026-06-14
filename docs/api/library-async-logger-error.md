---
name: library-async-logger-error
group: api
category: facade
update-time: 20260614
description: Enqueue an error-level record through a LibraryAsyncLogger facade by delegating to the wrapped async logger's error shortcut.
key-word:
    - async
    - library
    - error
    - public
---

## Library-async-logger-error

Enqueue an error-level record through the library-facing async logger. This is the convenience wrapper for `log(Level::Error, ...)` on `LibraryAsyncLogger[S]`.

### Interface

```moonbit
pub async fn[S] LibraryAsyncLogger::error(
  self : LibraryAsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger that should receive the error record.
- `message : String` - Error message text.
- `fields : Array[@bitlogger.Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `error(...)` on the wrapped async logger, which in turn uses `log(Level::Error, ...)`.
- The record is still subject to min-level gating, stored shared context fields, patching, filtering, and overflow policy.
- This helper does not accept a per-call target override. It uses the facade's stored target unless the facade was derived earlier with `with_target(...)` or `child(...)`.
- Error records represent the highest built-in severity in this async facade API.
- Use this helper when a named error call is clearer than a raw `log(...)` call.
- Async state helpers remain on the underlying `AsyncLogger[S]` and require `to_async_logger()` first.

### How to Use

Here are some specific examples provided.

#### When Need Async Failure Reporting In A Library Boundary

When an operation should emit a high-severity failure event:
```moonbit
logger.error("worker execution failed")
```

In this example, failure intent is explicit at the call site.

#### When Attach Structured Error Context

When an error event should include diagnostic fields:
```moonbit
logger.error(
  "dispatch failed",
  fields=[@bitlogger.field("job_id", "42")],
)
```

In this example, the error record carries structured context without falling back to the generic `log(...)` form.

And any shared context fields already stored on the facade are still prepended before these per-call fields.

And the write still uses the facade's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger is closed or overflow policy prevents acceptance, even an error-level record may not become a normal queued record.

- If the logger minimum level is above `Error`, the helper still follows the same level gate, although that usually requires a custom higher threshold outside the common built-in levels.

- If callers need to inspect worker failure rather than emit an error record, `has_failed()` and `last_error()` are the relevant APIs on the full async logger.

- If callers need a per-call target override, they should use `log(...)` instead of this fixed-level shortcut.

### Notes

1. Use this helper for high-severity async application failures.

2. Emitting an error record is separate from the logger worker itself entering failure state.

3. Use `to_async_logger()` first when later code needs queue or failure inspection rather than another write shortcut.
