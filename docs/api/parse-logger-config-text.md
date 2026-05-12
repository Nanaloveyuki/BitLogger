---
name: parse-logger-config-text
group: api
category: config
update-time: 20260512
description: Parse raw JSON text into a typed LoggerConfig without building the runtime logger yet.
key-word:
    - parse
    - config
    - json
    - public
---

## Parse-logger-config-text

Parse JSON text into a typed `LoggerConfig`. This API is useful when you want validation and inspection of config data before turning it into a runtime logger.

### Interface

```moonbit
pub fn parse_logger_config_text(input : String) -> LoggerConfig raise ConfigError {}
```

#### input

- `input : String` - Raw JSON text matching the supported logger config schema.

#### output

- `LoggerConfig` - Parsed typed configuration value.

### Explanation

Detailed rules explaining key parameters and behaviors

- Parsing is separated from runtime construction.
- This API is ideal for validating, editing, or inspecting config values before calling `build_logger(...)`.
- Supported keys are intentionally constrained to stable built-in sink shapes and formatter options.
- The error surface is `ConfigError` rather than silent fallback behavior.

### How to Use

Here are some specific examples provided.

#### When Need Validation Before Runtime Build

When config should be reviewed before creating the logger:
```moonbit
let config = parse_logger_config_text(raw) catch {
  err => return
}
let logger = build_logger(config)
```

In this example, parsing and building remain separate phases.

#### When Need To Inspect Parsed Values

When config should be normalized into typed values first:
```moonbit
let config = parse_logger_config_text(raw) catch {
  err => return
}
println(config.target)
```

In this example, the parsed object can be inspected or rewritten before runtime use.

### Error Case

e.g.:
- If `input` is invalid JSON, parsing raises `ConfigError`.

- If supported fields have wrong types or unsupported enum text, parsing raises `ConfigError`.

### Notes

1. Prefer this API when you need typed config inspection before building.

2. Prefer `parse_and_build_logger(...)` when one-step bootstrapping is enough.

