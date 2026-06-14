---
name: build-application-logger
group: api
category: facade
update-time: 20260520
description: Build the application-facing configured logger alias from a LoggerConfig by delegating directly to the normal runtime logger build path.
key-word:
    - application
    - facade
    - logger
    - public
---

## Build-application-logger

Build an `ApplicationLogger` from `LoggerConfig`. This facade is the application-oriented sync entry point and currently aliases the configured runtime logger shape returned by `build_logger(...)`.

### Interface

```moonbit
pub fn build_application_logger(config : LoggerConfig) -> ApplicationLogger {
```

#### input

- `config : LoggerConfig` - Fully assembled sync logger config.

#### output

- `ApplicationLogger` - Application-facing configured runtime logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to `build_logger(...)` directly.
- The embedded config still goes through the normal runtime logger build path, including runtime sink selection, optional queue wrapping, and timestamp application.
- Because the result is only the `ApplicationLogger` alias over `ConfiguredLogger`, this builder does not hide any queue, drain, flush, or file runtime helper methods.
- The configured runtime helper surface is therefore preserved and directly exposed on the returned alias rather than being rebuilt or hidden behind an unwrap step.
- The returned alias also keeps inherited `Logger` behavior such as `with_target(...)`, `child(...)`, and per-call `target=` overrides on `log(...)`.
- That means `log(..., target=...)` can override the target for one write, while severity helpers such as `info(...)`, `warn(...)`, and `error(...)` continue to use the stored logger target unless a derived logger was created first with `with_target(...)` or `child(...)`.
- Use this alias-oriented entrypoint when application boot code wants an app-specific name without changing the underlying configured runtime logger surface.

### How to Use

Here are some specific examples provided.

#### When Need An App-level Sync Builder Entry

When boot code assembles config values before runtime construction:
```moonbit
let logger = build_application_logger(
  LoggerConfig::new(target="app", sink=SinkConfig::new(kind=SinkKind::Console)),
)
```

In this example, the application facade builds the same configured runtime logger shape as `build_logger(...)`.

And any queue/file/runtime helpers selected by the config remain directly available on the returned alias value.

And unlike `build_library_logger(...)`, no `to_logger()` unwrap is required to reach that helper surface.

The returned value also keeps the ordinary logger target semantics because the facade does not wrap or narrow the underlying `ConfiguredLogger`.

#### When Need A Per-call Target Override After App-oriented Build

When typed app config should still build a logger that supports a one-write target override:
```moonbit
let logger = build_application_logger(config)
logger.log(Level::Error, "boom", target="app.audit")
```

In this example, the emitted record uses `app.audit` for that write.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

### Error Case

e.g.:
- If the config uses file output on a backend without native file support, backend runtime limitations still apply after construction.

- If queueing is not configured, queue helper values simply reflect the non-queued runtime shape.

### Notes

1. This is a facade API, not a separate runtime implementation.

2. Use `parse_and_build_application_logger(...)` when starting from JSON text.

3. Use `build_library_logger(...)` instead when the public surface should intentionally hide configured-runtime helper methods.
