---
name: build-async-logger
group: api
category: async
update-time: 20260614
description: Build an async logger from combined logger and async config by first building the sync runtime logger and then wrapping its sink in the async layer.
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
pub fn build_async_logger(config : AsyncLoggerBuildConfig) -> AsyncLogger[@bitlogger.RuntimeSink] {}
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined synchronous logger config plus async queue/flush config.

#### output

- `AsyncLogger[RuntimeSink]` - A config-built async logger with runtime sink control preserved.

### Explanation

Detailed rules explaining key parameters and behaviors

- The `logger` section is built through the same config machinery used by synchronous configured loggers.
- That means `LoggerConfig.sink` and the optional synchronous `LoggerConfig.queue` are applied before the async layer is added.
- The resulting async logger inherits `min_level`, `target`, and timestamp behavior from the built synchronous logger.
- File, formatter, and any configured synchronous queue choices all come from config rather than direct code-side sink wiring.
- The returned sink type is `RuntimeSink`, which keeps configured control helpers available where relevant.
- This builder returns the underlying `AsyncLogger[@bitlogger.RuntimeSink]` value directly. `build_application_async_logger(...)` only re-exports the same result under the `ApplicationAsyncLogger` alias, while `build_library_async_logger(...)` wraps the same result in `LibraryAsyncLogger[@bitlogger.RuntimeSink]`.
- Because this path starts from `build_logger(config.logger)`, it preserves the broader runtime-sink build path, including sync-side queue decoration when `LoggerConfig.queue` is present.
- In the current direct builder coverage, the returned logger exposes the expected serialized async state snapshot, runtime-sink variant choice, queue counters, lifecycle flags, and later failure fields after `run()` or `shutdown()`.
- File-backed runtime helpers also stay directly available on the returned `RuntimeSink` with the same behavior later observed through the application and library facade equivalence tests.
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

#### When Need Runtime Sink Features After Async Build

When the sink shape is configured but runtime features still matter:
```moonbit
let logger = build_async_logger(config)
println(stringify_async_logger_state(logger.state(), pretty=true))
```

In this example, the built async logger remains introspectable even though construction was config-driven.

And any configured synchronous runtime sink controls are preserved inside the returned `RuntimeSink`.

### Error Case

e.g.:
- If the config text was invalid, error handling should happen earlier in `parse_async_logger_build_config_text(...)`.

- If the configured sink shape is unsupported for a specific capability, the resulting runtime behavior follows the existing sink/runtime rules rather than inventing a separate builder-only failure model.

- If callers depend on queued runtime-sink helpers or file-backed runtime helpers, this builder is the direct API that preserves them rather than a reduced facade path.

### Notes

1. Prefer this API when applications externalize both sync sink choice and async queue behavior.

2. Use `async_logger(...)` directly when you want explicit code-defined sink wiring.

3. Library portability is broader than example portability: a runnable `async fn main` example may still be target-limited even when the async library itself compiles for that backend.

4. See [target-verification.md](./target-verification.md) for the current verification boundary.

5. If the next boundary is library-facing rather than application-facing, build here and then narrow with `build_library_async_logger(...)` instead of documenting the broader runtime helper surface directly.
