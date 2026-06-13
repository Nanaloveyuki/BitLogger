---
name: application-text-async-logger
group: api
category: facade
update-time: 20260614
description: Application-facing alias for the text-console async logger surface, preserving the full AsyncLogger helper set for the concrete text sink shape.
key-word:
    - application
    - async
    - text
    - public
---

## Application-text-async-logger

`ApplicationTextAsyncLogger` is the application-facing async logger alias for text-console output. It currently maps directly to `AsyncLogger[@bitlogger.FormattedConsoleSink]` and keeps the same async lifecycle and queue helper surface while preserving the concrete text sink shape.

### Interface

```moonbit
pub type ApplicationTextAsyncLogger = AsyncLogger[@bitlogger.FormattedConsoleSink]
```

#### output

- `ApplicationTextAsyncLogger` - Application-facing name for the text-console async logger shape.

### Explanation

Detailed rules explaining key parameters and behaviors

- This alias does not introduce a new runtime type or wrapper layer.
- It preserves the same async lifecycle helpers as other async logger aliases.
- Because this is only an alias, methods that are async on `AsyncLogger[@bitlogger.FormattedConsoleSink]` remain async here as well.
- The alias therefore keeps the same text-console-specific builder and lifecycle semantics already documented on `AsyncLogger[@bitlogger.FormattedConsoleSink]`, including the concrete sink shape and runtime-dependent close/failure behavior.
- The application-facing type does not hide any async state or lifecycle helpers; queue/backlog/failure inspection remains directly available on this alias just as it is on the underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]`.
- When the value is built through `build_application_text_async_logger(...)`, the direct async counters come from the outer async logger only; any optional sync queue configured on `LoggerConfig.queue` is not carried into this text-specific build path.
- The alias exists to give application code a clearer public name when it wants the concrete text-console sink shape explicitly.
- `build_application_text_async_logger(...)` returns this alias.

### How to Use

Here are some specific examples provided.

#### When Need An App-level Name For Text-console Async Output

When application code wants a stable type name for a text-console async logger:
```moonbit
let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
  AsyncLoggerBuildConfig::new(logger=text_console(target="app.text.async")),
)
```

In this example, the application alias keeps the same underlying async logger behavior while preserving the text sink shape explicitly.

#### When Pass A Text-console Async Logger Through App-level APIs

When caller code should know it is working with the text-console variant:
```moonbit
async fn start_text_async(logger : ApplicationTextAsyncLogger) -> Unit {
  logger.run()
}
```

In this example, the app-facing alias communicates the concrete text-console async shape directly, while `run()` keeps its async calling contract.

And the same pending-count, state, and failure helpers remain directly available because no narrowing wrapper is added.

### Error Case

e.g.:
- Because this is only an alias, any async target limitations or runtime behavior still apply unchanged.

- If code does not need the concrete text-console sink shape, `ApplicationAsyncLogger` is the broader runtime-sink async alias.

### Notes

1. This alias is about naming and public intent, not a different async implementation.

2. Use `build_application_text_async_logger(...)` when callers want the `FormattedConsoleSink`-backed async type explicitly.

3. Use `ApplicationAsyncLogger` when application code should keep the broader runtime-sink shape instead of the text-console-specific one.

4. Use `LibraryAsyncLogger[@bitlogger.FormattedConsoleSink]` instead when a library boundary should intentionally narrow the exposed async surface while still preserving the concrete text sink type.
