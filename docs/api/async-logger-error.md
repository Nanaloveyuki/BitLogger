---
name: async-logger-error
group: api
category: async
update-time: 20260614
description: Enqueue an error-level record through the async logger using the highest built-in severity shortcut and the repo's direct async call style.
key-word:
    - async
    - logger
    - error
    - public
---

## Async-logger-error

Enqueue an error-level record through the async logger. This is the convenience wrapper for `log(Level::Error, ...)`.

### Interface

```moonbit
pub async fn[S] AsyncLogger::error(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should receive the error record.
- `message : String` - Error message text.
- `fields : Array[Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Error, ..., fields=fields)`.
- The record is still subject to min-level gating, patching, filtering, and overflow policy.
- This helper does not accept a per-call target override. It uses the logger's stored target unless the logger was derived earlier with `with_target(...)` or `child(...)`.
- Error records represent the highest built-in severity in this logger API.
- Use this helper when a named error call is clearer than a raw `log(...)` call.

### How to Use

Here are some specific examples provided.

#### When Need Async Failure Reporting

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

And any shared context already carried by the logger still participates ahead of these per-call fields when the record is built.

The write still uses the logger's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger is closed or overflow policy prevents acceptance, even an error-level record may not become a normal queued record.

- If callers need to inspect worker failure rather than emit an error record, `has_failed()` and `last_error()` are the relevant APIs.

### Notes

1. Use this helper for high-severity async application failures.

2. Use `log(...)` instead when an error call needs a one-off target override.

3. Emitting an error record is separate from the logger worker itself entering failure state.
