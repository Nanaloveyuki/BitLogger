---
name: build-async-logger
group: api
category: async
update-time: 20260614
description: Build an async logger from combined logger and async config with a distinct async runtime sink wrapper.
key-word:
    - async
    - config
    - builder
    - public
---

## Build-async-logger

Build an async logger directly from `AsyncLoggerBuildConfig`. This is the config-driven async entry point that bridges synchronous logger config, sink creation, and async queue setup in one call.

### Interface

```moonbit
pub fn build_async_logger(config : AsyncLoggerBuildConfig) -> AsyncLogger[AsyncRuntimeSink] {}
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined synchronous logger config plus async queue/flush config.

#### output

- `AsyncLogger[AsyncRuntimeSink]` - A config-built async logger whose async runtime wrapper delegates controls to shared configured sink state.

### Explanation

Detailed rules explaining key parameters and behaviors

- The `logger` section is built through the same config machinery used by synchronous configured loggers.
- That means `LoggerConfig.sink` and the optional synchronous `LoggerConfig.queue` are applied before the async layer is added.
- The resulting async logger inherits `min_level`, `target`, and timestamp behavior from the built synchronous logger.
- File, formatter, and any configured synchronous queue choices all come from config rather than direct code-side sink wiring.
- The returned sink type is `AsyncRuntimeSink`, which wraps the sync-configured runtime state. Its async file writes and flushes use the async filesystem backend.
- `build_async_logger(...)` returns `AsyncLogger[AsyncRuntimeSink]`. `build_application_async_logger(...)` returns its `ApplicationAsyncLogger` alias, while `build_library_async_logger(...)` returns `LibraryAsyncLogger[AsyncRuntimeSink]`.
- The returned async logger also keeps ordinary target rules unchanged: `log(..., target=...)` can override the target for one call, while severity helpers such as `debug(...)`, `info(...)`, and `error(...)` continue to use the stored logger target unless a derived logger was created first with `with_target(...)` or `child(...)`.
- This path starts from the sync config builder, so it preserves runtime sink selection and optional sync queue decoration when `LoggerConfig.queue` is present.
- The sync config path selects a `RuntimeSink` variant, including queued variants when configured; `AsyncRuntimeSink` wraps that shared state and supplies async file writes and flushes.
- The async flush callback uses `AsyncRuntimeSink::flush_async()`, so `Batch` and `Shutdown` use the async file flush path for file-backed sinks.
- The returned logger exposes async state and sink-kind information through its async logger and `AsyncRuntimeSink` APIs.
- File-backed runtime helpers are provided by the returned `AsyncRuntimeSink`, not by an exposed root `RuntimeSink` value.
- Use `build_async_text_logger(...)` instead when you want the direct text-console async builder path with `FormattedConsoleSink` and without the sync runtime-sink construction layer.
- The `src-async` library is designed to compile on `native / llvm / js / wasm / wasm-gc`, but runtime mode differs by backend.
- Current local release-facing verification is explicit for `native / js / wasm / wasm-gc`.
- `llvm` remains experimental and did not complete local verification in this environment.
- On non-native targets, the async library still compiles and exposes the same public surface through compatibility-mode behavior rather than native background-worker semantics.

### How to Use

Here are some specific examples provided.

#### When Need Fully Config-driven Async Bootstrapping

When your application should build async logging entirely from configuration:
```moonbit
let config = parse_async_logger_build_config_text(raw) catch {
  err => return
}
let logger = build_async_logger(config)
```

In this example, parsing and async runtime wiring are separated cleanly.

And the returned logger can immediately be started with `run()`.

#### When Need A Per-call Target Override After Typed Async Build

When typed async config should still build a logger that supports a one-call target override:
```moonbit
let logger = build_async_logger(config)
logger.log(@bitlogger.Level::Error, "boom", target="svc.audit")
```

In this example, the emitted record uses `svc.audit` for that call.

And later `debug(...)`, `info(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

#### When Need Runtime Sink Features After Async Build

When the sink shape is configured but runtime features still matter:
```moonbit
let logger = build_async_logger(config)
println(stringify_async_logger_state(logger.state(), pretty=true))
```

In this example, the built async logger remains introspectable even though construction was config-driven.

Configured synchronous runtime state and controls are preserved inside the returned `AsyncRuntimeSink` wrapper.

And if `AsyncFlushPolicy::Batch` or `Shutdown` is configured, this builder uses the wrapper's async file flush path rather than the default no-op callback used by the text-specific builder line.

### Error Case

e.g.:
- If the config text was invalid, error handling should happen earlier in `parse_async_logger_build_config_text(...)`.

- If the configured sink shape is unsupported for a specific capability, the resulting runtime behavior follows the existing sink/runtime rules rather than inventing a separate builder-only failure model.

- If callers depend on queued runtime-sink helpers or file-backed runtime helpers, this builder preserves them through the returned `AsyncRuntimeSink` wrapper rather than exposing a root `RuntimeSink`.

- If callers depend on the exact sink variant, `AsyncRuntimeSink::kind()` reports the sync-first sink selection made from the logger config, including any configured sync queue wrapper.

- If callers need the text-console path where `Batch` and `Shutdown` keep the default no-op flush callback, `build_async_text_logger(...)` is the different builder contract; this runtime-sink path wires `AsyncRuntimeSink::flush_async()` for async file flushing.

### Notes

1. Prefer this API when applications externalize both sync sink choice and async queue behavior.

2. Use `async_logger(...)` directly when you want explicit code-defined sink wiring.

3. Library portability is broader than example portability: a runnable `async fn main` example may still be target-limited even when the async library itself compiles for that backend.

4. See [target-verification.md](./target-verification.md) for the current verification boundary.

5. If the next boundary is library-facing rather than application-facing, build here and then narrow with `build_library_async_logger(...)` instead of documenting the broader runtime helper surface directly.
