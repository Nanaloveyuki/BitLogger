---
name: async-logger-build-config-to-json
group: api
category: async
update-time: 20260614
description: Convert AsyncLoggerBuildConfig into a JSON value for exporting the full shared async build shape that can later feed either async builder path.
key-word:
    - async
    - build
    - config
    - public
---

## Async-logger-build-config-to-json

Convert `AsyncLoggerBuildConfig` into a `JsonValue`. This helper exports both the base synchronous logger config and the async runtime config as one structured payload.

### Interface

```moonbit
pub fn async_logger_build_config_to_json(
  config : AsyncLoggerBuildConfig,
) -> @json_parser.JsonValue {}
```

#### input

- `config : AsyncLoggerBuildConfig` - Complete build config used by async logger builders.

#### output

- `JsonValue` - Structured JSON representation of the full async build config.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output always includes `logger` and `async_config`.
- Logger export is delegated to `@bitlogger.logger_config_to_json(...)`.
- Async export is delegated to `async_logger_config_to_json(...)`.
- This helper is useful when generated setup should preserve both sink/logger behavior and async runtime behavior together.
- The exported `logger` section keeps the full `LoggerConfig` shape, including fields that only matter on the full sync-first builder path such as the optional sync queue layer.
- That means the JSON shape is broader than the consumption pattern of `build_async_text_logger(...)`, which only uses selected text-oriented logger fields when building the sink.

### How to Use

Here are some specific examples provided.

#### When Need Structured Export Of Full Async Setup

When a tool or test needs one object describing the whole async logger build:
```moonbit
let payload = async_logger_build_config_to_json(
  AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(target="svc"),
    async_config=AsyncLoggerConfig::new(max_pending=64),
  ),
)
```

In this example, both layers of configuration are exported together.

And later consumers can still choose whether to rebuild through `build_async_logger(...)` or the narrower `build_async_text_logger(...)` path.

#### When Need Roundtrip-friendly Build Config Data

When generated build config should later be parsed again:
```moonbit
let value = async_logger_build_config_to_json(AsyncLoggerBuildConfig::new())
```

In this example, the resulting JSON matches the supported async build config shape.

### Error Case

e.g.:
- If callers only need the async runtime section, this API is broader than necessary and `async_logger_config_to_json(...)` should be used instead.

- If callers want direct text output, they should use `stringify_async_logger_build_config(...)` instead.

- Exporting the full `logger` section does not imply that every async builder will later consume every logger field equally.

### Notes

1. Use this helper when tools or tests need a structured JSON object instead of text.

2. Use `stringify_async_logger_build_config(...)` when the same build shape should be emitted as JSON text directly.

3. The resulting object round-trips through `parse_async_logger_build_config_text(...)`, even though different async builders later consume different parts of the embedded `LoggerConfig`.

