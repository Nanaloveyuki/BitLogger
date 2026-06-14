---
name: build-library-async-text-logger
group: api
category: facade
update-time: 20260614
description: Build the library-facing text-console async logger facade from an AsyncLoggerBuildConfig using the concrete text-console builder path.
key-word:
    - library
    - async
    - text
    - public
---

## Build-library-async-text-logger

Build a `LibraryAsyncLogger[FormattedConsoleSink]` from `AsyncLoggerBuildConfig`. This facade is the library-oriented async builder for the concrete text-console sink shape returned by `build_async_text_logger(...)`.

### Interface

```moonbit
pub fn build_library_async_text_logger(
  config : AsyncLoggerBuildConfig,
) -> LibraryAsyncLogger[FormattedConsoleSink] {
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined sync logger config and async queue/runtime config.

#### output

- `LibraryAsyncLogger[FormattedConsoleSink]` - Library-facing async logger backed by formatted console output.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to `build_async_text_logger(...)` and then narrows the result to `LibraryAsyncLogger[@bitlogger.FormattedConsoleSink]`.
- It always produces a concrete `FormattedConsoleSink` from `config.logger.sink.text_formatter` instead of branching on sink kinds.
- That means even if `config.logger.sink.kind` says `Console`, `JsonConsole`, or `File`, this facade still follows the text-console path and uses only the configured `text_formatter` details.
- Unlike `build_library_async_logger(...)`, this facade does not go through the full synchronous configured-logger build path first.
- It uses the selected text-oriented `LoggerConfig` fields directly and therefore does not apply `LoggerConfig.queue` or preserve sync runtime sink controls.
- A sync queue configured on `LoggerConfig.queue` is therefore ignored by this builder instead of being preserved behind the wrapped text-console async logger.
- The returned facade wraps the same underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]` value that `build_async_text_logger(...)` would return directly, so `run()`, `shutdown()`, and queue or failure-state behavior are unchanged under the narrower public type.
- In the current direct text-builder coverage, unwrapping this facade yields the same async state snapshot, formatter behavior, queue counters, lifecycle flags, and later failure fields as calling `build_async_text_logger(config)` directly.
- The configured `flush_policy` is still carried by that underlying async logger, but this text-specific builder path does not provide the explicit sink flush callback used by `build_library_async_logger(...)` through `build_async_logger(...)`.
- As a result, `Batch` and `Shutdown` only invoke the default no-op async flush callback on this text-console path unless downstream code unwraps and adds different behavior elsewhere.
- The facade still preserves the underlying async target rules on its exposed write methods: `log(..., target=...)` can override the target for one call, while `info(...)`, `warn(...)`, and `error(...)` continue using the stored logger target unless the facade first derived another logger with `with_target(...)` or `child(...)`.
- Async state helpers such as `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, and failure-status inspection remain on the underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]`, not on the returned facade itself.
- `to_async_logger()` can recover the underlying full async logger if needed.
- Use this builder when the boundary should preserve the concrete text-console sink type while still hiding broader async inspection and helper APIs from downstream callers.

### How to Use

Here are some specific examples provided.

#### When Need A Narrow Async Text Logger For Libraries

When a library wants text-console async output and a narrower public type:
```moonbit
let logger = build_library_async_text_logger(
  AsyncLoggerBuildConfig::new(
    logger=text_console(target="lib.text.async"),
    async_config=AsyncLoggerConfig::new(max_pending=4),
  ),
)
```

In this example, the async text sink shape is preserved under the library facade.

And the chosen builder path matters more than `config.logger.sink.kind`: this facade still uses the text formatter directly because it always builds a `FormattedConsoleSink` before narrowing to `LibraryAsyncLogger[@bitlogger.FormattedConsoleSink]`.

#### When Need Async State Helpers After Library Text Construction

When library-facing text-console construction should still allow internal async inspection later:
```moonbit
let logger = build_library_async_text_logger(config)
let full = logger.to_async_logger()
ignore(full.pending_count())
```

In this example, the facade is unwrapped before using async state helpers.

#### When Need A Per-call Target Override Through The Library Async Text Builder Facade

When typed library async text config should still build a facade that allows a one-call target override without unwrapping first:
```moonbit
let logger = build_library_async_text_logger(config)
logger.log(@bitlogger.Level::Error, "boom", target="lib.text.audit")
```

In this example, the emitted record uses `lib.text.audit` for that call.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the facade's stored target unless code derives another facade first with `with_target(...)` or `child(...)`.

### Error Case

e.g.:
- If callers need sink-kind-driven branching such as JSON console or file-backed async output, they should use `build_library_async_logger(...)` instead.

- If the config carries file-oriented fields such as `path` only because `sink.kind` was set to `File`, this facade still ignores that sink-kind choice and does not create a file-backed async logger.

- If callers expect async state or idle-wait helpers directly on the returned facade, they must unwrap first with `to_async_logger()`.

- If callers need to inspect the actual formatter-backed async state after library-level `run()` or `shutdown()` calls, unwrapping exposes the same post-call counters and failure fields that the direct text builder would have produced.

- Normal async lifecycle expectations still apply if the logger is never run.

### Notes

1. This is the library-side counterpart to `build_application_text_async_logger(...)`.

2. It is most useful when a concrete text-console async sink type matters to the caller boundary.

3. Use `build_library_async_logger(...)` instead when the library-facing async type should keep the broader `RuntimeSink` build path, including sync queue application through `build_logger(config.logger)`.
