---
name: logger-debug
group: api
category: logging
update-time: 20260512
description: Emit a debug-level record through the logger using the debug severity shortcut.
key-word:
    - logger
    - debug
    - sync
    - public
---

## Logger-debug

Emit a debug-level record through the synchronous logger. This is the convenience wrapper for `log(Level::Debug, ...)`.

### Interface

```moonbit
pub fn[S : Sink] Logger::debug(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `self : Logger[S]` - Logger that should emit the debug record.
- `message : String` - Debug message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the logger threshold and sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Debug, ...)`.
- Debug logging is useful for development diagnostics that are usually too verbose for normal production visibility.
- This helper does not accept a per-call target override. It uses the logger's stored target unless the logger was derived earlier with `with_target(...)` or `child(...)`.
- All logger wrappers remain active exactly as they would for the base `log(...)` path.

### How to Use

Here are some specific examples provided.

#### When Need Internal State Diagnostics

When implementation details should be observable during debugging:
```moonbit
logger.debug("cache refreshed")
```

In this example, the call site signals a development-focused diagnostic event.

#### When Attach Structured Debug Fields

When a debug event should carry explicit state:
```moonbit
logger.debug("session loaded", fields=[field("user_id", "42")])
```

In this example, the logger emits structured state without using the fully explicit `log(...)` form.

And any shared context already carried by the logger still participates through the sink pipeline.

The write still uses the logger's stored target because this shortcut does not take a one-off `target=` override.

### Error Case

e.g.:
- If the logger minimum level is above `Debug`, the call returns without writing a record.

- If the event needs a custom target override, use `log(...)` instead of this shortcut.

### Notes

1. Prefer this helper when debug intent is more readable than a raw `log(Level::Debug, ...)` call.

2. Use `is_enabled(Level::Debug)` when building the debug payload is expensive.

