---
name: async-logger-config-type
group: api
category: async
update-time: 20260614
description: Public async logger config alias used for async queue interpretation, batching, linger, and flush settings.
key-word:
    - async
    - config
    - alias
    - public
---

## Async-logger-config-type

`AsyncLoggerConfig` is the public config object used to describe async queue capacity, overflow behavior, batching, linger timing, and flush policy. It is a direct alias to the async config model used by `async_logger(...)`, config parsers, and async config serializers.

### Interface

```moonbit
pub type AsyncLoggerConfig = @utils.AsyncLoggerConfig
```

#### output

- `AsyncLoggerConfig` - Public async config object containing `max_pending`, `overflow`, `max_batch`, `linger_ms`, and `flush`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a runtime logger handle.
- The current fields are `max_pending : Int`, `overflow : AsyncOverflowPolicy`, `max_batch : Int`, `linger_ms : Int`, and `flush : AsyncFlushPolicy`.
- `AsyncLoggerConfig::new(...)` normalizes `max_batch` and `linger_ms`, but it preserves the provided `max_pending` value.
- Runtime queue creation later interprets negative `max_pending` as `0` when choosing the internal queue kind.
- `parse_async_logger_config_text(...)`, `async_logger_config_to_json(...)`, and `stringify_async_logger_config(...)` all operate on this same public config shape.
- The parser accepts the stable serialized labels such as `DropNewest` and `Never`, plus compatibility aliases such as `DropLatest` and `None`.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Async Runtime Policy Value

When async queue and flush behavior should be passed around as structured config:
```moonbit
let config : AsyncLoggerConfig = AsyncLoggerConfig::new(
  max_pending=64,
  overflow=AsyncOverflowPolicy::DropOldest,
)
```

In this example, async policy remains a typed object instead of immediately becoming JSON text or a logger instance.

#### When Need To Inspect The Config Before Building

When one layer should read or adjust async policy before logger construction:
```moonbit
let config = AsyncLoggerConfig::new(max_batch=4, linger_ms=20)
println(stringify_async_logger_config(config, pretty=true))
```

In this example, the same public config object supports both inspection and later build steps.

### Error Case

e.g.:
- `AsyncLoggerConfig` itself does not have a runtime failure mode.

- Constructor normalization still applies when the value is created through `AsyncLoggerConfig::new(...)`, so very small batch sizes and negative linger values may be adjusted before later serialization or use.

- Negative `max_pending` is not rewritten inside the config object itself; it is only clamped later when the async queue kind is derived at runtime.

### Notes

1. Use `AsyncLoggerConfig::new(...)` when you need a value of this type in code.

2. Use `AsyncLoggerBuildConfig` when the async config should travel together with the base synchronous `LoggerConfig`.

3. Use `parse_async_logger_config_text(...)` when the same shape should come from JSON text, including accepted aliases like `DropLatest` and `None`.
