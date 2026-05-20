---
name: text-console
group: api
category: config
update-time: 20260520
description: Create a logger config preset for the built-in text console sink with formatter settings.
key-word:
    - preset
    - text
    - console
    - public
---

## Text-console

Create a `LoggerConfig` preset for text-formatted console output. This helper bundles `SinkKind::TextConsole` together with a `TextFormatterConfig` so config-driven logger assembly can control text rendering without manual `SinkConfig::new(...)` calls.

### Interface

```moonbit
pub fn text_console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig {
```

#### input

- `min_level : Level` - Minimum enabled level for the preset.
- `target : String` - Default target stored in the returned config.
- `timestamp : Bool` - Whether the built logger should emit timestamps.
- `text_formatter : TextFormatterConfig` - Formatter config used by the text console sink.

#### output

- `LoggerConfig` - Config using `SinkKind::TextConsole` with the supplied formatter and no queue wrapper by default.

### Explanation

Detailed rules explaining key parameters and behaviors

- This preset always returns `sink.kind=SinkKind::TextConsole`.
- `text_formatter` is copied into `config.sink.text_formatter`.
- `queue=None` by default, so buffering remains opt-in through `with_queue(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Customized Human-readable Console Output

When console logs should use a specific separator or timestamp display:
```moonbit
let formatter = TextFormatterConfig::new(show_timestamp=false, separator=" | ")
let config = text_console(target="worker", text_formatter=formatter)
```

In this example, the text console sink uses the supplied formatter config.

And the preset stays fully compatible with later `build_logger(...)` assembly.

### Error Case

e.g.:
- If `target` is empty, the preset still returns a valid config.

- If you later apply `with_file_rotation(...)`, the config stays unchanged because this is not a file sink preset.

### Notes

1. Use this preset instead of `console(...)` when text formatting must be configured explicitly.

2. File-only settings such as `path` and `rotation` are not part of this preset.
