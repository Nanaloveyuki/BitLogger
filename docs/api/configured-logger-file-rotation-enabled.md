---
name: configured-logger-file-rotation-enabled
group: api
category: runtime
update-time: 20260512
description: Read whether rotation is currently enabled on the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-rotation-enabled

Read whether rotation is currently enabled on a `ConfiguredLogger` file sink. This helper exposes whether runtime rotation policy is active.

### Interface

```moonbit
pub fn ConfiguredLogger::file_rotation_enabled(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose rotation state should be inspected.

#### output

- `Bool` - Whether rotation is currently enabled.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks report whether a rotation config is active.
- Queued file sinks forward the state from the wrapped file sink.
- Non-file sinks return `false`.
- This helper is narrower than `file_rotation_config()` when only a yes/no check is needed.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Rotation Visibility

When support output should expose whether rotation is active:
```moonbit
let rotating = logger.file_rotation_enabled()
```

In this example, callers get a direct boolean answer without inspecting config objects.

#### When Guard Rotation-specific Behavior

When logic should only run for rotating file sinks:
```moonbit
if logger.file_rotation_enabled() {
  println("rotation active")
}
```

In this example, runtime policy can drive control flow.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need the actual rotation parameters, `file_rotation_config()` is the better API.

### Notes

1. Use this helper for simple runtime rotation checks.

2. Pair it with `file_rotation_config()` when parameters also matter.
