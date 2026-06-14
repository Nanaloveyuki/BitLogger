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
- Because it is `AsyncLogger[@bitlogger.FormattedConsoleSink]`, the alias also keeps ordinary async logger composition and target behavior such as `with_target(...)`, `child(...)`, and per-call `log(..., target=...)` overrides.
- In particular, `log(..., target=...)` can override the target for one call, while severity helpers such as `info(...)`, `warn(...)`, and `error(...)` continue using the stored logger target unless code derives another logger first with `with_target(...)` or `child(...)`.
- Like the broader runtime-sink async alias, `with_context_fields(...)` and `bind(...)` preserve the visible `ApplicationTextAsyncLogger` shape because shared fields are stored directly on the async logger value instead of being modeled as a separate sink wrapper.
- Because this is only an alias, methods that are async on `AsyncLogger[@bitlogger.FormattedConsoleSink]` remain async here as well.
- The alias therefore keeps the same text-console-specific builder and lifecycle semantics already documented on `AsyncLogger[@bitlogger.FormattedConsoleSink]`, including the concrete sink shape plus the same close, queue, and failure-state behavior.
- The application-facing type does not hide any async state or lifecycle helpers; queue/backlog/failure inspection remains directly available on this alias just as it is on the underlying `AsyncLogger[@bitlogger.FormattedConsoleSink]`.
- In the current direct alias coverage, values built through `build_application_text_async_logger(...)` keep the same serialized state snapshot shape, formatter behavior, queue counters, lifecycle flags, and failure fields that the underlying text-console async logger exposes directly.
- When the value is built through `build_application_text_async_logger(...)`, the direct async counters come from the outer async logger only; any optional sync queue configured on `LoggerConfig.queue` is not carried into this text-specific build path.
- When the value is built through `build_application_text_async_logger(...)`, `logger.sink.kind` also does not decide the runtime sink shape. The builder still constructs `FormattedConsoleSink` from `logger.sink.text_formatter`, even if the config said `Console`, `JsonConsole`, or `File`.
- When the value is built through `build_application_text_async_logger(...)`, `flush_policy()` still reports the configured async policy, but the text-specific build path keeps the default no-op async flush callback instead of wiring an explicit sink flush step.
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

And the inherited async logger target rules stay the same: `log(..., target=...)` can override the target per call, while `info(...)`, `warn(...)`, and `error(...)` continue using the stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

#### When Need A One-call Target Override On The Text-console Alias

When app-level text-console async code should keep the same alias value but emit one record under a different target:
```moonbit
logger.log(@bitlogger.Level::Error, "boom", target="app.text.async.audit")
```

In this example, the emitted record uses `app.text.async.audit` only for that one call.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the alias value's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

#### When Need Shared Context On The Text-console Async Alias

When app-level text-console async code should attach stable metadata to later queued records:
```moonbit
let contextual = logger.with_context_fields([@bitlogger.field("service", "billing")])
```

In this example, the returned value still has the visible type `ApplicationTextAsyncLogger`.

And that shape preservation is intentional because async context binding updates stored logger metadata instead of changing the exposed sink type.

### Error Case

e.g.:
- Because this is only an alias, any async target limitations or runtime behavior still apply unchanged.

- If code does not need the concrete text-console sink shape, `ApplicationAsyncLogger` is the broader runtime-sink async alias.

- If the value came from `build_application_text_async_logger(...)`, carrying `logger.sink.kind=File` in the config still does not make this alias file-backed; that builder keeps the formatter-driven text-console path.

- If callers depend on the concrete formatter or direct text-console helper surface, they remain available on this alias because no wrapper layer narrows them away.

### Notes

1. This alias is about naming and public intent, not a different async implementation.

2. Inherited `AsyncLogger` behavior stays unchanged on this alias, including target overrides on `log(...)` and derived target composition through `with_target(...)` and `child(...)`.

3. Use `build_application_text_async_logger(...)` when callers want the `FormattedConsoleSink`-backed async type explicitly.

4. Use `ApplicationAsyncLogger` when application code should keep the broader runtime-sink shape instead of the text-console-specific one.

5. Use `LibraryAsyncLogger[@bitlogger.FormattedConsoleSink]` instead when a library boundary should intentionally narrow the exposed async surface while still preserving the concrete text sink type.
