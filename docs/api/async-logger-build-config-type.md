---
name: async-logger-build-config-type
group: api
category: async
update-time: 20260614
description: Public async build config alias combining the base logger config and async runtime config for both the general async builder path and the specialized text-console builder path.
key-word:
    - async
    - build
    - config
    - public
---

## Async-logger-build-config-type

`AsyncLoggerBuildConfig` is the public config object that combines the base synchronous `LoggerConfig` with the async runtime `AsyncLoggerConfig`. It is a direct alias to the build-config model used by async builder APIs, parsers, and serializers, even though the available builders consume different parts of the embedded sync config.

### Interface

```moonbit
pub type AsyncLoggerBuildConfig = @utils.AsyncLoggerBuildConfig
```

#### output

- `AsyncLoggerBuildConfig` - Public async build config object containing `logger` and `async_config`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a built logger instance.
- The current fields are `logger : LoggerConfig` and `async_config : AsyncLoggerConfig`.
- The public `src-async` surface forwards this alias directly from `@utils.AsyncLoggerBuildConfig`, so constructor, parser, export, and stringify helpers all operate on one shared underlying build-config model.
- `AsyncLoggerBuildConfig::new(...)` constructs this type as the main handoff object for async build flows.
- `build_async_logger(...)`, `build_async_text_logger(...)`, `parse_async_logger_build_config_text(...)`, `async_logger_build_config_to_json(...)`, and `stringify_async_logger_build_config(...)` all consume or produce this same public shape.
- `build_async_logger(...)` consumes the full sync build path by calling `build_logger(config.logger)` first, so `LoggerConfig.sink`, `LoggerConfig.queue`, and the resulting runtime sink behavior all participate before the async layer is added.
- `build_async_text_logger(...)` is narrower: it builds a text console sink directly from `config.logger.sink.text_formatter` and the top-level `min_level`, `target`, and `timestamp` fields, without applying `LoggerConfig.queue`.
- On that text-specific path, `config.logger.sink.kind` also does not decide the runtime sink shape. `build_async_text_logger(...)` still constructs `FormattedConsoleSink` from `config.logger.sink.text_formatter` even if the config says `Console`, `JsonConsole`, or `File`.

### How to Use

Here are some specific examples provided.

#### When Need One Typed Object For Full Async Logger Setup

When sync sink setup and async runtime policy should move together through application boot code:
```moonbit
let config : AsyncLoggerBuildConfig = AsyncLoggerBuildConfig::new(
  logger=@bitlogger.LoggerConfig::new(target="svc"),
  async_config=AsyncLoggerConfig::new(max_pending=64),
)
```

In this example, both layers of logger setup are kept in one typed value.

And downstream code can still choose between the full sync-first builder path and the narrower text-console builder path.

And if downstream code chooses `build_async_text_logger(...)`, that builder choice still matters more than `logger.sink.kind` because only the formatter-backed text path is consumed there.

#### When Need To Export Or Inspect The Full Build Shape

When application code should inspect the combined async build configuration before constructing the logger:
```moonbit
let config = AsyncLoggerBuildConfig::new(async_config=AsyncLoggerConfig::new(max_batch=4))
println(stringify_async_logger_build_config(config, pretty=true))
```

In this example, the same public config object supports both review and later build steps.

### Error Case

e.g.:
- `AsyncLoggerBuildConfig` itself does not have a runtime failure mode.

- If only async runtime policy is needed and the base sync logger config is irrelevant, this type may be broader than necessary and `AsyncLoggerConfig` is the smaller fit.

- If callers expect every `LoggerConfig` field to affect every async builder in the same way, that assumption is too broad: the text-specific builder intentionally ignores the optional sync queue layer.

- In particular, carrying `logger.sink.kind=File` inside this config type does not force the later text-specific builder path to create a file-backed async logger; only `build_async_logger(...)` branches on sink kind.

### Notes

1. Use `AsyncLoggerBuildConfig::new(...)` when one object should carry both sync and async logger setup.

2. Use `parse_async_logger_build_config_text(...)` when the same shape should come from JSON text instead of handwritten code.

3. Pick `build_async_logger(...)` when the full synchronous config path, including `LoggerConfig.queue`, should be preserved before async wrapping.

4. Pick `build_async_text_logger(...)` when the goal is specifically a concrete text console sink and only the selected text-oriented `LoggerConfig` fields should apply.
