---
name: build-library-logger
group: api
category: facade
update-time: 20260613
description: Build the library-facing sync logger facade from a LoggerConfig and intentionally hide direct runtime helper methods.
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

- This API builds a configured runtime logger first and then wraps it as `LibraryLogger[RuntimeSink]`.
- The facade intentionally exposes a smaller logging surface than the full configured runtime logger.
- Queue metrics, flush and drain helpers, and file runtime controls remain on the underlying `ConfiguredLogger`, not on the returned facade itself.
- Call `to_logger()` if a caller must recover the underlying full logger object.

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
ignore(full.pending_count())
```

In this example, the library facade is unwrapped before using configured runtime helper methods.

### Error Case

e.g.:
- If backend-specific sink limitations exist, they still apply after the facade is built.

- If code later needs queue metrics, flush or drain helpers, or file runtime controls, it must unwrap with `to_logger()`.

### Notes

1. Prefer this facade when library APIs should not expose the full configured runtime logger type.

2. Use `parse_and_build_library_logger(...)` when starting from JSON text.
