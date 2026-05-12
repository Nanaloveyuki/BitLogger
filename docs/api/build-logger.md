---
name: build-logger
group: api
category: config
update-time: 20260512
description: Build a configured runtime logger from a LoggerConfig while preserving queue and file control helpers.
key-word:
    - logger
    - config
    - runtime
    - public
---

## Build-logger

Build a `ConfiguredLogger` from `LoggerConfig`. This is the main config-to-runtime bridge for synchronous logging and is the builder used before async wrapping in config-driven async flows.

### Interface

```moonbit
pub fn build_logger(config : LoggerConfig) -> ConfiguredLogger {}
```

#### input

- `config : LoggerConfig` - Fully assembled logger config including level, target, timestamp, sink, and optional queue wrapper.

#### output

- `ConfiguredLogger` - A runtime logger backed by `RuntimeSink`, with queue and file control helpers preserved.

### Explanation

Detailed rules explaining key parameters and behaviors

- `build_logger(...)` constructs the runtime sink shape based on `SinkConfig` and optional queue wrapper.
- The returned logger still supports normal logging methods because `ConfiguredLogger` is `Logger[RuntimeSink]`.
- Queue metrics and file controls remain available through forwarding helpers on the configured logger.
- This API is deterministic and data-driven, making it suitable for bootstrapping from parsed config.

### How to Use

Here are some specific examples provided.

#### When Need Structured Config-first Bootstrapping

When config is already assembled as typed values:
```moonbit
let logger = build_logger(
  LoggerConfig::new(
    min_level=Level::Info,
    target="svc",
    sink=SinkConfig::new(kind=SinkKind::TextConsole),
  ),
)
```

In this example, no JSON parsing is required because config objects were built directly.

And the runtime logger is ready immediately.

#### When Need Config-built Queue Or File Runtime Helpers

When the sink shape comes from config but runtime controls still matter:
```moonbit
let logger = build_logger(config)
ignore(logger.pending_count())
ignore(logger.file_runtime_state())
```

In this example, config-driven construction does not remove observability or control helpers.

### Error Case

e.g.:
- If config contains a file sink on a non-native backend, callers must still respect backend capability behavior.

- If queue is not configured, queue-related counters simply reflect the non-queued runtime shape.

### Notes

Notes are here.

1. Use this API when config is already typed as `LoggerConfig`.

2. Use `parse_and_build_logger(...)` when the starting point is raw JSON text.

3. `ConfiguredLogger` is still a logger, not a separate opaque runtime object.

4. This API is the sync runtime builder paired with `build_async_logger(...)` for async use cases.
