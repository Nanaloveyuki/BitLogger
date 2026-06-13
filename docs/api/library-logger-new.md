---
name: library-logger-new
group: api
category: facade
update-time: 20260613
description: Create a narrower sync library logger facade from any sink implementation.
key-word:
    - library
    - facade
    - logger
    - public
---

## Library-logger-new

Create a `LibraryLogger[S]` from any sink implementation. This is the library-facing sync constructor when you want standard logging behavior but do not want to expose the full `Logger[S]` surface.

### Interface

```moonbit
pub fn[S] LibraryLogger::new(
  sink : S,
  min_level~ : Level = Level::Info,
  target~ : String = "",
) -> LibraryLogger[S] {
```

#### input

- `sink : S` - Any sink value implementing `Sink`, such as `console_sink()` or a composed sink.
- `min_level : Level` - Minimum enabled level. Messages below this threshold are ignored.
- `target : String` - Default target attached to emitted records unless later overridden.

#### output

- `LibraryLogger[S]` - Narrow library-facing wrapper over a newly created sync logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API builds a regular `Logger::new(...)` internally and then wraps it as `LibraryLogger`.
- The returned facade intentionally exposes a smaller method set than the full `Logger[S]` type.
- The original sink type is still preserved in `LibraryLogger[S]`.
- Call `to_logger()` if later code must recover the full sync logger surface.

### How to Use

Here are some specific examples provided.

#### When Need A Narrower Library-facing Constructor

When a package should create a logger without exposing the full logger API:
```moonbit
let logger = LibraryLogger::new(console_sink(), min_level=Level::Info, target="plugin")
logger.info("loaded")
```

In this example, the package creates a normal sync logger pipeline but publishes only the smaller facade type.

#### When Accept A Generic Sink But Keep Library Boundaries Small

When a library API wants typed sinks without exposing extra composition helpers:
```moonbit
let logger = LibraryLogger::new(text_console_sink(text_formatter()), target="worker")
```

In this example, sink typing remains explicit while the consumer only sees the library facade.

### Error Case

e.g.:
- If `target` is empty, the returned logger remains valid and later records simply use an empty default target.

- If later code needs methods outside the facade, it must unwrap with `to_logger()`.

### Notes

1. This is the direct constructor counterpart to `Logger::new(...)` for library-oriented APIs.

2. Prefer this when public package boundaries should stay narrower than `Logger[S]`.
