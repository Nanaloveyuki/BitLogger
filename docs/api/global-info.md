---
name: global-info
group: api
category: global
update-time: 20260512
description: Emit an info-level record through the shared default logger shortcut.
key-word:
    - global
    - info
    - default
    - public
---

## Global-info

Emit an info-level record through the shared default logger. This is the global convenience wrapper for `log(Level::Info, ...)`.

### Interface

```moonbit
pub fn info(message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `message : String` - Informational message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled through the shared default logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `default_logger().info(...)`.
- It uses the shared console sink and current default target.
- `Info` is the default global threshold unless changed through `set_default_min_level(...)`.
- This is the simplest entry point for normal app-level informational events.

### How to Use

Here are some specific examples provided.

#### When Emit Simple Global Application Events

When a small app wants direct lifecycle logging:
```moonbit
set_default_target("app")
info("service started")
```

In this example, the shared default logger emits an informational record under the `app` target.

#### When Attach Structured Informational Data

When a global info event should include metadata:
```moonbit
info("request completed", fields=[field("status", "200")])
```

In this example, the global helper still supports structured fields.

### Error Case

e.g.:
- If the shared minimum level is above `Info`, the record is skipped.

- If different components need different targets, shared global info logging may become too broad.

### Notes

1. This is the most common global write helper for small applications or scripts.

2. Prefer explicit loggers when the codebase grows beyond one shared logging path.

