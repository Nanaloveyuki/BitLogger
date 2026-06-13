---
name: configured-logger
group: api
category: runtime
update-time: 20260613
description: Public configured runtime logger alias used for config-built sync logging with queue and file controls.
key-word:
    - logger
    - runtime
    - alias
    - public
---

## Configured-logger

`ConfiguredLogger` is the public sync runtime logger type returned by config-driven build APIs. It is a direct alias to `Logger[RuntimeSink]`, so it keeps ordinary logger write methods while also exposing configured queue and file runtime helpers.

### Interface

```moonbit
pub type ConfiguredLogger = Logger[RuntimeSink]
```

#### output

- `ConfiguredLogger` - Public config-built runtime logger backed by `RuntimeSink`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a separate wrapper implementation.
- It preserves normal logger methods such as `info(...)`, `warn(...)`, `error(...)`, and the other `Logger` APIs.
- It also exposes configured runtime helpers such as `flush()`, `drain()`, `pending_count()`, `dropped_count()`, and file-specific controls when the runtime sink supports them.
- Builders such as `build_logger(...)` and `parse_and_build_logger(...)` return this alias as the main sync config-to-runtime result.
- `ApplicationLogger` is another direct alias-oriented name for this same configured runtime surface, while `LibraryLogger[RuntimeSink]` is the narrowing facade variant that intentionally hides these runtime helpers until `to_logger()` is used.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Config-built Runtime Logger

When boot code should keep the built logger as a named runtime type:
```moonbit
let logger : ConfiguredLogger = build_logger(LoggerConfig::new(target="svc"))
```

In this example, the configured runtime logger remains a first-class typed value after config assembly.

#### When Need Normal Logging Plus Runtime Controls

When code should both emit logs and inspect configured runtime behavior:
```moonbit
logger.info("started")
ignore(logger.pending_count())
```

In this example, the alias keeps ordinary logging calls while still exposing runtime diagnostics.

### Error Case

e.g.:
- `ConfiguredLogger` itself does not have a runtime failure mode.

- The concrete behavior of queue and file helpers still depends on the configured `RuntimeSink` shape and current backend support.

### Notes

1. Use `build_logger(...)` or `parse_and_build_logger(...)` when you need a value of this type.

2. Use `ApplicationLogger` when application code wants the same full configured-runtime helper surface under an app-facing name.

3. Use `LibraryLogger[RuntimeSink]` when a library boundary should intentionally hide configured-runtime helper methods behind a narrower facade.
