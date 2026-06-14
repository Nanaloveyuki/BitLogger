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
- The root logger also preserves the core target contract used across the sync API surface: `log(..., target=...)` can override the target for one call, while fixed-level helpers such as `trace(...)`, `debug(...)`, `info(...)`, `warn(...)`, and `error(...)` continue using the stored logger target unless code derives another logger first with `with_target(...)` or `child(...)`.
- In particular, synchronous `with_context_fields(...)` and `bind(...)` change the visible logger type to `Logger[ContextSink[S]]` because shared fields are implemented by extending the sink pipeline rather than by storing extra root-level context metadata on `Logger[S]` itself.
- `Logger::new(...)` constructs this type as the main synchronous entry point.
- This root type is also what sits underneath both facade families: `ApplicationLogger` is a direct alias over the configured `Logger[RuntimeSink]` line, while `LibraryLogger[S]` is a narrowing wrapper around a `Logger[S]` value.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Root Logger Value

When synchronous logging should begin from a concrete sink-preserving root object:
```moonbit
let logger : Logger[ConsoleSink] = Logger::new(console_sink(), target="app")
```

In this example, the root logger keeps the concrete console sink type visible for later typed composition.

#### When Need A One-call Target Override On The Root Logger

When sync code should keep one logger value but emit a single record under a different target:
```moonbit
logger.log(Level::Error, "boom", target="app.audit")
```

In this example, the emitted record uses `app.audit` only for that one call.

And later `trace(...)`, `debug(...)`, `info(...)`, `warn(...)`, or `error(...)` calls still use the logger's stored target unless code derives another logger first with `with_target(...)` or `child(...)`.

#### When Need Shared Context On A Sync Root Logger

When sync code should attach stable metadata to later records:
```moonbit
let contextual = logger.with_context_fields([field("service", "billing")])
```

In this example, the returned value has the visible type `Logger[ContextSink[S]]`.

And that type change is expected because sync context binding extends the sink pipeline instead of only updating root-level metadata.

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

2. Use `ConfiguredLogger` when config-built runtime helpers should stay directly available on the returned logger value.

3. Use `ApplicationLogger` when application code wants that same configured-runtime surface under an app-facing alias.

4. Use `LibraryLogger[S]` when a library boundary should intentionally narrow the public logger surface and expose broader composition only through `to_logger()`.
