---
name: build-application-async-logger
group: api
category: facade
update-time: 20260614
description: Build the application-facing runtime-sink async logger alias from an AsyncLoggerBuildConfig through the sync-first async builder path.
key-word:
    - application
    - async
    - facade
    - public
---

## Build-application-async-logger

Build an `ApplicationAsyncLogger` from `AsyncLoggerBuildConfig`. This is the application-facing runtime-sink async alias returned through `build_async_logger(...)`.

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
- Any optional synchronous queue layer and runtime-sink controls chosen by `build_logger(config.logger)` remain active under the returned logger.
- In particular, a sync queue configured on `LoggerConfig.queue` is preserved inside the wrapped `RuntimeSink` variant instead of being stripped away by the application alias.
- Because the result is only the `ApplicationAsyncLogger` alias over `AsyncLogger[@bitlogger.RuntimeSink]`, this builder does not hide any async helpers or introduce a wrapper layer.
- The broader async helper surface is therefore preserved and directly exposed on the returned alias rather than being rebuilt or hidden behind an unwrap step.
- The returned alias also keeps inherited async logger target behavior such as `with_target(...)`, `child(...)`, and per-call `target=` overrides on `log(...)`.
- The returned logger keeps the full async lifecycle and state helper surface directly, including helpers such as `run()`, `shutdown()`, `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, `has_failed()`, and `last_error()`.
- It also keeps the same queue counters, failure state, sink shape, and runtime-dependent post-close behavior as the underlying runtime-sink async logger.
- Because this facade delegates to `build_async_logger(...)`, `Batch` and `Shutdown` also keep the underlying runtime-sink flush wiring: the returned alias uses the built sink's real `flush()` path instead of the default no-op callback used by the text-specific builder line.
- In the current direct builder coverage, this alias matches `build_async_logger(config)` all the way through serialized state snapshots, runtime-sink variant choice, queue counters, lifecycle flags, and later failure fields after `run()` or `shutdown()`.
- File-backed runtime helpers on the returned `RuntimeSink` also stay aligned with the direct builder result instead of being hidden behind a separate application-layer wrapper.
- Use this alias-oriented builder when application code wants the standard runtime-sink async shape without narrowing the public surface.

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

And unlike `build_library_async_logger(...)`, no `to_async_logger()` unwrap is required to reach queue, lifecycle, or file-backed runtime helpers.

The returned value also keeps the ordinary async logger target semantics because the facade does not wrap or narrow the underlying `AsyncLogger[@bitlogger.RuntimeSink]`.

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

- If callers rely on file-backed runtime helpers, they should treat this builder as the same runtime-sink result as `build_async_logger(config)`, not as a reduced alias with different helper behavior.

- If callers specifically want the text-console async path where `Batch` and `Shutdown` keep the default no-op flush callback, `build_application_text_async_logger(...)` is the different contract; this runtime-sink alias preserves the real sink `flush()` behavior from `build_async_logger(...)`.

### Notes

1. This is a facade over the existing async runtime logger builder.

2. Use `parse_and_build_application_async_logger(...)` when starting from JSON text.

3. Use `build_application_text_async_logger(...)` instead when callers should keep the concrete text-console sink type and the direct text-builder path.

4. Use `build_library_async_logger(...)` instead when a library boundary should narrow the exposed async surface.
