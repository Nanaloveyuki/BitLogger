---
name: trace-context
group: api
category: observability
update-time: 20260928
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

Valid W3C values are normalized through `moonbit-community/opentelemetry`: 32-digit trace ids, 16-digit span ids, and 2-digit trace flags are rewritten with `TraceId`, `SpanId`, and `TraceFlags`. `trace_state` is parsed with `TraceState::from_header`. Values that are not valid hex stay unchanged, so application-local identifiers still bind as fields.

Use `context.as_fields()` when integrating with a custom carrier, or pass the value to a logger's `with_trace_context(...)` helper. BitLogger does not parse HTTP headers or export OTLP data; an application-owned tracing library remains responsible for propagation and sampling.
