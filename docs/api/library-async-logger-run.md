---
name: library-async-logger-run
group: api
category: facade
update-time: 20260613
description: Start the LibraryAsyncLogger worker loop so queued records are drained to the underlying sink.
key-word:
    - async
    - library
    - worker
    - public
---

## Library-async-logger-run

Start the library-facing async logger worker loop. This is the core runtime API that drains queued records to the underlying sink while preserving the narrower facade boundary.

### Interface

```moonbit
pub async fn[S : @bitlogger.Sink] LibraryAsyncLogger::run(self : LibraryAsyncLogger[S]) -> Unit {
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger whose queue should be drained by the worker loop.

#### output

- `Unit` - No return value. The method runs until the queue is closed or a worker failure occurs.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates directly to the wrapped async logger's `run()` behavior.
- It starts the worker loop that makes accepted queued records reach the underlying sink.
- Failure and lifecycle state are still tracked by the wrapped async logger.
- The narrower library facade does not hide the need to explicitly activate queue draining.

### How to Use

Here are some specific examples provided.

#### When Need Background Queue Drain Through The Facade

When library async logging should be processed by a worker task:
```moonbit
let logger = LibraryAsyncLogger::new(@bitlogger.console_sink())
@async.with_task_group(group => {
  group.spawn_bg(() => logger.run())
  logger.info("started")
  logger.shutdown()
})
```

In this example, `run()` is the worker loop that makes the async facade actually deliver queued records.

#### When Need Explicit Worker Lifetime Control

When worker execution should be started under caller control:
```moonbit
group.spawn_bg(() => logger.run())
```

In this example, the caller decides when the worker begins instead of hiding that lifecycle step.

### Error Case

e.g.:
- If the worker loop fails, the wrapped async logger records failure state.

- If `run()` is never started, accepted records may remain queued and not reach the sink.

### Notes

1. `LibraryAsyncLogger::new(...)` only constructs the facade; `run()` is what activates queue draining.

2. Pair this API with `shutdown()` for a complete worker lifecycle.
