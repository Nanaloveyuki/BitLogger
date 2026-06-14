---
name: async-logger-build-config
group: api
category: async
update-time: 20260614
description: Create the combined sync-and-async build config used by async logger builder APIs, whether callers later choose the full sync-first builder path or the specialized text-console builder path.
key-word:
    - async
    - build
    - config
    - public
---

## Async-logger-build-config

Create an `AsyncLoggerBuildConfig` value that combines the base synchronous `LoggerConfig` with the async runtime `AsyncLoggerConfig`. This is the constructor used when async builder APIs should receive one typed object carrying both layers of setup, even though different builders later consume different parts of the embedded sync config.

### Interface

```moonbit
pub fn AsyncLoggerBuildConfig::new(
  logger~ : @bitlogger.LoggerConfig = @bitlogger.default_logger_config(),
  async_config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
) -> AsyncLoggerBuildConfig {
```

#### input

- `logger : LoggerConfig` - Base synchronous logger config describing the sink, level, target, related sync logger settings, and any optional synchronous queue wrapper.
- `async_config : AsyncLoggerConfig` - Async runtime config describing queue, batching, linger, and flush behavior.

#### output

- `AsyncLoggerBuildConfig` - Combined build config used by async logger build and parse helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- Omitting `logger` uses `default_logger_config()`.
- Omitting `async_config` uses `AsyncLoggerConfig::new()`.
- The constructor simply packages both config objects into one public build shape.
- The constructor does not normalize or reinterpret either embedded config beyond those defaults; any normalization has already happened inside the `LoggerConfig` or `AsyncLoggerConfig` values passed in.
- When passed to `build_async_logger(...)`, the `logger` portion is built first through the normal synchronous config path before the outer async queue layer is applied.
- When passed to `build_async_text_logger(...)`, the same `logger` portion is consumed more narrowly: `text_formatter`, `min_level`, `target`, and `timestamp` are used directly to build a text console sink, while `LoggerConfig.queue` is not applied.
- On that text-specific path, `logger.sink.kind` also does not decide the runtime sink shape. `build_async_text_logger(...)` still constructs `FormattedConsoleSink` from `logger.sink.text_formatter` even if the config says `Console`, `JsonConsole`, or `File`.
- This helper is the main code-side counterpart to `parse_async_logger_build_config_text(...)`.

### How to Use

Here are some specific examples provided.

#### When Need One Typed Object For Async Builder Input

When sync sink setup and async runtime policy should travel together through build code:
```moonbit
let config = AsyncLoggerBuildConfig::new(
  logger=@bitlogger.LoggerConfig::new(target="svc.async"),
  async_config=AsyncLoggerConfig::new(max_pending=64, max_batch=8),
)
```

In this example, the builder input keeps both configuration layers in one typed value.

And later code can still decide whether that shared config should flow into the full sync-first builder or the narrower text-console builder.

And if later code chooses `build_async_text_logger(...)`, that builder choice still matters more than `logger.sink.kind` because only the formatter-backed text path is consumed there.

#### When Need Defaulted Async Build Settings

When code only wants the standard combined config shape with few overrides:
```moonbit
let config = AsyncLoggerBuildConfig::new(async_config=AsyncLoggerConfig::new(max_batch=4))
```

In this example, the base sync logger config falls back to its default value automatically.

### Error Case

e.g.:
- This constructor itself does not have a normal failure mode; it only packages configuration values.

- If callers only need async runtime policy and not the full builder input shape, `AsyncLoggerConfig::new(...)` is the smaller API.

- If callers expect every field inside `LoggerConfig` to affect every async builder equally, that assumption is too broad: `build_async_text_logger(...)` intentionally skips the optional sync queue layer.

- In particular, carrying `logger.sink.kind=File` inside this config does not force the later text-specific builder path to create a file-backed async logger; only `build_async_logger(...)` branches on sink kind.

### Notes

1. Use this helper when async builder APIs should receive one combined config object.

2. Pair it with `build_async_logger(...)`, `build_async_text_logger(...)`, or `parse_async_logger_build_config_text(...)` depending on whether the source is code or JSON text.

3. Prefer `build_async_logger(...)` after constructing this value when configured sync sink behavior, including `LoggerConfig.queue`, should be preserved before async wrapping.

4. Prefer `build_async_text_logger(...)` after constructing this value when the goal is specifically config-driven text console output with a concrete `FormattedConsoleSink`.
