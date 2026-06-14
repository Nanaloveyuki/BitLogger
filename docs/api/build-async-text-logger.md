---
name: build-async-text-logger
group: api
category: async
update-time: 20260614
description: Build an async logger with a concrete text-console sink from combined logger and async config, using only the selected text-oriented LoggerConfig fields instead of the full sync build path.
key-word:
    - async
    - text
    - builder
    - public
---

## Build-async-text-logger

Build an async logger directly from `AsyncLoggerBuildConfig`, but keep the concrete sink type as `FormattedConsoleSink` instead of the broader runtime sink wrapper. This helper is the text-console specific counterpart to `build_async_logger(...)`.

### Interface

```moonbit
pub fn build_async_text_logger(config : AsyncLoggerBuildConfig) -> AsyncLogger[@bitlogger.FormattedConsoleSink] {
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined sync logger config plus async queue and flush config.

#### output

- `AsyncLogger[FormattedConsoleSink]` - Config-built async logger backed by a concrete text console sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This builder converts `config.logger.sink.text_formatter` into a runtime `TextFormatter` and wires it into `text_console_sink(...)`.
- It always constructs a `FormattedConsoleSink` directly instead of branching on `config.logger.sink.kind`.
- The returned logger inherits `min_level`, `target`, and timestamp behavior from `config.logger`.
- Unlike `build_async_logger(...)`, this helper does not run the full synchronous `build_logger(config.logger)` path first.
- That means it uses `config.logger.sink.text_formatter`, `min_level`, `target`, and `timestamp` directly, but it does not apply `LoggerConfig.queue` or preserve other sync runtime sink controls.
- This builder returns the underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]` value directly. `build_application_text_async_logger(...)` only re-exports that same result under the `ApplicationTextAsyncLogger` alias, while `build_library_async_text_logger(...)` wraps the same result in `LibraryAsyncLogger[@bitlogger.FormattedConsoleSink]`.
- The returned async logger also keeps ordinary target rules unchanged: `log(..., target=...)` can override the target for one call, while severity helpers such as `debug(...)`, `info(...)`, `warn(...)`, and `error(...)` continue to use the stored logger target unless a derived logger was created first with `with_target(...)` or `child(...)`.
- In the current direct text-builder coverage, the returned logger exposes the expected serialized async state snapshot, formatter behavior, queue counters, lifecycle flags, and later failure fields after worker execution.
- The async `flush_policy` still comes from `config.async_config`, but this text-specific builder does not supply the explicit `flush=fn(sink) { sink.flush() }` callback used by `build_async_logger(...)`.
- In practice, `Batch` and `Shutdown` therefore only trigger the default no-op async flush callback on this path, while each record write still follows whatever immediate behavior `FormattedConsoleSink` already has on its own.
- This helper is best suited to text-console output paths where callers want the concrete formatted sink type instead of `RuntimeSink`.
- This async text path follows the same target story as the broader async library: `native / js / wasm / wasm-gc` have stronger local verification, while `llvm` remains experimental and locally unverified in this environment.

### How to Use

Here are some specific examples provided.

#### When Need Config-built Async Text Console Output

When async queue behavior is config-driven and output should stay on text console formatting:
```moonbit
let logger = build_async_text_logger(
  AsyncLoggerBuildConfig::new(
    logger=text_console(target="async.text"),
    async_config=AsyncLoggerConfig::new(max_pending=4),
  ),
)
```

In this example, the async logger is built around a text console sink rather than the generic runtime sink enum.

#### When Need A Per-call Target Override After Built Async Text Construction

When typed async text config should still build a logger that supports a one-call target override:
```moonbit
let logger = build_async_text_logger(config)
logger.log(@bitlogger.Level::Error, "boom", target="async.text.audit")
```

In this example, the emitted record uses `async.text.audit` for that call.

And later `debug(...)`, `info(...)`, `warn(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

### Error Case

e.g.:
- If callers need sink-kind-driven branching across console, JSON, text, or file output, `build_async_logger(...)` is the better fit.

- If the logger is never `run()`, pending records still follow the normal async queue lifecycle rules.

- If callers rely on the concrete formatter or post-run state shape, this builder is the direct API that preserves those text-console details rather than a reduced alias or wrapper.

### Notes

1. This API is narrower than `build_async_logger(...)` because it preserves a concrete text sink type.

2. It is the base builder used by the application and library async text facades.

3. See [target-verification.md](./target-verification.md) for the current local verification matrix.

4. Use this direct builder when callers should keep the full async helper surface on the concrete text sink type rather than a naming alias or a narrowed library wrapper.
