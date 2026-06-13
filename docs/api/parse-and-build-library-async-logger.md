---
name: parse-and-build-library-async-logger
group: api
category: facade
update-time: 20260614
description: Parse JSON async build config text and build the library-facing async logger facade through the sync-first async builder path.
key-word:
    - library
    - async
    - parse
    - public
---

## Parse-and-build-library-async-logger

Parse raw JSON async build config text and build a `LibraryAsyncLogger[RuntimeSink]` in one step. This facade is the text-driven library counterpart to `parse_async_logger_build_config_text(...)` plus `build_library_async_logger(...)`.

### Interface

```moonbit
pub fn parse_and_build_library_async_logger(
  input : String,
) -> LibraryAsyncLogger[RuntimeSink] raise {
```

#### input

- `input : String` - Raw JSON async logger build config text.

#### output

- `LibraryAsyncLogger[RuntimeSink]` - Library-facing async runtime logger wrapper.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API parses async build config text, validates it, builds the async runtime logger through `build_library_async_logger(...)`, and narrows it to the library facade.
- Both the embedded sync logger config and async queue/runtime config are validated by the parser layer before any facade value is returned.
- The embedded `LoggerConfig` still goes through the normal synchronous config path first, so sink shape and any optional synchronous queue layer are already applied before the outer async layer is wrapped and then narrowed.
- The resulting facade keeps library-facing async operations such as `run()` and `shutdown()` while exposing a smaller public surface.
- The narrower facade does not change the underlying runtime-sink failure/reset or runtime-dependent close semantics; it only hides the broader helper surface until `to_async_logger()` is used.
- Async state helpers such as `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, and failure-status inspection stay on the underlying `AsyncLogger`, not on the returned facade itself.
- `to_async_logger()` can recover the underlying async logger when a wider API is required.

### How to Use

Here are some specific examples provided.

#### When Need Text-driven Async Library Bootstrapping

When a package accepts raw config text but wants a narrower async facade output:
```moonbit
let logger = parse_and_build_library_async_logger(
  "{\"logger\":{\"target\":\"lib.async\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":4,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
)
```

In this example, parsing and library-facade construction happen together.

And any configured synchronous runtime sink controls remain active under the returned `RuntimeSink`-backed async logger.

#### When Need Async State Helpers After Text-driven Library Bootstrapping

When JSON-driven construction should still allow internal async state inspection later:
```moonbit
let logger = parse_and_build_library_async_logger(raw) catch {
  err => return
}
let full = logger.to_async_logger()
ignore(full.pending_count())
```

In this example, the caller unwraps the library async facade before using async state helpers.

### Error Case

e.g.:
- If the JSON text is malformed, parsing raises an error.

- If the embedded config is invalid, parsing raises before the library facade is returned.

- If callers assume async state or idle-wait helpers are available directly on the returned facade, they must unwrap first with `to_async_logger()`.

### Notes

1. This is the narrow async library parse-and-build facade.

2. Use `build_library_async_logger(...)` when the config is already typed.

3. Use `build_library_async_text_logger(...)` instead when callers want the narrower `FormattedConsoleSink` text-console async shape rather than `RuntimeSink`.
