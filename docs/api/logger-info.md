---
name: logger-info
group: api
category: logging
update-time: 20260512
description: Emit an info-level record through the logger using the standard informational severity shortcut.
key-word:
    - logger
    - info
    - sync
    - public
---

## Logger-info

Emit an info-level record through the synchronous logger. This is the convenience wrapper for `log(Level::Info, ...)`.

### Interface

```moonbit
pub fn[S : Sink] Logger::info(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `self : Logger[S]` - Logger that should emit the info record.
- `message : String` - Informational message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the logger threshold and sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Info, ...)`.
- `Info` is the default minimum logger threshold unless changed explicitly.
- This helper does not accept a per-call target override. It uses the logger's stored target unless the logger was derived earlier with `with_target(...)` or `child(...)`.
- Context fields, filters, patches, and queue wrappers behave exactly as they do for other write methods.

### How to Use

Here are some specific examples provided.

#### When Emit Normal Application Events

When a service should report standard lifecycle milestones:
```moonbit
logger.info("service started")
```

In this example, the log event uses the normal informational severity.

#### When Attach Structured Informational Context

When an info event should include machine-readable metadata:
```moonbit
logger.info("request completed", fields=[field("status", "200")])
```

In this example, the event remains concise while still carrying useful fields.

And any shared context already carried by the logger still participates through the sink pipeline.

The write still uses the logger's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger minimum level is above `Info`, the call returns without writing a record.

- If the event needs an explicit alternate target, use `log(...)` instead of this shortcut.

### Notes

1. This is the most common convenience method for normal application events.

2. Because `Info` is often the default threshold, this helper is a common baseline for examples and docs.

