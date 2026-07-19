---
name: logger-with-trace-context
group: api
category: logger
update-time: 20260719
description: Bind a TraceContext to every record from a synchronous Logger.
key-word:
    - logger
    - trace
    - context
---

## Logger-with-trace-context

```moonbit
pub fn[S] Logger::with_trace_context(
  self : Logger[S],
  context : TraceContext,
) -> Logger[ContextSink[S]]
```

Returns a derived logger that prepends the context fields to every record. The original logger is unchanged. This is equivalent to `with_context_fields(context.as_fields())`, while making trace intent explicit.
