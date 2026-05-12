---
name: parse-async-logger-build-config-text
group: api
category: async
update-time: 20260512
description: Parse combined sync logger and async runtime JSON into a typed async build configuration.
key-word:
    - async
    - parse
    - config
    - public
---

## Parse-async-logger-build-config-text

Parse JSON text into `AsyncLoggerBuildConfig`. This API validates both the synchronous logger portion and the async queue/runtime portion before any async logger is built.

### Interface

```moonbit
pub fn parse_async_logger_build_config_text(input : String) -> AsyncLoggerBuildConfig raise {}
```

#### input

- `input : String` - JSON text containing `logger` and `async_config` sections.

#### output

- `AsyncLoggerBuildConfig` - Typed build config ready for `build_async_logger(...)` or `build_async_text_logger(...)`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The JSON root is split into `logger` and `async_config`.
- `logger` reuses the same synchronous config schema parsed by `parse_logger_config_text(...)`.
- `async_config` is parsed through `parse_async_logger_config_text(...)`.
- This API separates validation from actual async runtime construction.

### How to Use

Here are some specific examples provided.

#### When Need Config-driven Async Bootstrapping

When both sink config and async runtime config come from JSON:
```moonbit
let config = parse_async_logger_build_config_text(raw) catch {
  err => return
}
let logger = build_async_logger(config)
```

In this example, parsing and runtime construction remain separate and testable.

#### When Need To Inspect Async Build Config Before Use

When config should be validated or reviewed before build:
```moonbit
let config = parse_async_logger_build_config_text(raw) catch {
  err => return
}
println(config.logger.target)
```

In this example, parsed sync and async sections can be inspected independently.

### Error Case

e.g.:
- If the root is not an object, parsing fails.

- If either `logger` or `async_config` contains invalid schema values, parsing fails through the underlying config parsers.

### Notes

Notes are here.

1. Use this API when async build config is stored as JSON.

2. Use `AsyncLoggerBuildConfig::new(...)` when assembling config directly in code.

3. Pair this API with `build_async_logger(...)` after validation.

4. The split `logger` plus `async_config` shape keeps sync and async concerns explicit.
