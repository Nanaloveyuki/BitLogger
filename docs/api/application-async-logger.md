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
- Because it is `AsyncLogger[@bitlogger.RuntimeSink]`, the alias also keeps ordinary async logger composition and target behavior such as `with_target(...)`, `child(...)`, and per-call `log(..., target=...)` overrides.
- In particular, `log(..., target=...)` can override the target for one call, while severity helpers such as `info(...)`, `warn(...)`, and `error(...)` continue using the stored logger target unless code derives another logger first with `with_target(...)` or `child(...)`.
- Unlike the synchronous application alias, async `with_context_fields(...)` and `bind(...)` preserve the visible `ApplicationAsyncLogger` shape because shared fields are stored directly on the async logger value instead of being modeled as a separate sink wrapper.
- Because this is only an alias, methods that are async on `AsyncLogger[@bitlogger.RuntimeSink]` remain async here as well.
- The alias therefore keeps the same runtime-sink lifecycle, queue, failure-state, and runtime-dependent post-close semantics already documented on `AsyncLogger[@bitlogger.RuntimeSink]`.
- In the current direct alias coverage, values built through `build_application_async_logger(...)` keep the same serialized state snapshot shape, queue counters, lifecycle flags, failure fields, and runtime-sink helper surface that the underlying runtime-sink async logger exposes directly.
- That includes queued runtime-sink behavior and file-backed runtime helpers when the configured sink path supports them.
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

And the inherited async logger target rules stay the same: `log(..., target=...)` can override the target per call, while `info(...)`, `warn(...)`, and `error(...)` continue using the stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

#### When Need A One-call Target Override Without Rebuilding The Alias

When app-level async code should keep the same alias value but emit one record under a different target:
```moonbit
logger.log(@bitlogger.Level::Error, "boom", target="app.async.audit")
```

In this example, the emitted record uses `app.async.audit` only for that one call.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the alias value's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

#### When Need Shared Context On The Async Application Alias

When app-level async code should attach stable metadata to later queued records:
```moonbit
let contextual = logger.with_context_fields([@bitlogger.field("service", "billing")])
```

In this example, the returned value still has the visible type `ApplicationAsyncLogger`.

And that shape preservation is intentional because async context binding updates stored logger metadata instead of changing the exposed sink type.

### Error Case

e.g.:
- Because this is only an alias, any runtime-sink limitations or target-specific async behavior still apply unchanged.

- If code needs a narrower public surface than the full async logger API, `LibraryAsyncLogger` is the better facade.

- If callers need queued runtime-sink helpers or file-backed runtime helpers, they remain directly available on this alias because no wrapper layer strips them away.

### Notes

1. This alias is about naming and public intent, not a different async implementation.

2. Inherited `AsyncLogger` behavior stays unchanged on this alias, including target overrides on `log(...)` and derived target composition through `with_target(...)` and `child(...)`.

3. Use `build_application_async_logger(...)` or `parse_and_build_application_async_logger(...)` for the usual construction paths.

4. Use `ApplicationTextAsyncLogger` or `build_application_text_async_logger(...)` when application code should keep the narrower text-console sink type instead of the broader runtime-sink alias.
