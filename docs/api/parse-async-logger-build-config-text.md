---
name: parse-async-logger-build-config-text
group: api
category: async
update-time: 20260614
description: Parse combined sync logger and async runtime JSON into a typed async build configuration that can feed either the full async builder path or the specialized text-console builder path.
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

- `input : String` - JSON text that may contain `logger` and `async_config` sections.

#### output

- `AsyncLoggerBuildConfig` - Typed build config ready for `build_async_logger(...)` or `build_async_text_logger(...)`, with the same parsed shape feeding two distinct builder paths.

### Explanation

Detailed rules explaining key parameters and behaviors

- The JSON root is split into `logger` and `async_config`.
- `logger` reuses the same synchronous config schema parsed by `parse_logger_config_text(...)`.
- `async_config` is parsed through `parse_async_logger_config_text(...)`.
- If `logger` is omitted, parsing falls back to `default_logger_config()`.
- If `async_config` is omitted, parsing falls back to `AsyncLoggerConfig::new()`.
- This API separates validation from actual async runtime construction.
- When the parsed config is later passed to `build_async_logger(...)`, the embedded `logger` section goes through the normal sync builder path first, including optional `LoggerConfig.queue` handling.
- When the same parsed config is passed to `build_async_text_logger(...)`, only `logger.sink.text_formatter` plus the top-level `min_level`, `target`, and `timestamp` fields are consumed directly, so the sync queue layer is not applied.

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

And the later builder choice determines whether the parsed sync queue settings participate in construction.

#### When Need Parsed Async Text Console Setup

When JSON should drive async text-console output without the broader runtime sink wrapper:
```moonbit
let config = parse_async_logger_build_config_text(raw) catch {
  err => return
}
let logger = build_async_text_logger(config)
```

In this example, the same parsed config object is reused, but the text-specific builder only applies the selected text-oriented logger fields.

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

- Successful parsing does not guarantee that every parsed `LoggerConfig` field will matter equally to every async builder; that depends on the chosen builder path.

### Notes

1. Use this API when async build config is stored as JSON.

2. Use `AsyncLoggerBuildConfig::new(...)` when assembling config directly in code.

3. Use `build_async_logger(...)` after parsing when the full sync config path should be preserved before async wrapping.

4. Use `build_async_text_logger(...)` after parsing when callers specifically want config-driven text console output with a concrete `FormattedConsoleSink`.

