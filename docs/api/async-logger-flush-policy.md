---
name: async-logger-flush-policy
group: api
category: async
update-time: 20260707
description: Read the async logger flush policy currently governing batch-end and shutdown-end flush-callback timing.
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
- `Batch` means the worker invokes the stored async flush callback after each completed drained batch, not after every individual record write.
- `Shutdown` means the worker invokes the stored async flush callback once after the worker loop exits.
- `Never` leaves that explicit callback path unused and relies entirely on sink behavior or external control.
- This helper reports callback timing policy, not a progress count contract.
- The callback is now treated as an attempted flush action with optional failure, not as a meaningful returned item count.
- Builder routes that wrap `RuntimeSink` align with the sync/runtime facade by calling `RuntimeSink::flush_progress()` inside that callback and discarding the returned progress details.
- Text-specific async builder paths still keep the default no-op flush callback even when the visible policy is `Batch` or `Shutdown`, so the reported policy can describe when the callback would run without implying extra sink work actually happens on that path.

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
