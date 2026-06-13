---
name: file-rotation-type
group: api
category: sink
update-time: 20260613
description: Public file rotation alias used for native size-based file sink policy data.
key-word:
    - file
    - rotation
    - alias
    - public
---

## File-rotation-type

`FileRotation` is the public file sink rotation policy type used for native size-based log file rollover. It is a direct alias to the sink model that stores the byte limit and retained backup count.

### Interface

```moonbit
pub type FileRotation = @utils.FileRotation
```

#### output

- `FileRotation` - Public file rotation policy object containing `max_bytes` and `max_backups`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a file sink or rotation trigger by itself.
- The current fields are `max_bytes : Int` and `max_backups : Int`.
- `file_rotation(...)` constructs this type as the main public helper.
- The same value type is consumed by `file_sink(...)`, `FileSinkPolicy::new(...)`, `SinkConfig`, file runtime inspection APIs, and logger config serialization helpers.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Rotation Policy Value

When rotation settings should be assembled once and reused across file sink setup paths:
```moonbit
let rotation : FileRotation = file_rotation(1024 * 1024, max_backups=3)
```

In this example, the rollover policy remains a typed value instead of being embedded directly in one sink call.

#### When Need To Inspect Or Carry Rotation Policy Data

When code should keep rotation settings as structured policy before applying them:
```moonbit
let policy = FileSinkPolicy::new(rotation=Some(file_rotation(4096, max_backups=2)))
```

In this example, the alias type participates in higher-level file sink policy composition.

### Error Case

e.g.:
- `FileRotation` itself does not have a runtime failure mode.

- A value of this type can still describe rotation behavior that only takes effect on targets where native file support exists.

### Notes

1. Use `file_rotation(...)` when you need a value of this type in code.

2. Use `native_files_supported()` or the target verification guidance when portability matters across non-native targets.
