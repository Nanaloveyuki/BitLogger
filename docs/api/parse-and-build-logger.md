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

At the public `src` layer, this API is a facade composition of the root parser and root builder: it parses into the shared config model owned by `src/config_model`, then produces a `ConfiguredLogger` backed by `src/runtime.RuntimeSink`.

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

- Parsing and building are done in one step by calling `parse_logger_config_text(input)` first and then passing the resulting `LoggerConfig` into `build_logger(...)`.
- The resulting file-control and file-diagnostics helpers remain facade methods over `RuntimeSink`, which in turn delegates file behavior to `src/file_runtime` and file model values to `src/file_model`.
- The returned `ConfiguredLogger` is just `Logger[RuntimeSink]`, so it still supports regular logging calls.
- The returned logger also keeps inherited logger target behavior such as `with_target(...)`, `child(...)`, and per-call `target=` overrides on `log(...)`.
- That means `log(..., target=...)` can override the target for one write, while severity helpers such as `info(...)`, `warn(...)`, and `error(...)` continue to use the stored logger target unless a derived logger was created first with `with_target(...)` or `child(...)`.
- Queue wrapping and file control helpers remain available after config assembly.
- `parse_and_build_application_logger(...)` only re-exports this same configured runtime logger result under the `ApplicationLogger` alias, while `parse_and_build_library_logger(...)` wraps the same result in `LibraryLogger[RuntimeSink]`.
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

And the resulting value can immediately emit logs with the same ordinary logger target semantics as any other `Logger` value.

#### When Need A Per-call Target Override After Config Parsing

When parsed runtime config should still allow a one-write target override:
```moonbit
let logger = parse_and_build_logger(raw) catch {
  err => return
}
logger.log(Level::Error, "boom", target="api.audit")
```

In this example, the emitted record uses `api.audit` for that write.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

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

1. Use `parse_logger_config_text(...)` first if you want to validate and inspect config separately.

2. Prefer this API for app bootstrapping paths that read config once and then construct the runtime logger.

3. Use the application or library parse/build facades only when the public name or exposed surface should differ; they do not change the configured runtime logger pipeline produced here.

