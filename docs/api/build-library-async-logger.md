---
name: build-library-async-logger
group: api
category: facade
update-time: 20260614
description: Build the library-facing async logger facade from an AsyncLoggerBuildConfig while intentionally hiding direct async state helpers.
key-word:
    - library
    - async
    - facade
    - public
---

## Build-library-async-logger

Build a `LibraryAsyncLogger[RuntimeSink]` from `AsyncLoggerBuildConfig`. This is the library-facing async facade over the general config-driven async builder.

### Interface

```moonbit
pub fn build_library_async_logger(
  config : AsyncLoggerBuildConfig,
) -> LibraryAsyncLogger[RuntimeSink] {
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined sync logger config and async queue/runtime config.

#### output

- `LibraryAsyncLogger[RuntimeSink]` - Library-facing async logger wrapper.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API builds the general async runtime logger and then wraps it in the narrower `LibraryAsyncLogger[@bitlogger.RuntimeSink]` facade.
- The embedded `LoggerConfig` still goes through the normal synchronous config path first, so sink shape and any optional synchronous queue layer are already applied before the outer async layer is wrapped and then narrowed.
- The result keeps async lifecycle operations such as `run()` and `shutdown()` while narrowing the public shape.
- Async state helpers such as `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, and failure-status inspection remain on the underlying `AsyncLogger`, not on the returned facade itself.
- `to_async_logger()` can be used to recover the underlying full async logger.

### How to Use

Here are some specific examples provided.

#### When Need A Narrower Async Type For Libraries

When a reusable package should expose async logging but not the full runtime type directly:
```moonbit
let logger = build_library_async_logger(
  AsyncLoggerBuildConfig::new(
    logger=LoggerConfig::new(target="lib.async"),
    async_config=AsyncLoggerConfig::new(max_pending=4),
  ),
)
```

In this example, async runtime construction is hidden behind the library facade.

#### When Need Async State Helpers After Library-oriented Construction

When config-built async state inspection is still needed internally:
```moonbit
let logger = build_library_async_logger(config)
let full = logger.to_async_logger()
ignore(full.pending_count())
```

In this example, the library async facade is unwrapped before using async state helpers.

### Error Case

e.g.:
- If backend-specific sink limitations exist, they still apply under the facade.

- If callers need async state, failure-status, or idle-wait helpers outside the library facade, they must unwrap with `to_async_logger()`.

### Notes

1. Prefer this API when library boundaries should stay narrow.

2. Use `parse_and_build_library_async_logger(...)` when starting from JSON text.
