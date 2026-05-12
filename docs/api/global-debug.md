---
name: global-debug
group: api
category: global
update-time: 20260512
description: Emit a debug-level record through the shared default logger shortcut.
key-word:
    - global
    - debug
    - default
    - public
---

## Global-debug

Emit a debug-level record through the shared default logger. This is the global convenience wrapper for `log(Level::Debug, ...)`.

### Interface

```moonbit
pub fn debug(message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `message : String` - Debug message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled through the shared default logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `default_logger().debug(...)`.
- The record uses the current shared minimum level and target configuration.
- Debug output is typically intended for development and troubleshooting.
- This helper is best suited to small apps or code paths that intentionally rely on the shared logger.

### How to Use

Here are some specific examples provided.

#### When Need Simple Global Debug Logging

When code wants quick diagnostics without wiring a logger variable:
```moonbit
set_default_min_level(Level::Debug)
debug("cache refreshed")
```

In this example, the shared global path starts accepting debug records.

#### When Attach Structured Debug Context

When a debug event should include machine-readable detail:
```moonbit
debug("session loaded", fields=[field("user_id", "42")])
```

In this example, the global shortcut still supports structured fields.

### Error Case

e.g.:
- If the shared minimum level is above `Debug`, the record is skipped.

- If different modules need distinct targets or sinks, a shared global debug path may be too coarse.

### Notes

1. Prefer explicit loggers once application logging becomes subsystem-specific.

2. Use `set_default_min_level(...)` before expecting global debug output to appear.

