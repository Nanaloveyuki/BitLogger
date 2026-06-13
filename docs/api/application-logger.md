---
name: application-logger
group: api
category: facade
update-time: 20260613
description: Application-facing alias for the configured sync runtime logger surface.
key-word:
    - application
    - facade
    - alias
    - public
---

## Application-logger

`ApplicationLogger` is the application-facing sync logger alias. It currently maps directly to `ConfiguredLogger` and keeps the same runtime helper surface for sync logging, queue inspection, and file controls.

### Interface

```moonbit
pub type ApplicationLogger = ConfiguredLogger
```

#### output

- `ApplicationLogger` - Application-facing name for the configured sync runtime logger shape.

### Explanation

Detailed rules explaining key parameters and behaviors

- This alias does not introduce a new runtime type or wrapper layer.
- It preserves the same logging, queue, and file helper APIs exposed by `ConfiguredLogger`.
- The alias exists to give application boot code a clearer public entry name.
- Builders such as `build_application_logger(...)` and `parse_and_build_application_logger(...)` return this alias.

### How to Use

Here are some specific examples provided.

#### When Need An App-level Name For The Configured Runtime Logger

When application code wants a stable public type name for the configured sync logger:
```moonbit
let logger : ApplicationLogger = build_application_logger(LoggerConfig::new(target="app"))
```

In this example, the application alias keeps the same underlying runtime logger behavior while presenting an app-facing type name.

#### When Pass The Configured Logger Through App-level APIs

When top-level boot code or services should expose an application-oriented logger type:
```moonbit
fn start(logger : ApplicationLogger) -> Unit {
  logger.info("started")
}
```

In this example, callers see the app-facing alias instead of the lower-level `ConfiguredLogger` name.

### Error Case

e.g.:
- Because this is only an alias, any backend limitations of `ConfiguredLogger` still apply unchanged.

- If code needs a narrower public surface than the full configured runtime logger, `LibraryLogger` is the better facade.

### Notes

1. This alias is about naming and public intent, not a different runtime implementation.

2. Use `build_application_logger(...)` or `parse_and_build_application_logger(...)` for the usual construction paths.
