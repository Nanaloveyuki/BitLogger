---
name: async-logger-with-context-fields
group: api
category: async
update-time: 20260512
description: Attach reusable structured fields to an async logger so every queued record inherits them.
key-word:
    - async
    - logger
    - fields
    - public
---

## Async-logger-with-context-fields

Bind shared structured fields to an async logger. This is the standard way to attach stable metadata such as service name, component, region, or subsystem identity without repeating them for every async log call.

### Interface

```moonbit
pub fn[S] AsyncLogger::with_context_fields(
  self : AsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> AsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Base async logger that should gain shared fields.
- `fields : Array[Field]` - Structured fields that will be prepended to each emitted record.

#### output

- `AsyncLogger[S]` - A new async logger value carrying the shared field set.

### Explanation

Detailed rules explaining key parameters and behaviors

- Context fields are merged during `log(...)` before enqueue.
- When a log call also passes per-record fields, the context fields are placed before those per-call fields.
- This API returns a new logger value; it does not mutate the original async logger.
- The provided `fields` array replaces the previously stored shared field set on the returned async logger; it does not append onto whatever `context_fields` the source logger already had.
- Unlike synchronous `Logger::with_context_fields(...)`, this async variant stores fields directly on `AsyncLogger` instead of changing the visible sink type.
- Only the stored `context_fields` value changes. Target, minimum level, timestamp flag, queue configuration, and lifecycle/failure state stay on the same `AsyncLogger[S]` surface.
- In the current direct async coverage, the original logger keeps its previous `context_fields`, while the derived logger prepends the stored shared fields ahead of per-call fields exactly once when records are built.

### How to Use

Here are some specific examples provided.

#### When Need Stable Async Service Metadata

When every queued record should carry service-level metadata:
```moonbit
let logger = async_logger(console_sink(), target="billing")
  .with_context_fields([
    @bitlogger.field("service", "billing"),
    @bitlogger.field("region", "cn"),
  ])
```

In this example, both fields are attached before each record enters the queue.

And the returned async logger still keeps the same queue-facing API surface as the source logger.

#### When Build Child Async Loggers For Subsystems

When a subsystem has both a target and fixed fields:
```moonbit
let worker = async_logger(console_sink(), target="app")
  .child("worker")
  .with_context_fields([@bitlogger.field("component", "worker")])
```

In this example, target composition and field binding stay separate but work together cleanly.

### Error Case

e.g.:
- If `fields` is empty, the logger remains valid and just adds no extra metadata.

- If a derived async logger already had shared context fields, calling `with_context_fields(...)` again replaces that stored shared field set on the new derived logger rather than stacking both sets together.

- If duplicate field keys are provided, all fields are still emitted; conflict handling is left to the consumer side.

### Notes

1. Use this for stable metadata, not highly dynamic event-specific values.

2. This async variant preserves the visible `AsyncLogger[S]` type while still injecting shared fields.

3. State helpers such as `pending_count()`, `dropped_count()`, `is_closed()`, and `has_failed()` remain available on the returned logger because the visible async logger surface is preserved.

4. Use a fresh derived logger when one code path needs shared metadata and another should stay unchanged.

5. If you need to combine two shared field sets, combine them in the `fields` argument yourself instead of expecting repeated `with_context_fields(...)` calls to accumulate them.
