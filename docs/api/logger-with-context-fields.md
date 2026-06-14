---
name: logger-with-context-fields
group: api
category: logging
update-time: 20260512
description: Attach reusable structured fields to a logger so every emitted record inherits them.
key-word:
    - logger
    - fields
    - context
    - public
---

## Logger-with-context-fields

Bind shared structured fields to a logger. This is the standard way to attach stable metadata such as service name, component, region, request scope, or subsystem identity without repeating them for every log call.

### Interface

```moonbit
pub fn[S] Logger::with_context_fields(self : Logger[S], fields : Array[Field]) -> Logger[ContextSink[S]] {}
```

#### input

- `self : Logger[S]` - The base logger that should gain shared fields.
- `fields : Array[Field]` - Structured fields that will be prepended to each emitted record.

#### output

- `Logger[ContextSink[S]]` - A new logger wrapping the original sink with context-field merging behavior.

### Explanation

Detailed rules explaining key parameters and behaviors

- Context fields are merged at write time, not by mutating previously created records.
- When a log call also passes per-record fields, the context fields are placed before those per-call fields.
- This API returns a new typed logger wrapper; it does not mutate the original logger variable.
- The returned logger keeps the same stored target, min level, and timestamp behavior while extending the sink pipeline with context-field merging.
- `bind(...)` is an ergonomic alias for this same behavior.

### How to Use

Here are some specific examples provided.

#### When Need Stable Service Metadata

When every record from a logger should carry service-level metadata:
```moonbit
let logger = Logger::new(console_sink(), target="billing")
  .with_context_fields([field("service", "billing"), field("region", "cn")])

logger.info("started")
```

In this example, both `service` and `region` are automatically included on every record.

And callers only need to provide fields that actually vary per event.

The original base logger value is still unchanged if later code keeps using it directly.

#### When Build Child Loggers For Subsystems

When a subsystem has both a target and fixed fields:
```moonbit
let worker = Logger::new(console_sink(), target="app")
  .child("worker")
  .with_context_fields([field("component", "worker")])
```

In this example, target composition and field binding stay separate but work together cleanly.

### Error Case

e.g.:
- If `fields` is empty, the logger remains valid and just adds no extra metadata.

- If duplicate field keys are provided, all fields are still emitted; conflict handling is left to the consumer/formatter side.

### Notes

1. Use this for stable metadata, not highly dynamic event-specific values.

2. Prefer `fields([("k", "v")])` when you want a more ergonomic call site.

3. Use `bind(...)` when you want the same behavior with a shorter, library-style call name.

