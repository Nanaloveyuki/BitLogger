---
name: async-logger-build-config
group: api
category: async
update-time: 20260613
description: Create the combined sync-and-async build config used by async logger builder APIs.
key-word:
    - async
    - build
    - config
    - public
---

## Async-logger-build-config

Create an `AsyncLoggerBuildConfig` value that combines the base synchronous `LoggerConfig` with the async runtime `AsyncLoggerConfig`. This is the constructor used when async builder APIs should receive one typed object carrying both layers of setup.

### Interface

```moonbit
pub fn AsyncLoggerBuildConfig::new(
  logger~ : @bitlogger.LoggerConfig = @bitlogger.default_logger_config(),
  async_config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
) -> AsyncLoggerBuildConfig {
```

#### input

- `logger : LoggerConfig` - Base synchronous logger config describing the sink, level, target, and related sync logger settings.
- `async_config : AsyncLoggerConfig` - Async runtime config describing queue, batching, linger, and flush behavior.

#### output

- `AsyncLoggerBuildConfig` - Combined build config used by async logger build and parse helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- Omitting `logger` uses `default_logger_config()`.
- Omitting `async_config` uses `AsyncLoggerConfig::new()`.
- The constructor simply packages both config objects into one public build shape.
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

### Notes

1. Use this helper when async builder APIs should receive one combined config object.

2. Pair it with `build_async_logger(...)`, `build_async_text_logger(...)`, or `parse_async_logger_build_config_text(...)` depending on whether the source is code or JSON text.
