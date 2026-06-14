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

- `build_logger(...)` first constructs a base `RuntimeSink` from `config.sink`, then applies `config.queue` when present, and finally builds `Logger::new(...)` with `config.min_level`, `config.target`, and `config.timestamp`.
- The returned logger still supports normal logging methods because `ConfiguredLogger` is `Logger[RuntimeSink]`.
- The returned logger also keeps inherited logger target behavior such as `with_target(...)`, `child(...)`, and per-call `target=` overrides on `log(...)`.
- That means `log(..., target=...)` can override the target for one write, while severity helpers such as `info(...)`, `warn(...)`, and `error(...)` continue to use the stored logger target unless a derived logger was created first with `with_target(...)` or `child(...)`.
- Queue metrics and file controls remain available through forwarding helpers on the configured logger.
- `build_application_logger(...)` only re-exports this same configured runtime logger result under the `ApplicationLogger` alias, while `build_library_logger(...)` wraps the same result in `LibraryLogger[RuntimeSink]`.
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

And the runtime logger is ready immediately, with the same ordinary logger target semantics as any other `Logger` value.

#### When Need A Per-call Target Override After Typed Config Build

When typed config should still build a logger that supports a one-write target override:
```moonbit
let logger = build_logger(config)
logger.log(Level::Error, "boom", target="svc.audit")
```

In this example, the emitted record uses `svc.audit` for that write.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

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

1. Use this API when config is already typed as `LoggerConfig`.

2. Use `parse_and_build_logger(...)` when the starting point is raw JSON text.

3. Use the application or library facade builders only when the boundary name or exposed surface should differ; they do not change the underlying configured runtime logger pipeline built here.

