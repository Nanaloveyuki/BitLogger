---
name: build-application-logger
group: api
category: facade
update-time: 20260520
description: Build the application-facing configured logger facade from a LoggerConfig.
key-word:
    - application
    - facade
    - logger
    - public
---

## Build-application-logger

Build an `ApplicationLogger` from `LoggerConfig`. This facade is the application-oriented sync entry point and currently aliases the configured runtime logger shape returned by `build_logger(...)`.

### Interface

```moonbit
pub fn build_application_logger(config : LoggerConfig) -> ApplicationLogger {
```

#### input

- `config : LoggerConfig` - Fully assembled sync logger config.

#### output

- `ApplicationLogger` - Application-facing configured runtime logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to `build_logger(...)`.
- The returned value keeps the same public logging, queue, and file runtime helper surface as `ConfiguredLogger`.
- Use this facade when application boot code wants an app-specific entry name without exposing lower-level builder naming in its own code.

### How to Use

Here are some specific examples provided.

#### When Need An App-level Sync Builder Entry

When boot code assembles config values before runtime construction:
```moonbit
let logger = build_application_logger(
  LoggerConfig::new(target="app", sink=SinkConfig::new(kind=SinkKind::Console)),
)
```

In this example, the application facade builds the same configured runtime logger shape as `build_logger(...)`.

### Error Case

e.g.:
- If the config uses file output on a backend without native file support, backend runtime limitations still apply after construction.

- If queueing is not configured, queue helper values simply reflect the non-queued runtime shape.

### Notes

1. This is a facade API, not a separate runtime implementation.

2. Use `parse_and_build_application_logger(...)` when starting from JSON text.
