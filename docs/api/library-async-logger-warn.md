---
name: library-async-logger-warn
group: api
category: facade
update-time: 20260614
description: Enqueue a warning-level record through a LibraryAsyncLogger facade using the built-in severity shortcut and the repo's direct async call style.
key-word:
    - async
    - library
    - warn
    - public
---

## Library-async-logger-warn

Enqueue a warning-level record through the library-facing async logger. This is the convenience wrapper for `log(Level::Warn, ...)` on `LibraryAsyncLogger[S]`.

### Interface

```moonbit
pub async fn[S] LibraryAsyncLogger::warn(
  self : LibraryAsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger that should receive the warning record.
- `message : String` - Warning message text.
- `fields : Array[@bitlogger.Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Warn, ...)` on the wrapped async logger.
- The record is still subject to min-level gating, patching, filtering, and overflow policy.
- Warning records are useful for degraded but non-fatal runtime conditions.
- Use this helper when a named warning call is clearer than a raw `log(...)` call.

### How to Use

Here are some specific examples provided.

#### When Need Async Degradation Signals In Library Code

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
  fields=[@bitlogger.field("pending", "64")],
)
```

In this example, the warning carries structured operational detail.

### Error Case

e.g.:
- If the logger minimum level is above `Warn`, the record is skipped before enqueue.

- If the logger is closed or overflow policy prevents acceptance, the write may not become a normal queued record.

### Notes

1. Use this helper for notable but non-fatal async runtime conditions.

2. Pair warnings with structured fields when operators need quick context.
