---
name: async-logger-info
group: api
category: async
update-time: 20260614
description: Enqueue an info-level record through the async logger using the most common built-in severity shortcut and the repo's direct async call style.
key-word:
    - async
    - logger
    - info
    - public
---

## Async-logger-info

Enqueue an info-level record through the async logger. This is the convenience wrapper for `log(Level::Info, ...)`.

### Interface

```moonbit
pub async fn[S] AsyncLogger::info(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should receive the info record.
- `message : String` - Info message text.
- `fields : Array[Field]` - Optional structured fields added to the record.

#### output

- `Unit` - No return value. The record is handled according to logger state and policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Info, ..., fields=fields)`.
- The record is still subject to min-level gating, patching, filtering, and overflow policy.
- This helper does not accept a per-call target override. It uses the logger's stored target unless the logger was derived earlier with `with_target(...)` or `child(...)`.
- Info is often the default operational logging level for async application events.
- Use this helper when explicit info intent is clearer than a raw `log(...)` call.

### How to Use

Here are some specific examples provided.

#### When Need Normal Operational Async Events

When async code should report routine progress or lifecycle events:
```moonbit
logger.info("worker started")
```

In this example, the event is expressed at the most common operational logging level.

#### When Add Structured Operational Metadata

When an info event should include stable structured detail:
```moonbit
logger.info(
  "job queued",
  fields=[@bitlogger.field("queue", "sync")],
)
```

In this example, the record remains concise while still carrying useful metadata.

And any shared context already carried by the logger still participates ahead of these per-call fields when the record is built.

The write still uses the logger's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger minimum level is above `Info`, the record is skipped before enqueue.

- If the logger is closed or overflow policy prevents acceptance, the write may not become a normal queued record.

### Notes

1. This is often the most common convenience method for normal async application events.

2. Use `log(...)` when the call site needs a dynamic level or a one-off target override.
