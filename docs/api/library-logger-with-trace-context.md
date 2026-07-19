---
name: library-logger-with-trace-context
group: api
category: facade
update-time: 20260719
description: Bind TraceContext fields through the restricted LibraryLogger facade.
key-word:
    - library
    - trace
    - context
---

## Library-logger-with-trace-context

```moonbit
let logger = LibraryLogger::new(console_sink())
  .with_trace_context(trace_context("trace-1", "span-1"))
```

The derived facade preserves its library-facing API while wrapping the sink with context fields. Use `to_logger()` only when broader composition is required.
