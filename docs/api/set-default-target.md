---
name: set-default-target
group: api
category: global
update-time: 20260512
description: Update the default target used by the shared global logger helpers.
key-word:
    - global
    - target
    - default
    - public
---

## Set-default-target

Update the default target used by the shared default logger returned by `default_logger()` and by the global write helpers such as `info(...)` and `error(...)`.

### Interface

```moonbit
pub fn set_default_target(target : String) -> Unit {}
```

#### input

- `target : String` - New default target string for the shared global logger configuration.

#### output

- `Unit` - No return value. The stored default target is updated for later global calls.

### Explanation

Detailed rules explaining key parameters and behaviors

- The function updates the internal `Ref[String]` used by `default_logger()`.
- It does not mutate any custom `Logger` values created earlier.
- Later global writes inherit the new target unless a different explicit logger path is used.
- This is useful when one application wants the convenience of global helpers while still labeling records consistently.

### How to Use

Here are some specific examples provided.

#### When Label Global Application Logs

When global helper calls should carry one stable target:
```moonbit
set_default_target("app")
info("service started")
```

In this example, the emitted global record uses `app` as its target.

#### When Re-scope A Temporary Execution Context

When a script or tool should tag its own global output:
```moonbit
set_default_target("tool.migration")
warn("running fallback path")
```

In this example, later global writes stay grouped under the migration target.

### Error Case

e.g.:
- If `target` is empty, global writes remain valid and simply omit the target unless another logger path supplies one.

- Previously created custom loggers are unaffected because they do not read the shared default target reference afterward.

### Notes

1. This API is best suited for small apps, scripts, or a single shared logging entry path.

2. Prefer explicit child or per-component loggers when target structure needs to vary across subsystems.

