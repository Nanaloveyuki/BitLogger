---
name: async-logger
group: api
category: async
update-time: 20260614
description: Create an async logger with bounded queueing, overflow policy, lifecycle helpers, background run control, and a raising flush callback.
key-word:
    - async
    - logger
    - queue
    - public
---

## Async-logger

Create an `AsyncLogger[S]` on top of a sink and async queue configuration. This API is the main entry for queue-backed async logging, including overflow policy, batching, lifecycle control, and runtime observability.

### Interface

```moonbit
pub fn[S] async_logger(
  sink : S,
  config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
  min_level~ : @bitlogger.Level = @bitlogger.Level::Info,
  target~ : String = "",
  flush~ : (S) -> Int raise = fn(_) { 0 },
) -> AsyncLogger[S] {}
```

#### input

- `sink : S` - Underlying sink used after queue drain.
- `config : AsyncLoggerConfig` - Queue size, overflow behavior, batching, linger, and flush policy.
- `min_level : Level` - Level gate applied before enqueue.
- `target : String` - Default target for emitted records.
- `flush : (S) -> Int raise` - Flush callback used by batch/shutdown flush policies and allowed to raise if sink flushing fails.

#### output

- `AsyncLogger[S]` - A queue-backed async logger with lifecycle and state helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- `async_logger(...)` only builds the logger. Actual background draining is started by `run()`.
- The constructed logger starts with `is_closed=false`, `is_running=false`, `has_failed=false`, `last_error=""`, and zeroed pending/dropped counters.
- In non-native targets, the implementation uses compatibility behavior while keeping the same public surface.
- `src-async` is designed for `native / llvm / js / wasm / wasm-gc`, but current release-facing local verification is stronger for `native / js / wasm / wasm-gc` than for `llvm`.
- `llvm` should currently be read as experimental and locally unverified in this environment rather than as a stable checked target.
- `flush` is used only when batch or shutdown policy wants explicit flushing.
- If the supplied flush callback raises, worker failure state is recorded through `has_failed()` and `last_error()`.
- The exact behavior of late log attempts after closure is runtime-dependent, so callers should use lifecycle helpers like `is_closed()` and `shutdown()` instead of assuming identical post-close enqueue semantics everywhere.
- Queue overflow behavior depends on `AsyncOverflowPolicy`.

### How to Use

Here are some specific examples provided.

#### When Need Background Queue Drain

When your sink should not be written directly on the caller path:
```moonbit
let logger = async_logger(callback_sink(fn(rec) { println(rec.message) }))
@async.with_task_group(group => {
  group.spawn_bg(() => logger.run())
  logger.info("hello")
  logger.shutdown()
})
```

In this example, the worker drains queued records in the background and `shutdown()` waits for completion.

And the logging call path stays queue-oriented rather than direct-sink oriented.

#### When Need Configurable Overflow And Flush Behavior

When queue semantics matter for service durability and load:
```moonbit
let logger = async_logger(
  console_sink(),
  config=AsyncLoggerConfig::new(
    max_pending=128,
    overflow=AsyncOverflowPolicy::DropOldest,
    max_batch=8,
    flush=AsyncFlushPolicy::Batch,
  ),
)
```

In this example, queue pressure and flush timing are both explicit.

### Error Case

e.g.:
- If the logger is closed, further enqueue attempts stop being normal active logging operations.

- If queue drain fails internally, runtime state can reflect that through `has_failed()` and `last_error()`.

### Notes

1. `async_logger(...)` is the async counterpart to `Logger::new(...)`.

2. Use `state()`, `pending_count()`, and `dropped_count()` for runtime diagnostics.

3. Example entrypoint limitations such as `async fn main` support are separate from the library-level portability of this API.

4. See [target-verification.md](./target-verification.md) for the current local verification matrix.

5. Pair this constructor with `run()` and `shutdown()` when you need the full worker lifecycle rather than just a configured async logger value.
