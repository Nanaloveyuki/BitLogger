---
name: build-application-async-logger
group: api
category: facade
update-time: 20260614
description: Build the application-facing async runtime-sink async logger alias from an AsyncLoggerBuildConfig through the sync-first async builder path.
key-word:
    - application
    - async
    - facade
    - public
---

## Build-application-async-logger

Build an `ApplicationAsyncLogger` from `AsyncLoggerBuildConfig`. This is the application-facing async runtime-sink async alias returned through `build_async_logger(...)`.

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

- This API delegates to `build_async_logger(...)` directly.
- That means the embedded `LoggerConfig` is built first through the normal synchronous config path before the outer async layer is applied.
- Any optional synchronous queue layer and runtime controls chosen by the sync config path remain active inside the returned `AsyncRuntimeSink` wrapper.
- In particular, `LoggerConfig.queue` is applied to the sync-configured runtime sink before `AsyncRuntimeSink` wraps that shared state.
- The broader async helper surface is therefore preserved and directly exposed on the returned alias rather than being rebuilt or hidden behind an unwrap step.
- The returned alias also keeps inherited async logger target behavior such as `with_target(...)`, `child(...)`, and per-call `target=` overrides on `log(...)`.
- The returned logger keeps the full async lifecycle and state helper surface directly, including helpers such as `run()`, `shutdown()`, `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, `has_failed()`, and `last_error()`.
- It also keeps the same queue counters, failure state, sink shape, and runtime-dependent post-close behavior as the underlying async logger.
- Because this facade delegates to `build_async_logger(...)`, `Batch` and `Shutdown` use the async runtime wrapper's async flush path for file-backed sinks.
- In the current direct builder coverage, this alias matches `build_async_logger(config)` through serialized state snapshots, async sink-kind choice, queue counters, lifecycle flags, and later failure fields after `run()` or `shutdown()`.
- File-backed runtime helpers are exposed by the returned `AsyncRuntimeSink` through this alias; the alias does not expose a root `RuntimeSink` value.

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

Configured synchronous runtime controls remain available through the returned `AsyncRuntimeSink`-backed async logger.

And unlike `build_library_async_logger(...)`, no `to_async_logger()` unwrap is required to reach async queue and lifecycle helpers or the `AsyncRuntimeSink` file controls.

The returned value also keeps the ordinary async logger target semantics because the facade is an alias of `AsyncLogger[AsyncRuntimeSink]`, not a narrowing wrapper.

#### When Need Async State Helpers Immediately After App Construction

When application code should keep the ordinary async helper surface directly:
```moonbit
let logger = build_application_async_logger(config)
ignore(logger.pending_count())
ignore(logger.state())
```

In this example, the application alias exposes async state helpers directly because no narrowing wrapper is added.

### Error Case

e.g.:
- If file output is selected on a backend without native file support, backend behavior still applies when the worker drains records.

- If the logger is never `run()`, enqueue behavior and lifecycle state still follow the normal async logger rules.

- If callers rely on file-backed runtime helpers, they are available through the returned `AsyncRuntimeSink` wrapper, matching `build_async_logger(config)`.

- If callers specifically want the text-console async path where `Batch` and `Shutdown` keep the default no-op flush callback, `build_application_text_async_logger(...)` is the different contract; this runtime-sink alias uses the async file flush path from `build_async_logger(...)`.

### Notes

1. This is a facade over the existing async runtime logger builder.

2. Use `parse_and_build_application_async_logger(...)` when starting from JSON text.

3. Use `build_application_text_async_logger(...)` instead when callers should keep the concrete text-console sink type and the direct text-builder path.

4. Use `build_library_async_logger(...)` instead when a library boundary should narrow the exposed async surface.
