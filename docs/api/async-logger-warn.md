---
name: async-logger-warn
group: api
category: async
update-time: 20260614
description: Enqueue a warning-level record through the async logger using the built-in severity shortcut and the repo's direct async call style.
key-word:
    - async
    - logger
    - warn
    - public
---

## Async-logger-warn

Enqueue a warning-level record through the async logger. This is the convenience wrapper for `log(Level::Warn, ...)`.

### Interface

```moonbit
pub async fn[S] AsyncLogger::warn(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should receive the warning record.
- `message : String` - Warning message text.
- `fields : Array[Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Warn, ..., fields=fields)`.
- The record is still subject to min-level gating, patching, filtering, and overflow policy.
- This helper does not accept a per-call target override. It uses the logger's stored target unless the logger was derived earlier with `with_target(...)` or `child(...)`.
- Warning records are useful for degraded but non-fatal runtime conditions.
- Use this helper when a named warning call is clearer than a raw `log(...)` call.

### How to Use

Here are some specific examples provided.

#### When Need Async Degradation Signals

When the system should report a non-fatal problem:
```moonbit
logger.warn("retry budget running low")
```

In this example, the event is surfaced at warning severity without using the generic `log(...)` form.

#### When Attach Structured Warning Detail

When a warning event should include context:
```moonbit
logger.warn(
  "queue near capacity",
  fields=[@bitlogger.field("pending", logger.pending_count().to_string())],
)
```

In this example, the warning carries structured operational detail.

And any shared context already carried by the logger still participates ahead of these per-call fields when the record is built.

The write still uses the logger's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger minimum level is above `Warn`, the record is skipped before enqueue.

- If the logger is closed or overflow policy prevents acceptance, the write may not become a normal queued record.

### Notes

1. Use this helper for notable but non-fatal async runtime conditions.

2. Use `log(...)` instead when one warning call must override the target without deriving a new logger value.
