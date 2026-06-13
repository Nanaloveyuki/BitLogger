---
name: configured-logger-file-clear-rotation
group: api
category: runtime
update-time: 20260512
description: Disable runtime rotation on the configured file-backed logger sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-clear-rotation

Disable runtime rotation on a `ConfiguredLogger` file sink. This helper is the direct shortcut for clearing rotation policy.

### Interface

```moonbit
pub fn ConfiguredLogger::file_clear_rotation(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose rotation policy should be cleared.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks clear their runtime rotation policy through the wrapped `RuntimeSink`.
- Queued file sinks forward the update to the wrapped inner file sink.
- Non-file sinks return `false`.
- This helper is equivalent in intent to setting rotation to `None`, but is clearer at the call site.

### How to Use

Here are some specific examples provided.

#### When Need To Disable Rotation Explicitly

When runtime file rotation should be turned off:
```moonbit
ignore(logger.file_clear_rotation())
```

In this example, rotation policy is removed directly.

#### When Need A Clear Intent Shortcut

When code should make the disable-rotation intent obvious:
```moonbit
let ok = logger.file_clear_rotation()
```

In this example, the call site reads more clearly than a generic config setter.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need to switch to another rotation config rather than disable rotation, `file_set_rotation(...)` is the better API.

### Notes

1. Use this helper when the desired effect is simply “rotation off”.

2. It is clearer than passing `None` through a broader setter when intent matters.
