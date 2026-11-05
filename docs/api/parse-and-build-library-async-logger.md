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

Parse raw JSON async build config text and build a `LibraryAsyncLogger[AsyncRuntimeSink]` in one step. This facade is the text-driven library counterpart to `parse_async_logger_build_config_text(...)` plus `build_library_async_logger(...)`.

### Interface

```moonbit
pub fn parse_and_build_library_async_logger(
  input : String,
) -> LibraryAsyncLogger[AsyncRuntimeSink] raise {
```

#### input

- `input : String` - Raw JSON async logger build config text.

#### output

- `LibraryAsyncLogger[AsyncRuntimeSink]` - Library-facing async runtime logger wrapper.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API parses async build config text, validates it, builds the async runtime logger through `build_library_async_logger(...)`, and narrows it to the library facade.
- Both the embedded sync logger config and async queue/runtime config are validated by the parser layer before any facade value is returned.
- The embedded `LoggerConfig` first goes through the sync config path, which selects a `RuntimeSink` variant and applies any optional sync queue. `AsyncRuntimeSink` then wraps that shared state before the library facade narrows the logger surface.
- The parsed `logger.sink.kind` therefore determines the wrapped runtime variant before the library facade narrows the helper surface.
- The returned facade wraps the same underlying `AsyncLogger[AsyncRuntimeSink]` value that the direct parse plus `build_async_logger(...)` path produces.
- The resulting facade keeps library-facing async operations such as `run()` and `shutdown()` while exposing a smaller public surface.
- The broader async helper surface is still preserved rather than rebuilt, but it is intentionally not directly exposed on the returned facade. Queue counters, lifecycle state, idle-wait helpers, and file-backed runtime helpers stay behind `to_async_logger()` instead of disappearing.
- The narrower facade does not change the underlying runtime-sink queue counters, failure state, sink shape, or runtime-dependent post-close behavior; it only hides the broader helper surface until `to_async_logger()` is used.
- The narrower facade also preserves the underlying target rules on its exposed write methods: `log(..., target=...)` can override the target for one call, while `info(...)`, `warn(...)`, and `error(...)` continue using the stored logger target unless the facade first derived another logger with `with_target(...)` or `child(...)`.
- In the current parsed-builder coverage, unwrapping this facade yields the same async state snapshot, async sink-kind choice, queue counters, lifecycle flags, and failure fields as `build_async_logger(parse_async_logger_build_config_text(input))`.
- Parsed file-backed runtime helpers remain available through the unwrapped logger's `AsyncRuntimeSink` rather than being rebuilt into facade-specific sink state.
- Async state helpers such as `pending_count()`, `dropped_count()`, `state()`, `wait_idle()`, and failure-status inspection stay on the underlying `AsyncLogger`, not on the returned facade itself.
- `to_async_logger()` can recover the underlying async logger when a wider API is required.
- Use this parse/build facade when text-driven construction should preserve the runtime-sink build path but still hide broader async inspection helpers at the package boundary.

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

Configured synchronous runtime controls remain active inside the `AsyncRuntimeSink` wrapped by the returned async logger.

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

And unlike `ApplicationAsyncLogger`, the narrower parse/build result does not expose those broader async helpers directly on the facade surface.

#### When Need A Per-call Target Override Through The Library Facade

When parsed library configuration should still allow a one-call target override without unwrapping first:
```moonbit
let logger = parse_and_build_library_async_logger(raw) catch {
  err => return
}
logger.log(@bitlogger.Level::Error, "boom", target="lib.audit")
```

In this example, the emitted record uses `lib.audit` for that call.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the facade's stored target unless code derives another facade first with `with_target(...)` or `child(...)`.

### Error Case

e.g.:
- If the JSON text is malformed, parsing raises an error.

- If the embedded config is invalid, parsing raises before the library facade is returned.

- If callers assume async state or idle-wait helpers are available directly on the returned facade, they must unwrap first with `to_async_logger()`.

- If callers need file-backed runtime helpers after parse/build, they must unwrap first, but the resulting helper surface still matches the parsed direct builder path.

- If callers depend on queued or file-backed runtime behavior, this facade preserves the sync-first sink selection and queue setup inside `AsyncRuntimeSink`; it does not expose a root `RuntimeSink` directly.

### Notes

1. This is the narrow async library parse-and-build facade.

2. Use `build_library_async_logger(...)` when the config is already typed.

3. Use `build_library_async_text_logger(...)` instead when callers want the narrower `FormattedConsoleSink` text-console async shape rather than `AsyncRuntimeSink`.
