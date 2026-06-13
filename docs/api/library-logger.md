---
name: library-logger
group: api
category: facade
update-time: 20260613
description: Public library-facing sync logger facade type used to expose a narrower surface than Logger.
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
- The facade keeps common library-safe operations such as `new(...)`, `with_target(...)`, `child(...)`, `bind(...)`, `is_enabled(...)`, and the main write methods.
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

### Error Case

e.g.:
- `LibraryLogger[S]` itself does not have a runtime failure mode.

- Runtime behavior still depends on the wrapped sink `S`, so any sink-specific limitations remain unchanged behind the facade.

### Notes

1. Use `LibraryLogger::new(...)`, `build_library_logger(...)`, or `parse_and_build_library_logger(...)` when you need a value of this type.

2. Use `Logger[S]` directly when exposing the full sync composition surface is acceptable.
