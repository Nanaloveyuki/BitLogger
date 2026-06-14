---
name: global-log
group: api
category: global
update-time: 20260512
description: Emit a record through the shared default logger with an explicit level and optional fields.
key-word:
    - global
    - log
    - default
    - public
---

## Global-log

Emit a record through the shared default logger with an explicit level and message. This is the core global write API behind the global severity-specific shortcuts.

### Interface

```moonbit
pub fn log(level : Level, message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `level : Level` - Severity level for the record.
- `message : String` - Log message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is emitted through the current shared default logger behavior.

### Explanation

Detailed rules explaining key parameters and behaviors

- The function calls `default_logger().log(level, message, fields=fields)`.
- Each call therefore reads the current shared default threshold and target at write time instead of holding one long-lived logger value internally.
- It uses the shared console sink and the current global default threshold and target.
- Per-call target override is not exposed by this global shortcut.
- This helper is most useful when convenience matters more than explicit logger ownership.

### How to Use

Here are some specific examples provided.

#### When Need A Simple Global Logging Entry

When application code wants a direct severity-controlled write:
```moonbit
log(Level::Info, "service started")
```

In this example, the shared default logger handles the record without requiring an explicit logger variable.

If `set_default_min_level(...)` or `set_default_target(...)` changes later, future `log(...)` calls will observe those updated shared defaults automatically.

#### When Attach Structured Metadata Globally

When a global event should still include fields:
```moonbit
log(Level::Warn, "retry scheduled", fields=[field("attempt", "2")])
```

In this example, the global path still supports structured logging data.

### Error Case

e.g.:
- If the level is below the current shared minimum threshold, the write is skipped.

- If a custom target override is required, the explicit `Logger::log(...)` API is a better fit.

### Notes

1. This API is convenient but intentionally less configurable than an explicit logger value.

2. Future calls pick up later shared-default changes because the helper forwards through a fresh `default_logger()` each time.

3. Prefer explicit loggers when different subsystems need different sink or target behavior.

