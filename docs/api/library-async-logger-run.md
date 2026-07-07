---
name: library-async-logger-run
group: api
category: facade
update-time: 20260707
description: Start the LibraryAsyncLogger worker loop by delegating to the wrapped async logger's run behavior.
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
- The delegated `run()` call now preserves the wrapped logger's single-worker guard, so a second concurrent facade-level startup raises `AsyncLoggerAlreadyRunning`.
- Failure and lifecycle state are still tracked by the wrapped async logger.
- Once a delegated `run()` call has actually started, it clears any previous `has_failed()` flag and stored `last_error()` string on that same wrapped logger before draining resumes.
- The narrower library facade does not hide the need to explicitly activate queue draining.
- If the worker fails, the wrapped async logger records that through its failure-state helpers, which still require `to_async_logger()` for inspection from library-facing code.
- Unwrapping after a delegated `run()` exposes the same failure and backlog state that accumulated behind the facade; it does not create a second runtime view.

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

And the started worker loop is still the same wrapped async logger runtime rather than a separate library-specific execution path.

### Error Case

e.g.:
- If the worker loop fails, the wrapped async logger records failure state.

- If `run()` is never started, accepted records may remain queued and not reach the sink.

- A later delegated `run()` attempt starts from a fresh failure flag and empty `last_error()` string on the same wrapped logger, even if an earlier facade-level run failed.
- A concurrent delegated `run()` attempt while the wrapped logger is already active fails explicitly with `AsyncLoggerAlreadyRunning`.

- If callers need to inspect `is_running()`, `has_failed()`, or `last_error()` directly, they must unwrap first with `to_async_logger()`.

### Notes

1. `LibraryAsyncLogger::new(...)` only constructs the facade; `run()` is what activates queue draining.

2. Pair this API with `shutdown()` for a complete worker lifecycle.

3. Use `to_async_logger()` first when operational code needs direct lifecycle or failure inspection in addition to starting the worker.
