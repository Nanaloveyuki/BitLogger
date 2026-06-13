---
name: async-logger-last-error
group: api
category: async
update-time: 20260614
description: Read the last error string recorded by the async logger worker after run() resets and runtime failure capture.
key-word:
    - async
    - logger
    - failure
    - public
---

## Async-logger-last-error

Read the last error string recorded by the async logger worker. This helper gives the textual detail behind `has_failed()`.

### Interface

```moonbit
pub fn[S] AsyncLogger::last_error(self : AsyncLogger[S]) -> String {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose last worker error should be inspected.

#### output

- `String` - Last recorded worker error message, or an empty string if no error was recorded.

### Explanation

Detailed rules explaining key parameters and behaviors

- A later `run()` clears the stored error string only after that run has actually started.
- If the worker loop fails, the error text is captured from the raised exception.
- An empty string normally means no failure has been recorded.
- Once a failure string is recorded, it stays in place until a later `run()` invocation actually starts and clears it.
- This helper reports worker execution errors, not ordinary overflow or backpressure conditions.
- That reset happens before the restarted worker resumes drain work.

### How to Use

Here are some specific examples provided.

#### When Need Failure Detail In Diagnostics

When a compact error message should be surfaced to operators:
```moonbit
if logger.has_failed() {
  println(logger.last_error())
}
```

In this example, the error string is only read when failure is present.

#### When Export Full Async State

When custom diagnostics want to include the last error field directly:
```moonbit
let err = logger.last_error()
```

In this example, the helper provides the textual failure detail without building a full snapshot.

### Error Case

e.g.:
- If no runtime failure has occurred, the method returns an empty string.

- An empty string does not prove the queue is empty or the worker is idle; it only means no failure string is currently recorded.

- If callers need broader context than just the error text, they should use `state()`.

- `close()` or `shutdown()` do not clear a previously recorded error string by themselves; the reset happens only after a later `run()` has already started.

### Notes

1. Read this helper together with `has_failed()` when interpreting worker health.

2. The stored value is a diagnostic string, not a typed error object.

3. Pair it with `is_running()` or `pending_count()` when you need to know whether failure left the logger with unfinished backlog, because the previous error string can coexist with remaining pending records until later cleanup or restart.
