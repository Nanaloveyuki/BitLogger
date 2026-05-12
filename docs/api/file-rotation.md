---
name: file-rotation
group: api
category: sink
update-time: 20260512
description: Create a size-based file rotation policy for native file sinks.
key-word:
    - file
    - rotation
    - policy
    - public
---

## File-rotation

Create a size-based file rotation policy for `file_sink(...)`. This helper defines how large a file may grow before rotation and how many historical backups should be retained.

### Interface

```moonbit
pub fn file_rotation(max_bytes : Int, max_backups~ : Int = 1) -> FileRotation {}
```

#### input

- `max_bytes : Int` - Maximum active file size threshold before rotation.
- `max_backups : Int` - Number of retained backup files.

#### output

- `FileRotation` - Rotation policy usable by direct file sinks or config-driven sink state.

### Explanation

Detailed rules explaining key parameters and behaviors

- `max_bytes <= 0` is normalized to `1`.
- `max_backups <= 0` is normalized to `1`.
- Rotation is size-based only.
- This policy is consumed by `file_sink(...)`, file policy helpers, and config-driven file sink assembly.

### How to Use

Here are some specific examples provided.

#### When Need Bounded Local Log Files

When a file should not grow without limit:
```moonbit
let sink = file_sink(
  "app.log",
  rotation=Some(file_rotation(1024 * 1024, max_backups=3)),
)
```

In this example, the file rotates after the configured size threshold.

And up to three backup files are retained.

#### When Need Runtime Policy Composition

When file sink policy is assembled explicitly:
```moonbit
let policy = FileSinkPolicy::new(rotation=Some(file_rotation(4096, max_backups=2)))
```

In this example, rotation can be bundled with append and auto-flush settings.

### Error Case

e.g.:
- If `max_bytes` is non-positive, it is clamped to `1`.

- If `max_backups` is non-positive, it is clamped to `1`.

### Notes

Notes are here.

1. This API defines policy only; it does not open files by itself.

2. Rotation currently focuses on size thresholds rather than time schedules or compression.

3. Use with `file_sink(...)` on native-capable backends only.

4. Policy values can later be inspected through file sink state helpers.
