---
name: async-logger-run
group: api
category: async
update-time: 20260614
description: Start the async logger worker loop so queued records are drained to the underlying sink while lifecycle and failure state are reset and updated around execution.
key-word:
    - async
    - logger
    - worker
    - public
---

## Async-logger-run

Start the async logger worker loop. This is the core runtime API that drains queued records to the underlying sink and updates worker lifecycle state around that drain loop.

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

- `run()` sets `is_running` to `true` before worker execution begins.
- Every invocation clears previous failure state first by setting `has_failed=false` and `last_error()` to an empty string.
- The method then keeps draining records until `queue.get()` stops with `AsyncLoggerClosed` or a worker error escapes.
- On a normal queue-close exit, `run()` clears `is_running` and returns normally.
- On failure, the logger records `has_failed=true`, stores the error text in `last_error`, clears `is_running`, and then raises the error back out of `run()`.
- This helper does not enforce a single-worker guard by itself, so the public contract should be treated as application-controlled worker startup rather than an API that deduplicates repeated `run()` calls.

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
- If the worker loop fails, `has_failed()` becomes `true`, `last_error()` stores the error text, and `run()` raises that failure to the caller.

- If `run()` is never started, accepted records may remain queued and not reach the sink.

- A later `run()` attempt starts from a fresh failure flag and empty `last_error()` string, even if an earlier run failed.

- Starting more than one `run()` task for the same logger is not prevented by this method and can produce application-level worker coordination bugs.

### Notes

1. `async_logger(...)` only constructs the logger; `run()` is what activates queue draining.

2. Pair this API with `shutdown()` for a complete worker lifecycle.

3. Pair it with `has_failed()`, `last_error()`, or `state()` when tests need to inspect how a worker exit affected logger health.

4. Start one deliberate worker task per logger unless your own code is intentionally coordinating a different pattern.
