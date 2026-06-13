---
name: sink-config
group: api
category: config
update-time: 20260512
description: Create a typed sink configuration for config-driven logger assembly.
key-word:
    - sink
    - config
    - file
    - public
---

## Sink-config

Create a `SinkConfig` value describing the concrete sink shape used by config-driven logger builders. This API selects between console, JSON console, text console, and file-based sink assembly while also carrying sink-specific settings.

### Interface

```moonbit
pub fn SinkConfig::new(
  kind~ : SinkKind = SinkKind::Console,
  path~ : String = "",
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> SinkConfig {}
```

#### input

- `kind : SinkKind` - Sink variant such as `Console`, `JsonConsole`, `TextConsole`, or `File`.
- `path : String` - File path used when `kind=File`.
- `append : Bool` - File append policy.
- `auto_flush : Bool` - File auto-flush policy.
- `rotation : FileRotation?` - Optional file rotation policy.
- `text_formatter : TextFormatterConfig` - Formatter config used by text console or file text rendering.

#### output

- `SinkConfig` - Typed sink configuration used by `LoggerConfig`.

### Explanation

Detailed rules explaining key parameters and behaviors

- One config type is used for all supported built-in sink shapes.
- File-only options are stored even though only `kind=File` actually consumes them.
- Text formatter config is always present, making text-driven sink configuration simpler and stable.
- This type is consumed by `build_logger(...)` and `parse_and_build_logger(...)`.
- `build_logger(...)` maps `kind` to the concrete base runtime sink: `Console`, `JsonConsole`, and `TextConsole` build their matching console sink variants, while `File` builds a file sink using `path`, `append`, `auto_flush`, `rotation`, and text formatting derived from `text_formatter`.
- The constructor itself does not reject an empty file path, but JSON parsing does: `parse_logger_config_text(...)` raises `ConfigError` when `kind=File` and `path` is empty.
- The same `text_formatter` field is also reused by the direct async text-builder path when `build_async_text_logger(...)` or its facade variants create `FormattedConsoleSink` values.

### How to Use

Here are some specific examples provided.

#### When Build A Text Console Config

When runtime output should be text-formatted through config:
```moonbit
let sink = SinkConfig::new(
  kind=SinkKind::TextConsole,
  text_formatter=TextFormatterConfig::new(show_timestamp=false),
)
```

In this example, the formatter choice is embedded directly into sink config.

#### When Build A File Sink Config

When file behavior should be data-driven:
```moonbit
let sink = SinkConfig::new(
  kind=SinkKind::File,
  path="app.log",
  rotation=Some(file_rotation(1024, max_backups=2)),
)
```

In this example, file location and retention policy are part of the same sink definition.

### Error Case

e.g.:
- If `kind=File` but `path` is empty, the config object is still constructible, but runtime usage should be evaluated carefully.

- If `kind` is non-file, file-specific options may simply be unused by the runtime builder.

### Notes

1. This type is sink-shape configuration, not the runtime sink itself.

2. Use `sink_config_to_json(...)` and `stringify_sink_config(...)` for export.

3. Use `default_sink_config()` when callers want the standard console default without spelling out every sink field.
