---
name: global-warn
group: api
category: global
update-time: 20260512
description: Emit a warn-level record through the shared default logger shortcut.
key-word:
    - global
    - warn
    - default
    - public
---

## Global-warn

Emit a warn-level record through the shared default logger. This is the global convenience wrapper for `log(Level::Warn, ...)`.

### Interface

```moonbit
pub fn warn(message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `message : String` - Warning message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled through the shared default logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `default_logger().warn(...)`.
- The shared current threshold and target determine whether and how the record is emitted.
- Warning logs are suited to degraded or suspicious states that do not necessarily stop execution.
- This helper offers convenience for a single shared logging path.

### How to Use

Here are some specific examples provided.

#### When Need A Quick Global Warning

When a recoverable issue should be surfaced without creating a logger variable:
```moonbit
warn("cache miss ratio increased")
```

In this example, the shared default logger emits a warning-severity record.

#### When Attach Structured Warning Context

When the warning should include machine-readable detail:
```moonbit
warn("retry scheduled", fields=[field("attempt", "3")])
```

In this example, the global helper still supports structured metadata.

### Error Case

e.g.:
- If the shared minimum level is above `Warn`, the record is skipped.

- If subsystem-specific routing is needed, a shared global warning path may be too limited.

### Notes

1. Global warnings are convenient for simple apps and scripts.

2. Warning-level global events are often the first candidate for separate monitoring or routing later.

