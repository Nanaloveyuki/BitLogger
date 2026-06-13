---
name: library-async-logger-error
group: api
category: facade
update-time: 20260614
description: Enqueue an error-level record through a LibraryAsyncLogger facade using the highest built-in severity shortcut and the repo's direct async call style.
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

- This helper delegates to `log(Level::Error, ...)` on the wrapped async logger.
- The record is still subject to patching, filtering, and overflow policy.
- Error records represent the highest built-in severity in this async facade API.
- Use this helper when a named error call is clearer than a raw `log(...)` call.

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

### Error Case

e.g.:
- If the logger is closed or overflow policy prevents acceptance, even an error-level record may not become a normal queued record.

- If callers need to inspect worker failure rather than emit an error record, `has_failed()` and `last_error()` are the relevant APIs on the full async logger.

### Notes

1. Use this helper for high-severity async application failures.

2. Emitting an error record is separate from the logger worker itself entering failure state.
