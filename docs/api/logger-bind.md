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

- `Logger[ContextSink[S]]` - New logger wrapper that prepends shared fields at write time.

### Explanation

Detailed rules explaining key parameters and behaviors

- `bind(...)` delegates directly to `with_context_fields(...)`.
- The original logger value is not mutated; a wrapped logger is returned.
- Shared fields are applied to every later log call emitted through the returned logger.
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

### Error Case

e.g.:
- If `fields` is empty, the returned logger remains valid and simply adds no extra metadata.

- If duplicate field keys are bound, all copies are preserved for downstream formatting or inspection.

### Notes

1. Use `bind(...)` and `with_context_fields(...)` interchangeably; choose the one that reads better in context.

2. This alias exists for ergonomics, not for different semantics.

