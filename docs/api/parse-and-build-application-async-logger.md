---
name: parse-and-build-application-async-logger
group: api
category: facade
update-time: 20260614
description: Parse JSON async build config text and build the application-facing async logger facade through the sync-first async builder path.
key-word:
    - application
    - async
    - parse
    - public
---

## Parse-and-build-application-async-logger

Parse raw JSON async build config text and build an `ApplicationAsyncLogger` in one step. This facade is the application-oriented counterpart to `parse_async_logger_build_config_text(...)` plus `build_application_async_logger(...)`.

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

- This API parses async build config text first, then builds the async application facade.
- Both the embedded sync logger config and async queue/runtime config are validated by the parser layer.
- The embedded `LoggerConfig` is then built through the normal synchronous config path before the outer async layer is applied.
- The returned logger keeps the normal async lifecycle and state helpers.

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

### Error Case

e.g.:
- If the JSON text is malformed, parsing raises an error.

- If the embedded config is invalid, parsing raises before the async facade is returned.

### Notes

1. Use this facade when application boot starts from JSON text.

2. Use `build_application_async_logger(...)` when config is already typed as `AsyncLoggerBuildConfig`.
