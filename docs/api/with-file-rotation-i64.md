---
name: with-file-rotation-i64
group: api
category: config
update-time: 20260705
description: Add or replace native-focused Int64 file rotation on an existing file logger config preset.
key-word:
    - preset
    - file
    - rotation
    - i64
---

## With-file-rotation-i64

Add or replace a size-based file rotation policy with an `Int64` byte threshold on an existing `LoggerConfig`. This helper is the additive native-focused counterpart to `with_file_rotation(...)` for large-file rotation thresholds.

### Interface

```moonbit
pub fn with_file_rotation_i64(
  config : LoggerConfig,
  max_bytes : Int64,
  max_backups~ : Int = 1,
) -> LoggerConfig {
```

#### input

- `config : LoggerConfig` - Base logger config to inspect and possibly update.
- `max_bytes : Int64` - Native-focused wide file size threshold.
- `max_backups : Int` - Number of rotated backup files to retain.

#### output

- `LoggerConfig` - Updated file config with a wide rotation policy, or the original config unchanged when the sink is not file-based.

### Explanation

- `with_file_rotation_i64(...)` only applies to file presets or other configs whose `sink.kind=SinkKind::File`.
- If the input config is not file-based, the helper returns the config unchanged.
- When the input config is file-based, the helper preserves all existing config fields while replacing `sink.rotation` with a wide native-focused policy.
- Rotation policy creation follows `file_rotation_i64(...)` normalization rules.
- When the resulting config is exported to JSON, the nested rotation object preserves the exact threshold through `max_bytes_i64` and keeps `max_bytes` as the compatibility view.

### How to Use

#### When Need A Wide Threshold On A File Preset

```moonbit
let config = with_file_rotation_i64(file("service.log"), 4294967296L, max_backups=3)
```

In this example, the file preset gains an `Int64` rotation threshold.

#### When Compose Queue And Wide Rotation Together

```moonbit
let config = with_file_rotation_i64(
  with_queue(file("service.log"), max_pending=32),
  3221225472L,
  max_backups=2,
)
```

In this example, queue settings are preserved while a wide native-focused rotation policy is added.

### Error Case

- If the input config is not file-based, no error is raised and the config is returned unchanged.
- If `max_bytes` is non-positive, normalization behavior follows `file_rotation_i64(...)`.

### Notes

1. This helper is additive and does not replace `with_file_rotation(...)`.
2. Prefer the default helper unless the file size threshold must exceed the standard `Int` contract.
3. JSON roundtrip preserves the exact wide threshold through `max_bytes_i64`.
4. This helper is intended for advanced, native-aware configuration flows.
