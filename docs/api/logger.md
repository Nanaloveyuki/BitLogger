---
name: logger
group: api
category: logging
update-time: 20260613
description: Public synchronous logger root type used for typed logging pipelines and sink-preserving composition.
key-word:
    - logger
    - sync
    - type
    - public
---

## Logger

`Logger[S]` is the public synchronous root logger type. It stores a concrete sink type `S` together with minimum level, default target, and timestamp settings, then serves as the base value for typed composition helpers and write APIs.

### Interface

```moonbit
pub struct Logger[S] {
  min_level : Level
  sink : S
  target : String
  timestamp : Bool
}
```

#### output

- `Logger[S]` - Public synchronous logger value parameterized by the concrete sink type `S`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `min_level : Level`, `sink : S`, `target : String`, and `timestamp : Bool`.
- The sink type parameter is preserved across composition, which is why helpers such as `with_context_fields(...)`, `with_filter(...)`, `with_patch(...)`, and `with_queue(...)` can return more specific logger shapes.
- `Logger::new(...)` constructs this type as the main synchronous entry point.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Root Logger Value

When synchronous logging should begin from a concrete sink-preserving root object:
```moonbit
let logger : Logger[ConsoleSink] = Logger::new(console_sink(), target="app")
```

In this example, the root logger keeps the concrete console sink type visible for later typed composition.

#### When Need To Build A Composed Logging Pipeline

When code should start from one root logger and then derive more specific wrapped forms:
```moonbit
let logger = Logger::new(console_sink(), min_level=Level::Info)
  .with_timestamp()
  .with_context_fields([field("service", "billing")])
```

In this example, the root type becomes the stable base for later logging behavior changes.

### Error Case

e.g.:
- `Logger[S]` itself does not have a runtime failure mode.

- Actual write behavior still depends on the wrapped sink `S`, so sink-specific limitations remain unchanged behind the logger type.

### Notes

1. Use `Logger::new(...)` when you need a value of this type in code.

2. Use `ConfiguredLogger`, `ApplicationLogger`, or `LibraryLogger[S]` when a more intention-specific wrapper or alias fits the calling boundary better.
