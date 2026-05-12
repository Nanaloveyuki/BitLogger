---
name: async-logger-debug
group: api
category: async
update-time: 20260512
description: Enqueue a debug-level record through the async logger using the built-in severity shortcut.
key-word:
    - async
    - logger
    - debug
    - public
---

## Async-logger-debug

Enqueue a debug-level record through the async logger. This is the convenience wrapper for `log(Level::Debug, ...)`.

### Interface

```moonbit
pub async fn[S] AsyncLogger::debug(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should receive the debug record.
- `message : String` - Debug message text.
- `fields : Array[Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Debug, ...)`.
- The record is still subject to min-level gating, patching, filtering, and overflow policy.
- Debug records are useful for development and targeted diagnostics.
- Use this helper when a named debug call is clearer than a raw `log(...)` call.

### How to Use

Here are some specific examples provided.

#### When Need Async Development Diagnostics

When intermediate async flow details should be visible during debugging:
```moonbit
await logger.debug("loaded worker config")
```

In this example, the call site communicates its intended diagnostic level directly.

#### When Attach Structured Debug Context

When a debug event should include extra fields:
```moonbit
await logger.debug(
  "dispatch start",
  fields=[@bitlogger.field("job_id", "42")],
)
```

In this example, the record carries structured context without needing the generic `log(...)` form.

### Error Case

e.g.:
- If the logger minimum level is above `Debug`, the record is skipped before enqueue.

- If the logger is closed or overflow policy prevents acceptance, the write may not become a normal queued record.

### Notes

1. Prefer this helper when the event is semantically debug-level.

2. Use `log(...)` when the level must be chosen dynamically.
