# Trace Context

BitLogger keeps trace interoperability in its structured record model rather than owning HTTP propagation or a telemetry transport. Use the tracing library already selected by the application to extract a request context, then bind its identifiers to the logger.

```moonbit
let request_logger = logger.with_trace_context(
  @log.trace_context(
    trace_id,
    span_id,
    trace_flags="01",
    trace_state=trace_state,
  ),
)
```

Every record from `request_logger` receives `trace_id`, `span_id`, `trace_flags`, and, when supplied, `trace_state`. The base logger is unchanged, so a child request cannot leak identifiers into unrelated work.

Use `context.as_fields()` for a custom logger facade. BitLogger intentionally does not parse `traceparent` headers, create spans, make sampling decisions, or export OTLP data; those concerns remain with the application tracing implementation.
