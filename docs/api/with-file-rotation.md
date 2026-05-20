---
name: with-file-rotation
group: api
category: config
update-time: 20260520
description: Add or replace size-based file rotation on an existing file logger config preset.
key-word:
    - preset
    - file
    - rotation
    - public
---

## With-file-rotation

Add or replace a size-based file rotation policy on an existing `LoggerConfig`. This helper is intentionally narrow: it only mutates configs whose sink kind is `File` and leaves every non-file config unchanged.

### Interface

```moonbit
pub fn with_file_rotation(
  config : LoggerConfig,
  max_bytes : Int,
  max_backups~ : Int = 1,
) -> LoggerConfig {
```

#### input

- `config : LoggerConfig` - Base logger config to inspect and possibly update.
- `max_bytes : Int` - Maximum active file size before rotation.
- `max_backups : Int` - Number of rotated backup files to retain.

#### output

- `LoggerConfig` - Updated file config with rotation, or the original config unchanged when the sink is not file-based.

### Explanation

Detailed rules explaining key parameters and behaviors

- `with_file_rotation(...)` only applies to file presets or other configs whose `sink.kind=SinkKind::File`.
- If the input config is not file-based, the helper returns the config unchanged.
- When the input config is file-based, the helper preserves `min_level`, `target`, `timestamp`, file path, append mode, auto-flush, formatter, and queue settings while replacing `sink.rotation`.
- Rotation policy creation follows `file_rotation(...)` normalization rules for `max_bytes` and `max_backups`.

### How to Use

Here are some specific examples provided.

#### When Need To Extend A File Preset

When file rotation should be added after the base preset is assembled:
```moonbit
let config = with_file_rotation(file("service.log"), 1024 * 1024, max_backups=3)
```

In this example, the file preset gains a size-based rotation policy.

And all other file sink settings remain unchanged.

#### When Compose Queue And Rotation Together

When the file logger also needs bounded queueing:
```moonbit
let config = with_file_rotation(
  with_queue(file("service.log"), max_pending=32),
  4096,
  max_backups=2,
)
```

In this example, queue settings are preserved while file rotation is added.

### Error Case

e.g.:
- If the input config is not file-based, no error is raised and the config is returned unchanged.

- If `max_bytes` or `max_backups` are non-positive, normalization behavior follows `file_rotation(...)`.

### Notes

1. This helper is a no-op for `console(...)`, `json_console(...)`, and `text_console(...)` presets.

2. Use `file(...)` when you need to provide the initial file path, because `with_file_rotation(...)` does not create a file sink from a non-file config.
