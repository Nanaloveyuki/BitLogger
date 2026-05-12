---
name: async-logger-last-error
group: api
category: async
update-time: 20260512
description: Read the last error recorded by the async logger worker during runtime failure handling.
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

- `run()` resets the stored error string when the worker starts.
- If the worker loop fails, the error text is captured from the raised exception.
- An empty string normally means no failure has been recorded.
- This helper reports worker execution errors, not ordinary overflow or backpressure conditions.

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

- If callers need broader context than just the error text, they should use `state()`.

### Notes

1. Read this helper together with `has_failed()` when interpreting worker health.

2. The stored value is a diagnostic string, not a typed error object.
