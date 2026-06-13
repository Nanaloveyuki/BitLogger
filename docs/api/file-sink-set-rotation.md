---
name: file-sink-set-rotation
group: api
category: sink
update-time: 20260613
description: Update the rotation configuration used by a FileSink.
key-word:
    - file
    - sink
    - rotation
    - public
---

## File-sink-set-rotation

Update the rotation configuration used by a `FileSink`. This helper changes direct runtime file rotation behavior without rebuilding or reopening the sink.

### Interface

```moonbit
pub fn FileSink::set_rotation(self : FileSink, rotation : FileRotation?) -> Unit {
```

#### input

- `self : FileSink` - File sink whose rotation policy should change.
- `rotation : FileRotation?` - New rotation config, or `None` to disable rotation.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method updates runtime rotation policy only.
- Passing `None` disables rotation.
- It does not reopen the sink or rotate immediately by itself.
- Append and auto-flush settings are left unchanged.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Rotation Tuning

When a concrete file sink should enable or change rotation dynamically:
```moonbit
sink.set_rotation(Some(file_rotation(1024, max_backups=3)))
```

In this example, direct runtime rotation behavior is updated without rebuilding the sink.

#### When Need To Disable Rotation

When the file sink should stop rotating:
```moonbit
sink.set_rotation(None)
```

In this example, the sink has its rotation policy cleared explicitly.

### Error Case

e.g.:
- If callers only want to remove rotation, `clear_rotation()` is the more direct API.

- This helper does not report past rotation failures; use `rotation_failures()` or `state()` for diagnostics.

### Notes

1. Use this helper when setting a full runtime rotation config.

2. It is useful for operational tuning on a concrete file sink without rebuilding it.
