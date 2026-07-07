---
name: sink-kind
group: api
category: config
update-time: 20260707
description: Public sink kind enum re-exported from config_model for built-in sink selection.
key-word:
    - sink
    - config
    - alias
    - public
---

## Sink-kind

`SinkKind` is the public enum that selects which built-in sink shape a `SinkConfig` should build. On the root `src` facade, it is re-exported from `src/config_model`, so config builders, JSON parsers, and sink serialization helpers all use the same small set of variants.

### Interface

```moonbit
pub using @config_model { type SinkKind }
```

#### output

- `SinkKind` - Public sink selection enum with the variants `Console`, `JsonConsole`, `TextConsole`, and `File`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This root surface is a re-export, not the concrete owner definition.
- The concrete enum lives in `@config_model.SinkKind`, not in `@utils`.
- `SinkKind::Console` selects the basic text console sink.
- `SinkKind::JsonConsole` selects JSON line output.
- `SinkKind::TextConsole` selects text console output driven by `TextFormatterConfig`.
- `SinkKind::File` selects file-backed output and requires a non-empty `path` during config parsing.

### How to Use

Here are some specific examples provided.

#### When Need To Build A File Sink Through Config

When logger construction should be described entirely as config data:
```moonbit
let sink = SinkConfig::new(kind=SinkKind::File, path="app.log")
let config = LoggerConfig::new(sink=sink)
```

In this example, the selected enum variant controls which built-in sink builder will be used.

#### When Need Formatter-driven Console Output

When the config should request text console formatting instead of the default console sink:
```moonbit
let sink = SinkConfig::new(kind=SinkKind::TextConsole)
```

In this example, the enum value makes the config intent explicit.

### Error Case

e.g.:
- Unsupported sink kind text in parsed JSON raises `ConfigError`.

- `SinkKind::File` without a non-empty `path` is rejected during config parsing.

### Notes

1. This enum is for config-driven sink selection, not for direct handwritten sink composition.

2. Use concrete constructors such as `console_sink()` or `file_sink(...)` when building sinks in code instead of through `SinkConfig`.
