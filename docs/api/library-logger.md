---
name: library-logger
group: api
category: facade
update-time: 20260613
description: Public library-facing sync logger facade type used to expose a narrower surface than Logger while preserving the wrapped logger state.
key-word:
    - library
    - logger
    - facade
    - public
---

## Library-logger

`LibraryLogger[S]` is the public library-facing sync logger facade type. It wraps `Logger[S]` and keeps standard logging behavior while intentionally exposing a narrower public surface for package boundaries.

### Interface

```moonbit
pub struct LibraryLogger[S] {
  inner : Logger[S]
}
```

#### output

- `LibraryLogger[S]` - Public library-oriented sync logger wrapper over a concrete sink type `S`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public facade struct, not a type alias.
- The wrapped sink type `S` is preserved, so sink-specific typing remains available through the facade type parameter.
- The facade keeps common library-safe operations such as `new(...)`, `with_target(...)`, `child(...)`, `bind(...)`, `is_enabled(...)`, and the main write methods `log(...)`, `info(...)`, `warn(...)`, and `error(...)`.
- The facade wraps the same underlying `Logger[S]` value rather than copying or rebuilding it.
- It does not expose the wider `Logger[S]` composition surface or `ConfiguredLogger` runtime helper methods directly.
- Most facade reshaping helpers keep the same visible sink type, but `with_context_fields(...)` and `bind(...)` intentionally return `LibraryLogger[ContextSink[S]]` because they extend the sink pipeline.
- Call `to_logger()` when later code must recover the full underlying `Logger[S]` surface.

### How to Use

Here are some specific examples provided.

#### When Need A Narrower Public Sync Logger Type

When a package should expose logging capability without publishing the full `Logger[S]` API:
```moonbit
let logger : LibraryLogger[ConsoleSink] = LibraryLogger::new(console_sink(), target="lib")
```

In this example, the package boundary exposes the library facade instead of the full logger type.

#### When Need To Recover The Full Logger Later

When a library-facing facade should later be adapted back into the ordinary sync logger surface:
```moonbit
let full = logger.to_logger()
full.info("started")
```

In this example, the facade can be unwrapped when broader logger operations are needed internally.

And the unwrapped value still carries the same target and sink pipeline that existed behind the library facade.

### Error Case

e.g.:
- `LibraryLogger[S]` itself does not have a runtime failure mode.

- Runtime behavior still depends on the wrapped sink `S`, so any sink-specific limitations remain unchanged behind the facade.

- If the wrapped sink type is `RuntimeSink`, queue and file runtime helpers still exist on the underlying logger but are not callable through `LibraryLogger[RuntimeSink]` unless it is unwrapped with `to_logger()`.

- If callers need direct composition helpers such as `with_timestamp(...)`, `with_filter(...)`, or `with_patch(...)`, they must unwrap first with `to_logger()`.

### Notes

1. Use `LibraryLogger::new(...)`, `build_library_logger(...)`, or `parse_and_build_library_logger(...)` when you need a value of this type.

2. Use `Logger[S]` directly when exposing the full sync composition surface is acceptable.

3. Use `to_logger()` when internal code later needs broader composition or runtime-helper access without changing the public facade type.
