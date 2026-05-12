---
name: async-logger-flush-policy
group: api
category: async
update-time: 20260512
description: Read the async logger flush policy currently governing batch and shutdown flushing behavior.
key-word:
    - async
    - logger
    - flush
    - public
---

## Async-logger-flush-policy

Read the async logger flush policy. This helper exposes which flush mode currently controls batch and shutdown behavior.

### Interface

```moonbit
pub fn[S] AsyncLogger::flush_policy(self : AsyncLogger[S]) -> AsyncFlushPolicy {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose flush policy should be inspected.

#### output

- `AsyncFlushPolicy` - Current flush policy used by the async worker logic.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned value reflects the policy captured when the async logger was created.
- `Batch` causes explicit flush calls after worker batch processing.
- `Shutdown` causes explicit flush calls at worker shutdown.
- `Never` leaves flushing entirely to sink behavior or external control.

### How to Use

Here are some specific examples provided.

#### When Need To Inspect Runtime Flush Semantics

When diagnostics should show how the worker flushes:
```moonbit
ignore(logger.flush_policy())
```

In this example, the configured flush mode is exposed directly from the logger.

#### When Export Async Runtime Metadata

When code should include flush behavior in custom state reporting:
```moonbit
let flush = logger.flush_policy()
```

In this example, flush behavior can be surfaced without reading the full snapshot.

### Error Case

e.g.:
- This helper does not expose a normal runtime error path; it returns the configured policy.

- If callers need the policy together with backlog and failure state, `state()` is usually the better API.

### Notes

1. This helper exposes configuration-driven runtime behavior, not dynamic worker health.

2. Use `state()` when you want flush policy packaged with the rest of async logger diagnostics.
