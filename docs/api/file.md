---
name: file
group: api
category: config
update-time: 20260520
description: Create a logger config preset for the built-in file sink with optional rotation and formatter settings.
key-word:
    - preset
    - file
    - rotation
    - public
---

## File

Create a `LoggerConfig` preset for the built-in file sink. This helper packages file path, append policy, auto-flush behavior, optional rotation, and text formatter settings into a single config object for runtime logger assembly.

### Interface

```moonbit
pub fn file(
  path : String,
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig raise ConfigError {
```

#### input

- `path : String` - Output file path for the file sink.
- `min_level : Level` - Minimum enabled level for the preset.
- `target : String` - Default target stored in the returned config.
- `timestamp : Bool` - Whether the built logger should emit timestamps.
- `append : Bool` - Whether file writes should append instead of truncate-on-open behavior.
- `auto_flush : Bool` - Whether writes should be flushed automatically.
- `rotation : FileRotation?` - Optional size-based file rotation policy.
- `text_formatter : TextFormatterConfig` - Formatter config used for file text rendering.

#### output

- `LoggerConfig` - Config using `SinkKind::File` and the supplied file-specific settings.

### Explanation

Detailed rules explaining key parameters and behaviors

- This preset always returns `sink.kind=SinkKind::File`.
- `path` must be non-empty.
- `rotation=None` leaves file rotation disabled until a rotation policy is provided directly or through `with_file_rotation(...)`.
- `queue=None` by default, so buffering is opt-in through `with_queue(...)`.

### How to Use

Here are some specific examples provided.

#### When Need A Config-driven File Logger

When application boot wants typed file logging config:
```moonbit
let config = file(
  "service.log",
  min_level=Level::Warn,
  append=true,
  auto_flush=true,
)
```

In this example, the returned config targets the built-in file sink.

And rotation remains disabled until configured.

#### When Need File Config With Rotation Prepared Up Front

When file retention should be included immediately:
```moonbit
let config = file(
  "service.log",
  rotation=Some(file_rotation(1024 * 1024, max_backups=3)),
)
```

In this example, the file preset carries both path and rotation policy.

### Error Case

e.g.:
- If `path` is empty, this preset raises `ConfigError::InvalidConfig("File sink requires non-empty path")`.

- If you need console output instead of file output, use a console preset because file-only settings are meaningful only for `SinkKind::File`.

### Notes

1. This is the only preset in this set that accepts file path and file rotation settings directly.

2. `with_file_rotation(...)` is designed to extend this preset or any other file-based `LoggerConfig`.
