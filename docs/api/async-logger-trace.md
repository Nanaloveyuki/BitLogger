---
name: async-logger-trace
group: api
category: async
update-time: 20260614
description: Enqueue a trace-level record through the async logger using the lowest built-in severity shortcut and the repo's direct async call style.
key-word:
    - async
    - logger
    - trace
    - public
---

## Async-logger-trace

Enqueue a trace-level record through the async logger. This is the convenience wrapper for `log(Level::Trace, ...)`.

### Interface

```moonbit
pub async fn[S] AsyncLogger::trace(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should receive the trace record.
- `message : String` - Trace message text.
- `fields : Array[Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Trace, ..., fields=fields)`.
- The record is still subject to min-level gating, patching, filtering, and overflow policy.
- This helper does not accept a per-call target override. It uses the logger's stored target unless the logger was derived earlier with `with_target(...)` or `child(...)`.
- Trace records are often skipped in production because they are the lowest built-in severity.
- Use this helper when explicit trace intent is clearer than a raw `log(...)` call.

### How to Use

Here are some specific examples provided.

#### When Need Fine-grained Async Diagnostics

When low-level execution flow should be observable during debugging:
```moonbit
logger.trace("entered reconciliation step")
```

In this example, the call site makes trace intent explicit.

#### When Attach Structured Trace Data

When a trace event should carry extra fields:
```moonbit
logger.trace(
  "cache probe",
  fields=[@bitlogger.field("key", "user:42")],
)
```

In this example, the record stays lightweight while still carrying structured detail.

### Error Case

e.g.:
- If the logger minimum level is above `Trace`, the record is skipped before enqueue.

- If the logger is closed or overflow policy prevents acceptance, the write may not become a normal queued record.

### Notes

1. Prefer this helper when trace intent is more readable than `log(Level::Trace, ...)`.

2. Use `log(...)` instead when one trace call needs a one-off target override.

3. Trace-level async logging can increase queue pressure quickly under verbose workloads.
