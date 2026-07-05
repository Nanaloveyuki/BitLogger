---
name: file-rotation-i64
group: api
category: sink
update-time: 20260705
description: Create a native-focused large-file rotation policy using an Int64 byte threshold.
key-word:
    - file
    - rotation
    - i64
    - native
---

## File-rotation-i64

Create a size-based file rotation policy with an `Int64` byte threshold. This helper is the opt-in native-focused path for large-file rotation scenarios that exceed the default `Int`-based contract.

### Interface

```moonbit
pub fn file_rotation_i64(max_bytes : Int64, max_backups~ : Int = 1) -> FileRotation {}
```

#### input

- `max_bytes : Int64` - Maximum active file size threshold before rotation on the native-focused wide path.
- `max_backups : Int` - Number of retained backup files.

#### output

- `FileRotation` - Rotation policy value that preserves a native wide threshold while staying compatible with the existing file sink API surface.

### Explanation

- `max_bytes <= 0L` is normalized to `1L`.
- `max_backups <= 0` is normalized to `1`.
- Rotation is size-based only.
- This helper keeps the existing `FileRotation` type but stores an additional native wide threshold internally for runtime rotation checks.
- The helper is intended for native file backends and advanced large-file scenarios.
- JSON config export helpers preserve the exact threshold through `max_bytes_i64` while still exposing a compatibility `max_bytes` view.

### How to Use

#### When Need Native Large-file Rotation Thresholds

```moonbit
let sink = file_sink(
  "app.log",
  rotation=Some(file_rotation_i64(5368709120L, max_backups=4)),
)
```

In this example, the active rotation threshold is expressed with `Int64` rather than the default `Int` path.

#### When Need A Wide Policy Value First

```moonbit
let rotation = file_rotation_i64(3221225472L, max_backups=2)
let sink = file_sink("app.log", rotation=Some(rotation))
```

In this example, the wide threshold policy is assembled separately and then reused.

### Error Case

- If `max_bytes` is non-positive, it is clamped to `1L`.
- This API does not make non-native targets gain real file support; callers should still use `native_files_supported()` when portability matters.

### Notes

1. This API is additive and does not replace the default `file_rotation(...)` contract.
2. Prefer the default `Int` path unless a native large-file threshold is actually required.
3. String-based JSON roundtrip uses `max_bytes_i64` for the exact threshold and keeps `max_bytes` as the compatibility field.
4. This helper is designed for advanced use and target-aware code.
