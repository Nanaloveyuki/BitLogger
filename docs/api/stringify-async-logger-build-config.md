---
name: stringify-async-logger-build-config
group: api
category: async
update-time: 20260512
description: Serialize AsyncLoggerBuildConfig into compact or pretty JSON text for export and diagnostics.
key-word:
    - async
    - build
    - stringify
    - public
---

## Stringify-async-logger-build-config

Serialize `AsyncLoggerBuildConfig` into JSON text. This helper is the most direct export path when a full async logger setup should be printed, logged, or stored as JSON text.

### Interface

```moonbit
pub fn stringify_async_logger_build_config(
  config : AsyncLoggerBuildConfig,
  pretty~ : Bool = false,
) -> String {}
```

#### input

- `config : AsyncLoggerBuildConfig` - Full async logger build config to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the full build config.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON for human inspection.
- This helper is built on top of `async_logger_build_config_to_json(...)`.
- The output keeps `logger` and `async_config` as separate sections, matching supported parser input.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Full Async Setup

When both logger and async policy should be inspected together:
```moonbit
println(stringify_async_logger_build_config(AsyncLoggerBuildConfig::new(), pretty=true))
```

In this example, the full build configuration is rendered as readable JSON.

#### When Need Compact Generated Build Config

When config text should stay small for snapshots or transport:
```moonbit
let text = stringify_async_logger_build_config(
  AsyncLoggerBuildConfig::new(async_config=AsyncLoggerConfig::new(max_batch=4)),
)
```

In this example, compact JSON is returned without extra formatting.

### Error Case

e.g.:
- If callers need a `JsonValue` for further composition, they should use `async_logger_build_config_to_json(...)` instead.

- If only one layer of config is required, this helper may be broader than necessary.

