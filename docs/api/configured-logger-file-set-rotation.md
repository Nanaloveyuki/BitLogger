---
name: configured-logger-file-set-rotation
group: api
category: runtime
update-time: 20260512
description: Update the rotation configuration used by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-set-rotation

Update the rotation configuration used by a `ConfiguredLogger` file sink. This helper changes runtime file rotation behavior without rebuilding the logger.

### Interface

```moonbit
pub fn ConfiguredLogger::file_set_rotation(
  self : ConfiguredLogger,
  rotation : FileRotation?,
) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose rotation policy should change.
- `rotation : FileRotation?` - New rotation config, or `None` to disable rotation.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks update their runtime rotation policy.
- Queued file sinks forward the update to the wrapped file sink.
- Passing `None` disables rotation.
- Non-file sinks return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Rotation Tuning

When a file sink should enable or change rotation dynamically:
```moonbit
ignore(logger.file_set_rotation(Some(file_rotation(1024, max_backups=3))))
```

In this example, runtime rotation behavior is updated without rebuilding the logger.

#### When Need To Disable Rotation

When the file sink should stop rotating:
```moonbit
let ok = logger.file_set_rotation(None)
```

In this example, the runtime file sink has its rotation policy cleared explicitly.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers only want to remove rotation, `file_clear_rotation()` is the more direct API.

### Notes

1. Use this helper when setting a full runtime rotation config.

2. It is useful for operational tuning without rebuilding the logger.
