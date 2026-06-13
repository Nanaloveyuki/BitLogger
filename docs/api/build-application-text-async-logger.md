---
name: build-application-text-async-logger
group: api
category: facade
update-time: 20260614
description: Build the application-facing text-console async logger facade from an AsyncLoggerBuildConfig using the configured text formatter directly.
key-word:
    - application
    - async
    - text
    - public
---

## Build-application-text-async-logger

Build an `ApplicationTextAsyncLogger` from `AsyncLoggerBuildConfig`. This facade is the application-oriented async builder for the text-console runtime sink shape returned by `build_async_text_logger(...)`.

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

- This API delegates to `build_async_text_logger(...)`.
- It is intended for config-driven async text console output where callers want the concrete text sink shape rather than the broader runtime sink enum wrapper.
- The builder always creates a `FormattedConsoleSink` from `config.logger.sink.text_formatter` instead of selecting among sink kinds.
- Unlike `build_application_async_logger(...)`, this facade does not go through the full synchronous configured-logger build path first.
- It uses the selected text-oriented `LoggerConfig` fields directly and therefore does not apply `LoggerConfig.queue` or preserve sync runtime sink controls.
- The returned logger keeps the usual async lifecycle helpers.
- Because it returns the direct `ApplicationTextAsyncLogger` alias, the resulting logger also keeps the same runtime-dependent close/failure semantics as the underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]`.

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

### Error Case

e.g.:
- If callers need sink-kind-driven branching such as JSON console or file-backed async output, they should use `build_application_async_logger(...)` instead.

- If runtime draining is never started, records still follow the normal async queue lifecycle rules.

### Notes

1. This is a narrower text-console async facade than `build_application_async_logger(...)`.

2. It is most useful when callers want the `FormattedConsoleSink`-backed async type explicitly.

3. Use `build_application_async_logger(...)` instead when callers need the broader runtime-sink build path, including sync queue application through `build_logger(config.logger)`.
