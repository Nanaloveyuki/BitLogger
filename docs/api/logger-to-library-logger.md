---
name: logger-to-library-logger
group: api
category: facade
update-time: 20260613
description: Convert a full sync logger into the narrower library-facing sync facade without rebuilding the underlying logger state.
key-word:
    - logger
    - library
    - facade
    - public
---

## Logger-to-library-logger

Convert `Logger[S]` into `LibraryLogger[S]`. This keeps the same sink and logging behavior while projecting the value onto the smaller library-facing sync surface.

### Interface

```moonbit
pub fn[S] Logger::to_library_logger(self : Logger[S]) -> LibraryLogger[S] {}
```

#### input

- `self : Logger[S]` - Full sync logger to project into the library facade.

#### output

- `LibraryLogger[S]` - Narrower library-facing wrapper over the same logger state.

### Explanation

Detailed rules explaining key parameters and behaviors

- This conversion does not rebuild the sink or change the logger configuration.
- Target, min level, timestamp behavior, and sink wiring are preserved because the same underlying logger value is wrapped.
- The returned facade keeps library-oriented write APIs such as `info(...)`, `warn(...)`, and `error(...)`.
- Broader sync composition helpers remain on the underlying `Logger[S]` and are intentionally hidden until `to_logger()` is used again.

### How to Use

Here are some specific examples provided.

#### When Need To Return A Narrower Library Type

When internal setup uses the full logger API but the exposed result should stay smaller:
```moonbit
let logger = Logger::new(console_sink(), target="lib")
let public_logger = logger.to_library_logger()
```

In this example, `public_logger` keeps the same logging behavior but exposes the library facade.

#### When Need To Narrow Surface Without Resetting Logger Composition

When an already-shaped logger should be projected to a library boundary without losing its current wrappers:
```moonbit
let full = Logger::new(console_sink(), target="lib").with_timestamp()
let public_logger = full.to_library_logger()
```

In this example, the projection changes the exposed type only; it does not remove the existing timestamp behavior or other logger state.

### Error Case

e.g.:
- If callers later need APIs outside the library facade, they must unwrap with `to_logger()`.

- The conversion does not remove existing target or field bindings from the original logger.

- If callers later need composition helpers such as `with_timestamp(...)`, `with_filter(...)`, or `with_patch(...)`, they must unwrap again with `to_logger()`.

### Notes

1. Use this when library boundaries should avoid exposing the full sync logger surface.

2. This is a projection API, not a copy or rebuild step.

3. Use `build_library_logger(...)` or `parse_and_build_library_logger(...)` when construction and narrowing should happen together from config.
