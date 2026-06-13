---
name: library-async-logger-new
group: api
category: facade
update-time: 20260613
description: Create a narrower library-facing async logger facade from any sink implementation.
key-word:
    - async
    - library
    - facade
    - public
---

## Library-async-logger-new

Create a `LibraryAsyncLogger[S]` from any sink implementation. This is the library-facing async constructor when you want queue-backed async logging behavior without exposing the full `AsyncLogger[S]` surface.

### Interface

```moonbit
pub fn[S] LibraryAsyncLogger::new(
  sink : S,
  config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
  min_level~ : @bitlogger.Level = @bitlogger.Level::Info,
  target~ : String = "",
  flush~ : (S) -> Int raise = fn(_) { 0 },
) -> LibraryAsyncLogger[S] {
```

#### input

- `sink : S` - Any sink value implementing `@bitlogger.Sink`, such as `@bitlogger.console_sink()` or a composed sink.
- `config : AsyncLoggerConfig` - Queue size, overflow behavior, batching, linger, and flush policy.
- `min_level : Level` - Minimum enabled level. Messages below this threshold are ignored before enqueue.
- `target : String` - Default target attached to emitted records unless later overridden.
- `flush : (S) -> Int raise` - Flush callback used when async batch or shutdown policy needs explicit flushing.

#### output

- `LibraryAsyncLogger[S]` - Narrow library-facing wrapper over a newly created async logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API builds a regular `async_logger(...)` internally and then wraps it as `LibraryAsyncLogger`.
- The returned facade intentionally exposes a smaller method set than the full `AsyncLogger[S]` type.
- Queue settings, flush policy, and runtime state are preserved inside the wrapped async logger.
- Call `to_async_logger()` if later code must recover the full async logger surface.

### How to Use

Here are some specific examples provided.

#### When Need A Narrower Library-facing Async Constructor

When a package should create an async logger without exposing the full async logger API:
```moonbit
let logger = LibraryAsyncLogger::new(
  @bitlogger.console_sink(),
  config=AsyncLoggerConfig::new(max_pending=32),
  target="plugin.async",
)
```

In this example, the package creates a normal async logging pipeline but publishes only the smaller facade type.

#### When Need Explicit Flush Behavior In A Library Boundary

When the sink requires a flush callback for batch or shutdown policy:
```moonbit
let logger = LibraryAsyncLogger::new(
  @bitlogger.console_sink(),
  flush=fn(sink) { 0 },
)
```

In this example, the facade still keeps the queue-backed async behavior while hiding the full async logger type.

### Error Case

e.g.:
- If `target` is empty, the returned logger remains valid and later records simply use an empty default target.

- If later code needs methods outside the facade, it must unwrap with `to_async_logger()`.

### Notes

1. This is the direct constructor counterpart to `async_logger(...)` for library-oriented async APIs.

2. Prefer this when public package boundaries should stay narrower than `AsyncLogger[S]`.
