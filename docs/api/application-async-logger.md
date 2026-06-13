---
name: application-async-logger
group: api
category: facade
update-time: 20260614
description: Application-facing alias for the runtime-sink async logger surface, preserving the same async calling semantics as AsyncLogger.
key-word:
    - application
    - async
    - alias
    - public
---

## Application-async-logger

`ApplicationAsyncLogger` is the application-facing async logger alias. It currently maps directly to `AsyncLogger[@bitlogger.RuntimeSink]` and keeps the same async lifecycle, state, and queue helper surface.

### Interface

```moonbit
pub type ApplicationAsyncLogger = AsyncLogger[@bitlogger.RuntimeSink]
```

#### output

- `ApplicationAsyncLogger` - Application-facing name for the runtime-sink async logger shape.

### Explanation

Detailed rules explaining key parameters and behaviors

- This alias does not introduce a new runtime type or wrapper layer.
- It preserves the same async lifecycle helpers such as `run()`, `shutdown()`, `pending_count()`, and `state()`.
- Because this is only an alias, methods that are async on `AsyncLogger[@bitlogger.RuntimeSink]` remain async here as well.
- The alias exists to give application boot code a clearer public type name for the standard runtime-sink async logger.
- Builders such as `build_application_async_logger(...)` and `parse_and_build_application_async_logger(...)` return this alias.

### How to Use

Here are some specific examples provided.

#### When Need An App-level Name For The Standard Async Runtime Logger

When application code wants a stable public type name for the runtime-sink async logger:
```moonbit
let logger : ApplicationAsyncLogger = build_application_async_logger(
  AsyncLoggerBuildConfig::new(logger=LoggerConfig::new(target="app.async")),
)
```

In this example, the application alias keeps the same underlying async logger behavior while presenting an app-facing type name.

#### When Pass The Async Logger Through App-level APIs

When top-level boot code or services should expose an application-oriented async logger type:
```moonbit
async fn start_async(logger : ApplicationAsyncLogger) -> Unit {
  logger.run()
}
```

In this example, callers see the app-facing alias instead of the more explicit generic async logger spelling, while `run()` keeps its async calling contract.

### Error Case

e.g.:
- Because this is only an alias, any runtime-sink limitations or target-specific async behavior still apply unchanged.

- If code needs a narrower public surface than the full async logger API, `LibraryAsyncLogger` is the better facade.

### Notes

1. This alias is about naming and public intent, not a different async implementation.

2. Use `build_application_async_logger(...)` or `parse_and_build_application_async_logger(...)` for the usual construction paths.
