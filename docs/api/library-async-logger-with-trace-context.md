---
name: library-async-logger-with-trace-context
group: api
category: facade
update-time: 20260719
description: Bind TraceContext fields through the restricted LibraryAsyncLogger facade.
key-word:
    - library
    - async
    - trace
---

## Library-async-logger-with-trace-context

`LibraryAsyncLogger::with_trace_context(...)` returns a derived library facade with `trace_id`, `span_id`, `trace_flags`, and optional `trace_state` attached to each later record. It does not start a worker or change lifecycle state.
