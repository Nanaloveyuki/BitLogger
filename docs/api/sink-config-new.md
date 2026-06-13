---
name: sink-config-new
group: api
category: config
update-time: 20260613
description: Construct a SinkConfig value for config-driven logger sink selection.
key-word:
    - sink
    - config
    - constructor
    - public
---

## Sink-config-new

Construct a `SinkConfig` value for config-driven logger assembly. This constructor stores sink shape and sink-specific settings as typed data for later runtime building.

### Interface

```moonbit
pub fn SinkConfig::new(
  kind~ : SinkKind = SinkKind::Console,
  path~ : String = "",
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> SinkConfig {
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

- The constructor stores the supplied sink-shape and file-specific fields directly.
- `kind` defaults to `SinkKind::Console`.
- `text_formatter` defaults to `default_text_formatter_config()` so text-oriented sink config always has a formatter config available.
- File-only options are stored even though only `kind=File` actually consumes them at runtime.

### How to Use

Here are some specific examples provided.

#### When Build A Text Console Config

When runtime output should be text-formatted through config data:
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

1. This constructor builds sink-shape configuration, not the runtime sink itself.

2. Use `sink_config_to_json(...)` and `stringify_sink_config(...)` for export.
