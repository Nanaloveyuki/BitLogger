---
name: logger-bind
group: api
category: logging
update-time: 20260512
description: Attach reusable structured fields to a logger through the bind alias.
key-word:
    - logger
    - bind
    - fields
    - public
---

## Logger-bind

Attach shared structured fields to a logger through the `bind(...)` alias. This API is behaviorally identical to `with_context_fields(...)` and exists as a shorter name for common structured context binding.

### Interface

```moonbit
pub fn[S] Logger::bind(self : Logger[S], fields : Array[Field]) -> Logger[ContextSink[S]] {}
```

#### input

- `self : Logger[S]` - Base logger that should gain shared fields.
- `fields : Array[Field]` - Structured fields attached to every emitted record.

#### output

- `Logger[ContextSink[S]]` - New logger value whose visible sink type becomes `ContextSink[S]` and prepends shared fields at write time.

### Explanation

Detailed rules explaining key parameters and behaviors

- `bind(...)` delegates directly to `with_context_fields(...)`; it is an alias, not a different implementation.
- The original logger value is not mutated; a derived wrapped logger is returned.
- The returned logger changes visible type from `Logger[S]` to `Logger[ContextSink[S]]` because the sink pipeline is extended with stored shared fields.
- Stored target, minimum level, and timestamp behavior are preserved while the sink pipeline changes.
- Shared fields are applied to every later log call emitted through the returned logger.
- When a log call also passes per-record fields, the shared bound fields are prepended before those per-call fields because `bind(...)` inherits the same merge order as `with_context_fields(...)`.
- This alias is useful when you prefer shorter chaining syntax in application code.

### How to Use

Here are some specific examples provided.

#### When Bind Shared Request Context

When a logger should carry stable fields through a flow:
```moonbit
let request_logger = Logger::new(console_sink(), target="api")
  .bind([field("request_id", "req-42")])
```

In this example, subsequent writes automatically include `request_id`.

#### When Prefer Shorter Chaining Syntax

When a context-bound child logger should stay readable:
```moonbit
let worker = Logger::new(console_sink(), target="app")
  .child("worker")
  .bind([field("component", "worker")])
```

In this example, `bind(...)` communicates intent without changing underlying behavior.

And the returned logger still keeps the same target and level-gating behavior as the source logger.

### Error Case

e.g.:
- If `fields` is empty, the returned logger remains valid and simply adds no extra metadata.

- If duplicate field keys are bound, all copies are preserved for downstream formatting or inspection.

### Notes

1. Use `bind(...)` and `with_context_fields(...)` interchangeably; choose the one that reads better in context.

2. This alias exists for ergonomics, not for different semantics.

3. Use `with_context_fields(...)` when the longer name makes the sink-type change to `ContextSink[S]` clearer at the call site.

