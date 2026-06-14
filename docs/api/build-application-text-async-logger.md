---
name: build-application-text-async-logger
group: api
category: facade
update-time: 20260614
description: Build the application-facing text-console async logger alias from an AsyncLoggerBuildConfig using the direct concrete text-sink builder path.
key-word:
    - application
    - async
    - text
    - public
---

## Build-application-text-async-logger

Build an `ApplicationTextAsyncLogger` from `AsyncLoggerBuildConfig`. This is the application-oriented async alias builder for the concrete text-console sink shape returned by `build_async_text_logger(...)`.

### Interface

```moonbit
pub fn build_application_text_async_logger(
  config : AsyncLoggerBuildConfig,
) -> ApplicationTextAsyncLogger {
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined sync logger config and async queue/runtime config.

#### output

- `ApplicationTextAsyncLogger` - Application-facing async logger backed by `FormattedConsoleSink`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to `build_async_text_logger(...)` directly.
- It is intended for config-driven async text console output where callers want the concrete text sink shape rather than the broader runtime sink enum wrapper.
- The builder always creates a `FormattedConsoleSink` from `config.logger.sink.text_formatter` instead of selecting among sink kinds.
- That means even if `config.logger.sink.kind` says `Console`, `JsonConsole`, or `File`, this facade still follows the text-console path and uses only the configured `text_formatter` details.
- Unlike `build_application_async_logger(...)`, this alias-oriented builder does not go through the full synchronous configured-logger build path first.
- It uses the selected text-oriented `LoggerConfig` fields directly and therefore does not apply `LoggerConfig.queue` or preserve sync runtime sink controls.
- A sync queue configured on `LoggerConfig.queue` is therefore ignored by this builder instead of being preserved under the returned async logger.
- Because the result is only the `ApplicationTextAsyncLogger` alias over `AsyncLogger[@bitlogger.FormattedConsoleSink]`, this builder returns the same underlying async logger value as `build_async_text_logger(...)` and does not hide any async helpers or introduce a wrapper layer.
- The returned alias also keeps inherited async logger target behavior such as `with_target(...)`, `child(...)`, and per-call `target=` overrides on `log(...)`.
- In particular, `log(..., target=...)` can override the target for one call, while severity helpers such as `debug(...)`, `info(...)`, `warn(...)`, and `error(...)` continue using the stored logger target unless code derives another logger first with `with_target(...)` or `child(...)`.
- The returned logger keeps the full async lifecycle and state helper surface directly, including helpers such as `run()`, `shutdown()`, `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, `has_failed()`, and `last_error()`.
- It also keeps the same close, queue, and failure-state semantics as the underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]`.
- In the current direct text-builder coverage, this alias matches `build_async_text_logger(config)` through serialized state snapshots, formatter behavior, queue counters, lifecycle flags, and later failure fields after worker execution.
- Its configured `flush_policy` is still visible on the returned alias, but this text-specific build path does not wire the explicit sink flush callback that `build_application_async_logger(...)` inherits through `build_async_logger(...)`.
- That means `Batch` and `Shutdown` only drive the default no-op async flush callback here; they do not add an extra explicit sink flush step beyond ordinary `FormattedConsoleSink` writes.
- Use `build_library_async_text_logger(...)` instead when the next boundary should keep the same concrete text sink type but intentionally narrow the directly exposed async helper surface.

### How to Use

Here are some specific examples provided.

#### When Need An App Async Builder With Text Sink Shape

When async output should stay on text console formatting:
```moonbit
let logger = build_application_text_async_logger(
  AsyncLoggerBuildConfig::new(
    logger=text_console(target="app.text.async"),
    async_config=AsyncLoggerConfig::new(max_pending=4),
  ),
)
```

In this example, the async logger is built for text-console output specifically.

And the chosen builder path matters more than `config.logger.sink.kind`: this facade still uses the text formatter directly because it always builds a `FormattedConsoleSink`.

And the returned value keeps the ordinary async logger target semantics because this facade does not wrap or narrow the underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]`.

#### When Need A Per-call Target Override After App Text Construction

When typed app async text config should still build a logger that supports a one-call target override:
```moonbit
let logger = build_application_text_async_logger(config)
logger.log(@bitlogger.Level::Error, "boom", target="app.text.audit")
```

In this example, the emitted record uses `app.text.audit` for that call.

And later `debug(...)`, `info(...)`, `warn(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

#### When Need Async State Helpers Immediately After Text App Construction

When application code should keep the ordinary async helper surface directly on the text-console variant:
```moonbit
let logger = build_application_text_async_logger(config)
ignore(logger.pending_count())
ignore(logger.state())
```

In this example, the application text alias exposes async state helpers directly because no narrowing wrapper is added.

### Error Case

e.g.:
- If callers need sink-kind-driven branching such as JSON console or file-backed async output, they should use `build_application_async_logger(...)` instead.

- If the config carries file-oriented fields such as `path` only because `sink.kind` was set to `File`, this facade still ignores that sink-kind choice and does not create a file-backed async logger.

- If runtime draining is never started, records still follow the normal async queue lifecycle rules.

- If callers rely on the formatter or state shape after text-builder construction, they should treat this as the same direct `build_async_text_logger(config)` result rather than a reduced alias with different helper behavior.

### Notes

1. This is a narrower text-console async facade than `build_application_async_logger(...)`.

2. It is most useful when callers want the `FormattedConsoleSink`-backed async type explicitly.

3. Use `build_application_async_logger(...)` instead when callers need the broader runtime-sink build path, including sync queue application through `build_logger(config.logger)`.

4. Use `build_library_async_text_logger(...)` instead when the public boundary should narrow the exposed async surface while preserving the same concrete text sink type.
