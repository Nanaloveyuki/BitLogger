---
name: async-logger-with-trace-context
group: api
category: async
update-time: 20260719
description: Bind TraceContext fields before records enter an AsyncLogger queue.
key-word:
    - async
    - trace
    - context
---

## Async-logger-with-trace-context

```moonbit
let contextual = logger.with_trace_context(
  @bitlogger.trace_context("trace-1", "span-1"),
)
```

The helper stores the mapped fields on the returned async logger and preserves its queue, lifecycle, target, and threshold state. Context is added before records are enqueued.
