---
name: library-logger-to-logger
group: api
category: facade
update-time: 20260614
description: Recover the underlying full sync logger from the library-facing sync facade without rebuilding, copying, or detaching the wrapped logger state.
key-word:
    - logger
    - library
    - facade
    - public
---

## Library-logger-to-logger

Recover `Logger[S]` from `LibraryLogger[S]`. This unwraps the library-facing sync facade when code needs methods that are only available on the full logger type.

### Interface

```moonbit
pub fn[S] LibraryLogger::to_logger(self : LibraryLogger[S]) -> Logger[S] {}
```

#### input

- `self : LibraryLogger[S]` - Library-facing sync logger facade.

#### output

- `Logger[S]` - The underlying full sync logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This conversion unwraps the existing logger instead of rebuilding it.
- Sink wiring, target, min level, timestamp behavior, and attached wrappers remain the same.
- The returned `Logger[S]` is still that same live wrapped value, so later facade writes or later unwraps continue observing and mutating the same logger instance.
- Use this when code needs full-surface APIs such as `with_timestamp(...)`, `with_filter(...)`, or `with_patch(...)`.
- When the wrapped sink is `RuntimeSink`, unwrapping preserves that runtime sink value, but the result type is still `Logger[RuntimeSink]` rather than the `ConfiguredLogger` alias. Runtime-specific operations remain available through `full.sink` or by keeping a `ConfiguredLogger` value directly.
- That same unwrap also preserves queued runtime state and file-backed helper behavior exactly as they existed behind the facade, including drain or flush results, file state snapshots, and file control methods.
- Runtime and file helper mutations are still live too. Draining queued records, flushing, or changing file helper state through the unwrapped logger changes the same runtime-backed logger that the facade already wrapped.

### How to Use

Here are some specific examples provided.

#### When Need Full Logger-only Composition APIs

When a library-facing logger must be widened temporarily for additional composition:
```moonbit
let library_logger = LibraryLogger::new(console_sink(), target="lib")
let full_logger = library_logger.to_logger().with_timestamp()
```

In this example, the facade is unwrapped so the caller can access full logger composition APIs again.

#### When Need Runtime Helpers After Library-oriented Config Build

When a library-facing runtime logger should later expose configured runtime controls internally:
```moonbit
let full = logger.to_logger()
ignore(full.sink.pending_count())
```

In this example, unwrapping preserves the same `RuntimeSink` pipeline, and callers reach runtime-specific helpers through that preserved sink value.

The same handle keeps reflecting later facade writes instead of becoming a detached snapshot.

### Error Case

e.g.:
- If callers only need library-oriented write APIs, unwrapping is unnecessary.

- Unwrapping does not change the current target or sink behavior by itself.

- Recovering the full logger does not rebuild or reset the existing sink wrappers.

- Recovering the full logger does not translate configured runtime state into a simpler snapshot; queued counts, file availability, file failure counters, and runtime file controls stay exactly as they were on the wrapped logger.

- Recovering the full logger also does not isolate later runtime-helper mutations. If unwrapped code drains queued records or changes file helper state, later facade writes still run against that same updated wrapped logger.

### Notes

1. Use this only when the narrower facade is no longer sufficient.

2. This is the inverse projection of `Logger::to_library_logger()`.

3. Use `LibraryLogger[S]` directly when the narrower package-facing surface is still sufficient.
