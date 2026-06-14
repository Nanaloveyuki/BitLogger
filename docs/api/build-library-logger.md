---
name: build-library-logger
group: api
category: facade
update-time: 20260613
description: Build the library-facing sync logger facade from a LoggerConfig by delegating to the configured runtime logger build path and then wrapping the result.
key-word:
    - library
    - facade
    - logger
    - public
---

## Build-library-logger

Build a `LibraryLogger[RuntimeSink]` from `LoggerConfig`. This facade keeps a smaller library-oriented sync surface while still using config-driven runtime assembly underneath.

### Interface

```moonbit
pub fn build_library_logger(config : LoggerConfig) -> LibraryLogger[RuntimeSink] {
```

#### input

- `config : LoggerConfig` - Fully assembled sync logger config.

#### output

- `LibraryLogger[RuntimeSink]` - Library-facing logger wrapper over the configured runtime sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API builds a configured runtime logger first and then wraps that same value as `LibraryLogger[RuntimeSink]`.
- The embedded config still goes through the normal runtime logger build path, including runtime sink selection, optional queue wrapping, and timestamp application.
- The returned facade wraps the same underlying `ConfiguredLogger` value that `build_logger(...)` would produce directly.
- The facade intentionally exposes a smaller logging surface than the full configured runtime logger.
- In particular, the configured runtime helper surface is preserved rather than rebuilt, but it is intentionally not directly exposed on the returned facade. Queue metrics, flush or drain helpers, and file controls stay behind `to_logger()` instead of disappearing.
- The facade still preserves the underlying logger target rules on its exposed write methods: `log(..., target=...)` can override the target for one write, while `info(...)`, `warn(...)`, and `error(...)` continue using the stored logger target unless the facade first derived another logger with `with_target(...)` or `child(...)`.
- Queue metrics, flush and drain helpers, and file runtime controls remain on the underlying `ConfiguredLogger`, not on the returned facade itself.
- Call `to_logger()` if a caller must recover the underlying full logger object.
- Use this builder when the boundary should preserve the configured runtime logger path but still hide broader runtime helper methods from downstream callers.

### How to Use

Here are some specific examples provided.

#### When Need A Smaller Library-facing Logging Type

When package code should accept or produce a narrower logger facade:
```moonbit
let logger = build_library_logger(
  LoggerConfig::new(target="lib", sink=SinkConfig::new(kind=SinkKind::Console)),
)
```

In this example, the logger is built from config and then narrowed to the library facade.

#### When Need Runtime Helpers After Library-oriented Construction

When config-built runtime queue or file controls are still needed internally:
```moonbit
let logger = build_library_logger(config)
let full = logger.to_logger()
ignore(full.sink.pending_count())
```

In this example, the library facade is unwrapped before using runtime-specific helpers through the preserved `RuntimeSink` value.

And the unwrapped value still carries the same `RuntimeSink` pipeline built from the original config.

And unlike `ApplicationLogger`, the narrower builder result does not expose those runtime helpers directly on the facade surface.

#### When Need A Per-call Target Override Through The Library Builder Facade

When typed library config should still build a facade that allows a one-write target override without unwrapping first:
```moonbit
let logger = build_library_logger(config)
logger.log(Level::Error, "boom", target="lib.audit")
```

In this example, the emitted record uses `lib.audit` for that write.

And later `info(...)`, `warn(...)`, or `error(...)` calls still use the facade's stored target unless code derives another facade first with `with_target(...)` or `child(...)`.

### Error Case

e.g.:
- If backend-specific sink limitations exist, they still apply after the facade is built.

- If code later needs queue metrics, flush or drain helpers, or file runtime controls, it must unwrap with `to_logger()`.

### Notes

1. Prefer this facade when library APIs should not expose the full configured runtime logger type.

2. Use `parse_and_build_library_logger(...)` when starting from JSON text.

3. Use `to_logger()` when internal code later needs broader logger composition or direct access to the preserved `RuntimeSink` value without changing the public facade type.
