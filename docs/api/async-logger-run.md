---
name: async-logger-run
group: api
category: async
update-time: 20260512
description: Start the async logger worker loop so queued records are drained to the underlying sink.
key-word:
    - async
    - logger
    - worker
    - public
---

## Async-logger-run

Start the async logger worker loop. This is the core runtime API that drains queued records to the underlying sink and updates worker lifecycle state.

### Interface

```moonbit
pub async fn[S : @bitlogger.Sink] AsyncLogger::run(self : AsyncLogger[S]) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose queue should be drained by the worker loop.

#### output

- `Unit` - No return value. The method runs until the queue is closed or a worker failure occurs.

### Explanation

Detailed rules explaining key parameters and behaviors

- `run()` sets `is_running` to `true` while the worker loop is active.
- It clears previous failure state before worker execution begins.
- On failure, the logger records `has_failed=true` and stores the error text in `last_error`.
- The worker exits when the queue is closed or when a failure aborts processing.

### How to Use

Here are some specific examples provided.

#### When Need Background Queue Drain

When async logging should be processed by a worker task:
```moonbit
let logger = async_logger(console_sink())
@async.with_task_group(group => {
  group.spawn_bg(() => logger.run())
  logger.info("started")
  logger.shutdown()
})
```

In this example, `run()` is the worker loop that makes the async logger actually deliver queued records.

#### When Need Explicit Worker Lifetime Control

When worker execution should be started under application control:
```moonbit
group.spawn_bg(() => logger.run())
```

In this example, the application decides when the worker begins instead of hiding that lifecycle step.

### Error Case

e.g.:
- If the worker loop fails, `has_failed()` becomes `true` and `last_error()` stores the error text.

- If `run()` is never started, accepted records may remain queued and not reach the sink.

### Notes

1. `async_logger(...)` only constructs the logger; `run()` is what activates queue draining.

2. Pair this API with `shutdown()` for a complete worker lifecycle.
