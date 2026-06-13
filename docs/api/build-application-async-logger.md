---
name: build-application-async-logger
group: api
category: facade
update-time: 20260614
description: Build the application-facing async logger facade from an AsyncLoggerBuildConfig through the sync-first async builder path.
key-word:
    - application
    - async
    - facade
    - public
---

## Build-application-async-logger

Build an `ApplicationAsyncLogger` from `AsyncLoggerBuildConfig`. This is the application-facing async facade over `build_async_logger(...)`.

### Interface

```moonbit
pub fn build_application_async_logger(
  config : AsyncLoggerBuildConfig,
) -> ApplicationAsyncLogger {
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined sync logger config and async queue/runtime config.

#### output

- `ApplicationAsyncLogger` - Application-facing async runtime logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to `build_async_logger(...)`.
- That means the embedded `LoggerConfig` is built first through the normal synchronous config path before the outer async layer is applied.
- The returned logger keeps the standard async lifecycle and state helper surface.
- Use this facade when application code wants a dedicated async app-level entry point.

### How to Use

Here are some specific examples provided.

#### When Need Config-driven App Async Boot

When both sync sink shape and async queue policy are assembled as typed config:
```moonbit
let logger = build_application_async_logger(
  AsyncLoggerBuildConfig::new(
    logger=LoggerConfig::new(target="app.async"),
    async_config=AsyncLoggerConfig::new(max_pending=8),
  ),
)
```

In this example, the app-facing async facade is built directly from typed config.

And any configured synchronous runtime sink controls remain available through the returned `RuntimeSink`-backed async logger.

### Error Case

e.g.:
- If file output is selected on a backend without native file support, backend behavior still applies when the worker drains records.

- If the logger is never `run()`, enqueue behavior and lifecycle state still follow the normal async logger rules.

### Notes

1. This is a facade over the existing async runtime logger builder.

2. Use `parse_and_build_application_async_logger(...)` when starting from JSON text.
