---
name: global-trace
group: api
category: global
update-time: 20260512
description: Emit a trace-level record through the shared default logger shortcut.
key-word:
    - global
    - trace
    - default
    - public
---

## Global-trace

Emit a trace-level record through the shared default logger. This is the global convenience wrapper for `log(Level::Trace, ...)`.

### Interface

```moonbit
pub fn trace(message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `message : String` - Trace message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled through the shared default logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `default_logger().trace(...)`.
- Trace is the lowest built-in severity and is commonly disabled unless the shared minimum level is lowered.
- The shared default target and console sink are used.
- This helper favors convenience over explicit per-component logger ownership.

### How to Use

Here are some specific examples provided.

#### When Need Quick Global Trace Output

When a script or small app wants temporary low-level diagnostics:
```moonbit
set_default_min_level(Level::Trace)
trace("entered sync loop")
```

In this example, the shared global path begins accepting trace records.

#### When Attach Structured Trace Context

When a global trace event should carry fields:
```moonbit
trace("cache probe", fields=[field("key", "user:42")])
```

In this example, the global helper still supports structured metadata.

### Error Case

e.g.:
- If the shared minimum level is above `Trace`, the record is skipped.

- If you need per-call target control, use an explicit `Logger` instead of this helper.

### Notes

1. Global trace logging is convenient for scripts but easy to overuse in larger systems.

2. This helper always goes through the shared default logger path.

