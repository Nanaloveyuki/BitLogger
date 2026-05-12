---
name: parse-and-build-logger
group: api
category: config
update-time: 20260512
description: Parse logger JSON config and immediately build a runtime logger with a stable control surface.
key-word:
    - config
    - logger
    - json
    - public
---

## Parse-and-build-logger

Parse a JSON logger definition and build a ready-to-use `ConfiguredLogger`. This is the most direct API when configuration is loaded from files, environment-derived JSON, or external settings systems.

### Interface

```moonbit
pub fn parse_and_build_logger(input : String) -> ConfiguredLogger raise ConfigError {}
```

#### input

- `input : String` - JSON text following the supported `LoggerConfig` schema.

#### output

- `ConfiguredLogger` - A runtime logger with normal logging methods plus queue/file control helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- Parsing and building are done in one step, which is useful when you do not need to inspect the intermediate `LoggerConfig`.
- The returned `ConfiguredLogger` is just `Logger[RuntimeSink]`, so it still supports regular logging calls.
- Queue wrapping and file control helpers remain available after config assembly.
- Errors are surfaced as `ConfigError` rather than silent fallback.

### How to Use

Here are some specific examples provided.

#### When Load Logger From JSON Text

When configuration comes from a file, environment variable, or settings service:
```moonbit
let logger = parse_and_build_logger(
  "{\"min_level\":\"info\",\"target\":\"api\",\"sink\":{\"kind\":\"text_console\"}}",
) catch {
  err => {
    ignore(err)
    return
  }
}
```

In this example, config parsing and logger construction happen in one place.

And the resulting value can immediately emit logs.

#### When Need Config-built File Or Queue Controls

When the sink shape is chosen by config but runtime introspection is still required:
```moonbit
let logger = parse_and_build_logger(raw) catch {
  err => return
}
ignore(logger.pending_count())
ignore(logger.file_runtime_state())
```

In this example, the configured runtime surface is still operational after building.

### Error Case

e.g.:
- If `input` is not valid JSON, a `ConfigError` is raised.

- If supported keys have wrong types or unsupported enum text, a `ConfigError` is raised.

### Notes

Notes are here.

1. Use `parse_logger_config_text(...)` first if you want to validate and inspect config separately.

2. Prefer this API for app bootstrapping paths that read config once and then construct the runtime logger.

3. `ConfiguredLogger` keeps queue and file helper methods, so config-driven logging does not lose control surface.

4. Keep the JSON schema limited to supported built-in sink shapes when designing external config files.
