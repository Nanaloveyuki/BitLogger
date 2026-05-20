---
name: build-library-async-text-logger
group: api
category: facade
update-time: 20260520
description: Build the library-facing text-console async logger facade from an AsyncLoggerBuildConfig.
key-word:
    - library
    - async
    - text
    - public
---

## Build-library-async-text-logger

Build a `LibraryAsyncLogger[FormattedConsoleSink]` from `AsyncLoggerBuildConfig`. This facade is the library-oriented async builder for text-console runtime output.

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

- This API delegates to `build_async_text_logger(...)` and then wraps the result as `LibraryAsyncLogger`.
- It is useful when library code wants a narrow async facade while preserving a concrete text-console sink type.
- `to_async_logger()` can recover the underlying full async logger if needed.

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

### Error Case

e.g.:
- If the embedded logger config does not describe text-console output, the caller should use the broader async facade instead.

- Normal async lifecycle expectations still apply if the logger is never run.

### Notes

1. This is the library-side counterpart to `build_application_text_async_logger(...)`.

2. It is most useful when a concrete text-console async sink type matters to the caller boundary.
