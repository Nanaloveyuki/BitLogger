---
name: async-logger-build-config-to-json
group: api
category: async
update-time: 20260512
description: Convert AsyncLoggerBuildConfig into a JSON value for exporting complete async logger build settings.
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

---

e.g.:
```moonbit
pub fn async_logger_build_config_to_json(config : AsyncLoggerBuildConfig) -> @json_parser.JsonValue {}
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined logger and async config.

#### output

- `JsonValue` - JSON-exportable build payload.

---

### Explanation

Detailed rules explaining key parameters and behaviors

- The output always includes `logger` and `async_config`.
- Logger export is delegated to `@bitlogger.logger_config_to_json(...)`.
- Async export is delegated to `async_logger_config_to_json(...)`.
- This helper is useful when generated setup should preserve both sink/logger behavior and async runtime behavior together.

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

### Notes

Notes are here.

1. This helper exports complete build settings, not runtime state.

2. It is useful for generated configs, test fixtures, and setup introspection.

3. The output combines `LoggerConfig` and `AsyncLoggerConfig` without flattening them.

4. This API complements `parse_async_logger_build_config_text(...)` in roundtrip workflows.
