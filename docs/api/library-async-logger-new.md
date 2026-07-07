---
name: library-async-logger-new
group: api
category: facade
update-time: 20260707
description: Create a narrower library-facing async logger facade by building a regular async logger and wrapping the same underlying state.
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
  flush~ : (S) -> Unit raise = fn(_) { () },
) -> LibraryAsyncLogger[S] {
```

#### input

- `sink : S` - Underlying sink value that should receive drained records, such as `@bitlogger.console_sink()` or a composed sink.
- `config : AsyncLoggerConfig` - Queue size, overflow behavior, batching, linger, and flush policy.
- `min_level : Level` - Minimum enabled level. Messages below this threshold are ignored before enqueue.
- `target : String` - Default target attached to emitted records unless later overridden.
- `flush : (S) -> Unit raise` - Flush callback used when async batch or shutdown policy needs explicit flushing, and allowed to raise if flushing fails.

#### output

- `LibraryAsyncLogger[S]` - Narrow library-facing wrapper over a newly created async logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API builds a regular `async_logger(...)` internally and then wraps that same value as `LibraryAsyncLogger`.
- The returned facade intentionally exposes a smaller method set than the full `AsyncLogger[S]` type.
- Queue settings, flush policy, target, minimum level, and runtime state are preserved inside the wrapped async logger.
- This constructor does not start background draining by itself; `run()` is still the step that activates queue processing.
- If the supplied flush callback later raises during async drain or shutdown, failure state is still recorded on the wrapped async logger.
- Call `to_async_logger()` if later code must recover the broader async logger surface for state inspection or additional composition helpers.

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
  flush=fn(sink) { () },
)
```

In this example, the facade still keeps the queue-backed async behavior while hiding the full async logger type.

#### When Need Full Async State Helpers Later

When library-facing construction should still allow later access to the broader async helper set:
```moonbit
let logger = LibraryAsyncLogger::new(@bitlogger.console_sink(), target="lib.async")
let full = logger.to_async_logger()
ignore(full.pending_count())
```

In this example, construction starts from the narrower facade, but the same underlying async logger can still be recovered later.

### Error Case

e.g.:
- If `target` is empty, the returned logger remains valid and later records simply use an empty default target.

- If later code needs methods outside the facade, it must unwrap with `to_async_logger()`.

- Constructing the facade alone does not drain queued records; callers still need `run()` for active background processing.

### Notes

1. This is the direct constructor counterpart to `async_logger(...)` for library-oriented async APIs.

2. Prefer this when public package boundaries should stay narrower than `AsyncLogger[S]`.

3. Use `async_logger(...)` directly when the full async lifecycle, state, and composition surface should stay public from the start.
