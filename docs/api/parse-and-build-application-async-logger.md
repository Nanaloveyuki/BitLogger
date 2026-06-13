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
- Because the result is the `ApplicationAsyncLogger` alias over `AsyncLogger[@bitlogger.RuntimeSink]`, this parse-and-build path does not narrow the helper surface.
- The returned logger keeps the full async lifecycle and state helpers directly.

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

### Error Case

e.g.:
- If the JSON text is malformed, parsing raises an error.

- If the embedded config is invalid, parsing raises before the async facade is returned.

### Notes

1. Use this facade when application boot starts from JSON text.

2. Use `build_application_async_logger(...)` when config is already typed as `AsyncLoggerBuildConfig`.

3. Use `parse_and_build_library_async_logger(...)` instead when text-driven construction should narrow the public async surface for a library boundary.
