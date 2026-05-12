---
name: async-logger
group: api
category: async
update-time: 20260512
description: Create an async logger with bounded queueing, overflow policy, lifecycle helpers, and background run control.
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
  flush~ : (S) -> Int = fn(_) { 0 },
) -> AsyncLogger[S] {}
```

#### input

- `sink : S` - Underlying sink used after queue drain.
- `config : AsyncLoggerConfig` - Queue size, overflow behavior, batching, linger, and flush policy.
- `min_level : Level` - Level gate applied before enqueue.
- `target : String` - Default target for emitted records.
- `flush : (S) -> Int` - Flush callback used by batch/shutdown flush policies.

#### output

- `AsyncLogger[S]` - A queue-backed async logger with lifecycle and state helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- `async_logger(...)` only builds the logger. Actual background draining is started by `run()`.
- In non-native targets, the implementation uses compatibility behavior while keeping the same public surface.
- `flush` is used only when batch or shutdown policy wants explicit flushing.
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

Notes are here.

1. `async_logger(...)` is the async counterpart to `Logger::new(...)`.

2. Use `state()`, `pending_count()`, and `dropped_count()` for runtime diagnostics.

3. Prefer `shutdown()` over raw `close()` in normal graceful shutdown paths.

4. On cross-target code paths, pair this API with `async_runtime_mode()` or `async_runtime_state()` when behavior differences matter.
