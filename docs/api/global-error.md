---
name: global-error
group: api
category: global
update-time: 20260512
description: Emit an error-level record through the shared default logger shortcut.
key-word:
    - global
    - error
    - default
    - public
---

## Global-error

Emit an error-level record through the shared default logger. This is the global convenience wrapper for `log(Level::Error, ...)`.

### Interface

```moonbit
pub fn error(message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `message : String` - Error message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled through the shared default logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `default_logger().error(...)`.
- It uses the shared console sink, default target, and current threshold configuration.
- `Error` is the highest built-in severity in the global sync helper set.
- This helper is useful when a small app wants a direct shared failure-reporting path.

### How to Use

Here are some specific examples provided.

#### When Report A Global Failure Event

When a small application should emit an explicit failure log:
```moonbit
error("worker execution failed")
```

In this example, the shared default logger emits a high-severity error record.

#### When Attach Structured Error Context

When an error event should include machine-readable detail:
```moonbit
error("dispatch failed", fields=[field("job_id", "42")])
```

In this example, the global helper still supports structured fields.

### Error Case

e.g.:
- If the shared minimum level is above `Error`, the call still returns without writing, though this configuration is unusual.

- If one module should not share the same sink or target policy, the global helper path may be too blunt.

### Notes

1. Use this helper for simple shared error reporting.

2. Explicit `Logger` values are usually better once the application needs richer routing or ownership boundaries.

