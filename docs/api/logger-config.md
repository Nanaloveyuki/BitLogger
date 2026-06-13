---
name: logger-config
group: api
category: config
update-time: 20260512
description: Create the main logger configuration object used by config-driven runtime logger assembly.
key-word:
    - logger
    - config
    - runtime
    - public
---

## Logger-config

Create a `LoggerConfig` value describing level, target, timestamp behavior, sink shape, and optional queue wrapping. This is the main typed configuration object consumed by `build_logger(...)` and async build helpers.

### Interface

```moonbit
pub fn LoggerConfig::new(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  sink~ : SinkConfig = default_sink_config(),
  queue~ : QueueConfig? = None,
) -> LoggerConfig {}
```

#### input

- `min_level : Level` - Global level gate.
- `target : String` - Default target namespace.
- `timestamp : Bool` - Whether the built logger should emit timestamps.
- `sink : SinkConfig` - Configured sink shape.
- `queue : QueueConfig?` - Optional synchronous queue wrapper.

#### output

- `LoggerConfig` - Main logger configuration object.

### Explanation

Detailed rules explaining key parameters and behaviors

- `LoggerConfig` is the top-level typed representation for synchronous config-driven logging.
- `sink` describes the final sink shape before optional queue wrapping.
- `queue=None` means no configured synchronous queue layer.
- This same type is embedded into async build config as the synchronous sink/runtime portion.
- `build_logger(...)` consumes this value directly by building the base runtime sink from `sink`, optionally wrapping it with `queue`, and then applying `min_level`, `target`, and `timestamp` onto the resulting `Logger[RuntimeSink]`.
- `build_async_logger(...)` reuses this same synchronous config path before adding the outer async layer, while `build_async_text_logger(...)` only uses the selected text-oriented fields instead of the full sync runtime-sink build path.

### How to Use

Here are some specific examples provided.

#### When Build Config In Code Instead Of JSON

When application bootstrapping prefers typed config values:
```moonbit
let config = LoggerConfig::new(
  min_level=Level::Warn,
  target="svc",
  timestamp=true,
  sink=SinkConfig::new(kind=SinkKind::TextConsole),
)
```

In this example, the logger configuration is explicit and strongly typed.

#### When Prepare Config For A Later Builder

When config is assembled in one place and built later:
```moonbit
let config = LoggerConfig::new(queue=Some(QueueConfig::new(16)))
let logger = build_logger(config)
```

In this example, the config object becomes the handoff boundary between assembly and runtime construction.

### Error Case

e.g.:
- If `sink` describes a capability-limited backend shape such as native file output on a non-native target, later runtime behavior still follows backend support rules.

- If `target` is empty, the configuration is still valid.

### Notes

1. This is the core typed config object for sync logger assembly.

2. Prefer this API when config is generated in code rather than parsed from text.

3. Use `default_logger_config()` when callers want the same field defaults as the parser and runtime helpers without spelling them out manually.
