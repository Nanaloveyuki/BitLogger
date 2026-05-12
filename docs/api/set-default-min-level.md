---
name: set-default-min-level
group: api
category: global
update-time: 20260512
description: Update the minimum level used by the shared default logger helpers.
key-word:
    - global
    - level
    - default
    - public
---

## Set-default-min-level

Update the minimum level used by the shared default logger returned by `default_logger()` and consumed by the global `log(...)`, `info(...)`, `warn(...)`, and similar helpers.

### Interface

```moonbit
pub fn set_default_min_level(level : Level) -> Unit {}
```

#### input

- `level : Level` - New minimum level for the shared default logger configuration.

#### output

- `Unit` - No return value. The stored default threshold is updated for later global calls.

### Explanation

Detailed rules explaining key parameters and behaviors

- The function updates the internal `Ref[Level]` used by `default_logger()`.
- It does not mutate any separately stored `Logger` values that were created earlier.
- Later calls to `default_logger()` and the global logging shortcuts observe the new threshold.
- This is the main API for adjusting process-wide default severity without building a custom logger variable.

### How to Use

Here are some specific examples provided.

#### When Raise Global Threshold In Production

When verbose logs should be suppressed process-wide:
```moonbit
set_default_min_level(Level::Warn)
```

In this example, later global `info(...)` calls are skipped while `warn(...)` and `error(...)` remain active.

#### When Enable Temporary Debug Visibility

When diagnostics should be turned on for a session:
```moonbit
set_default_min_level(Level::Debug)
debug("cache probe enabled")
```

In this example, the shared global path starts accepting debug records.

### Error Case

e.g.:
- If the level is set too high, lower-severity global writes are intentionally skipped.

- Existing custom `Logger` instances keep their own thresholds and are not retroactively changed.

### Notes

1. This API only affects the shared default logger workflow.

2. Prefer explicit logger instances when different subsystems need different thresholds at the same time.

