---
name: stringify-async-logger-build-config
group: api
category: async
update-time: 20260614
description: Serialize AsyncLoggerBuildConfig into compact or pretty JSON text for export and diagnostics across both async builder paths.
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
- Internally it serializes the `JsonValue` result with `@json_parser.stringify(...)` or `@json_parser.stringify_pretty(value, 2)`, so the text form stays aligned with the structured async build-config export helper.
- The output keeps `logger` and `async_config` as separate sections, matching supported parser input.
- The serialized `logger` section preserves the full `LoggerConfig` shape, even though `build_async_text_logger(...)` later consumes only the selected text-oriented subset of that logger config.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Full Async Setup

When both logger and async policy should be inspected together:
```moonbit
println(stringify_async_logger_build_config(AsyncLoggerBuildConfig::new(), pretty=true))
```

In this example, the full build configuration is rendered as readable JSON.

And the resulting text still describes a shared config object that can feed either async builder path later.

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

### Notes

1. Use this helper when the async build shape should be logged or stored as text directly.

2. Use `pretty=true` for review and diagnostics, or the default compact form for snapshots and transport.

3. The serialized shape round-trips through `parse_async_logger_build_config_text(...)`, but the later builder choice still controls whether the full sync config path or only the text-oriented subset is consumed during construction.

4. Use `async_logger_build_config_to_json(...)` when the next consumer still needs a `JsonValue` for composition before final stringification.

