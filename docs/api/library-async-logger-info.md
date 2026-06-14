---
name: library-async-logger-info
group: api
category: facade
update-time: 20260614
description: Enqueue an info-level record through a LibraryAsyncLogger facade by delegating to the wrapped async logger's info shortcut.
key-word:
    - async
    - library
    - info
    - public
---

## Library-async-logger-info

Enqueue an info-level record through the library-facing async logger. This is the convenience wrapper for `log(Level::Info, ...)` on `LibraryAsyncLogger[S]`.

### Interface

```moonbit
pub async fn[S] LibraryAsyncLogger::info(
  self : LibraryAsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger that should receive the info record.
- `message : String` - Info message text.
- `fields : Array[@bitlogger.Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `info(...)` on the wrapped async logger, which in turn uses `log(Level::Info, ...)`.
- The record is still subject to min-level gating, stored shared context fields, patching, filtering, and overflow policy.
- This helper does not accept a per-call target override. It uses the facade's stored target unless the facade was derived earlier with `with_target(...)` or `child(...)`.
- `Info` is often the default operational logging level for async application events.
- Use this helper when explicit info intent is clearer than a raw `log(...)` call.
- Async state helpers remain on the underlying `AsyncLogger[S]` and require `to_async_logger()` first.

### How to Use

Here are some specific examples provided.

#### When Need Normal Operational Async Library Events

When async package code should report routine progress or lifecycle events:
```moonbit
logger.info("worker started")
```

In this example, the event is expressed at the common operational logging level through the narrower facade.

#### When Add Structured Operational Metadata

When an info event should include stable structured detail:
```moonbit
logger.info(
  "job queued",
  fields=[@bitlogger.field("queue", "sync")],
)
```

In this example, the record remains concise while still carrying useful metadata.

And any shared context fields already stored on the facade are still prepended before these per-call fields.

And the write still uses the facade's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger minimum level is above `Info`, the record is skipped before enqueue.

- If the logger is closed or overflow policy prevents acceptance, the write may not become a normal queued record.

- If callers need a per-call target override, they should use `log(...)` instead of this fixed-level shortcut.

### Notes

1. This is often the most common convenience method for normal async library events.

2. Use `log(...)` when the call site needs a dynamic level or target override.

3. Use `to_async_logger()` first when later code needs queue or failure inspection rather than another write shortcut.
