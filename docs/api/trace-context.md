---
name: trace-context
group: api
category: observability
update-time: 20260719
description: Represent and bind distributed trace metadata using stable structured-log fields.
key-word:
    - trace
    - context
    - observability
---

## Trace-context

`TraceContext` carries the standard log fields used to correlate records with distributed traces: `trace_id`, `span_id`, `trace_flags`, and optional `trace_state`.

```moonbit
let context = trace_context(
  "4bf92f3577b34da6a3ce929d0e0e4736",
  "00f067aa0ba902b7",
  trace_state="vendor=value",
)
```

Use `context.as_fields()` when integrating with a custom carrier, or pass the value to a logger's `with_trace_context(...)` helper. BitLogger does not parse HTTP headers or export OTLP data; an application-owned tracing library remains responsible for propagation and sampling.
