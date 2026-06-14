---
name: parse-and-build-application-async-logger
group: api
category: facade
update-time: 20260614
description: Parse JSON async build config text and build the application-facing runtime-sink async logger alias through the sync-first async builder path.
key-word:
    - application
    - async
    - parse
    - public
---

## Parse-and-build-application-async-logger

Parse raw JSON async build config text and build an `ApplicationAsyncLogger` in one step. This is the application-oriented counterpart to `parse_async_logger_build_config_text(...)` plus `build_application_async_logger(...)`.

### Interface

```moonbit
pub fn parse_and_build_application_async_logger(
  input : String,
) -> ApplicationAsyncLogger raise {
```

#### input

- `input : String` - Raw JSON async logger build config text.

#### output

- `ApplicationAsyncLogger` - Application-facing async runtime logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API parses async build config text first, then builds the application async logger through `build_application_async_logger(...)`.
- Both the embedded sync logger config and async queue/runtime config are validated by the parser layer.
- The embedded `LoggerConfig` is then built through the normal synchronous config path before the outer async layer is applied.
- Any optional synchronous queue layer and runtime-sink controls from the parsed `logger` section remain active under the returned async logger.
- That includes preserving a parsed sync queue configuration inside the resulting `RuntimeSink` variant rather than collapsing it away during application-alias construction.
- Because the result is the `ApplicationAsyncLogger` alias over `AsyncLogger[@bitlogger.RuntimeSink]`, this parse-and-build path returns the same underlying async logger value that `parse_async_logger_build_config_text(...)` plus `build_async_logger(...)` would produce, without narrowing the helper surface.
- That preserved async helper surface also remains directly exposed on the returned alias rather than being rebuilt or hidden behind an unwrap step.
- The returned logger keeps the full async lifecycle and state helpers directly.
- The returned logger also keeps the ordinary async logger target rules unchanged: `log(..., target=...)` can override the target for one call, while severity helpers such as `info(...)`, `warn(...)`, and `error(...)` continue to use the stored logger target unless a derived logger was created first with `with_target(...)` or `child(...)`.
- In the current parsed-builder coverage, that direct equivalence also holds for serialized async state snapshots, runtime-sink variant choice, queue counters, lifecycle flags, and later failure fields after worker execution.
- Parsed file-backed runtime helpers remain available on the returned logger with the same behavior as the direct `build_async_logger(parse_async_logger_build_config_text(input))` path.
- Use `parse_and_build_library_async_logger(...)` instead when the same parsed runtime-sink result should be wrapped and narrowed for a library boundary.

### How to Use

Here are some specific examples provided.

#### When Need App Async Boot Directly From JSON

When async config is sourced as text and should become a running-capable facade immediately:
```moonbit
let logger = parse_and_build_application_async_logger(
  "{\"logger\":{\"target\":\"app.async\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":4,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
)
```

In this example, text parsing and async logger construction happen in one facade call.

And any configured synchronous runtime sink controls remain available through the returned `RuntimeSink`-backed async logger.

And unlike `parse_and_build_library_async_logger(...)`, no `to_async_logger()` unwrap is required to reach queue, lifecycle, or file-backed runtime helpers.

#### When Need Async State Helpers After JSON-driven App Construction

When application boot should parse JSON text and still keep direct access to async helper APIs:
```moonbit
let logger = parse_and_build_application_async_logger(raw) catch {
  err => return
}
ignore(logger.pending_count())
ignore(logger.state())
```

In this example, no unwrap step is needed because the application result is an alias, not a narrowing facade.

#### When Need A Per-call Target Override After JSON Boot

When parsed app configuration should keep the same direct target override behavior as the ordinary async logger:
```moonbit
let logger = parse_and_build_application_async_logger(raw) catch {
  err => return
}
logger.log(@bitlogger.Level::Error, "boom", target="app.audit")
```

In this example, the emitted record uses `app.audit` for that call.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

### Error Case

e.g.:
- If the JSON text is malformed, parsing raises an error.

- If the embedded config is invalid, parsing raises before the async facade is returned.

- If callers depend on file-backed runtime helpers, they can use them directly on the returned logger because this parse/build alias does not replace the underlying runtime-sink helper surface.

### Notes

1. Use this facade when application boot starts from JSON text.

2. Use `build_application_async_logger(...)` when config is already typed as `AsyncLoggerBuildConfig`.

3. Use `parse_and_build_library_async_logger(...)` instead when text-driven construction should narrow the public async surface for a library boundary.
