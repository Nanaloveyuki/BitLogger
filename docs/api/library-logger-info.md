---
name: library-logger-info
group: api
category: facade
update-time: 20260613
description: Emit an info-level record through a LibraryLogger facade using the informational severity shortcut.
key-word:
    - library
    - facade
    - info
    - public
---

## Library-logger-info

Emit an info-level record through the library-facing sync logger. This is the convenience wrapper for `log(Level::Info, ...)` on `LibraryLogger[S]`.

### Interface

```moonbit
pub fn[S : Sink] LibraryLogger::info(
  self : LibraryLogger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
```

#### input

- `self : LibraryLogger[S]` - Library-facing logger that should emit the info record.
- `message : String` - Informational message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the current threshold and wrapped sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Info, ...)` on the wrapped logger.
- `Info` is the default minimum logger threshold unless changed explicitly.
- Per-call target override is not exposed here; use `log(...)` if needed.
- The library facade keeps the same write semantics while exposing a smaller public surface.

### How to Use

Here are some specific examples provided.

#### When Emit Normal Library Lifecycle Events

When a package should report standard lifecycle milestones:
```moonbit
logger.info("service started")
```

In this example, the event uses normal informational severity through the narrower facade.

#### When Attach Structured Informational Context

When an info event should include machine-readable metadata:
```moonbit
logger.info("request completed", fields=[field("status", "200")])
```

In this example, the event remains concise while still carrying useful fields.

### Error Case

e.g.:
- If the logger minimum level is above `Info`, the call returns without writing a record.

- If the event needs an explicit alternate target, use `log(...)` instead of this shortcut.

### Notes

1. This is the common convenience method for normal library-facing events.

2. Because `Info` is often the default threshold, this helper is a natural baseline for facade examples.
