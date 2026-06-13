---
name: library-logger-bind
group: api
category: facade
update-time: 20260613
description: Attach reusable structured fields to a LibraryLogger facade through the bind alias.
key-word:
    - library
    - facade
    - bind
    - public
---

## Library-logger-bind

Attach shared structured fields to a `LibraryLogger[S]` through the `bind(...)` alias. This is behaviorally identical to `with_context_fields(...)` and exists as a shorter name for common library-facing context binding.

### Interface

```moonbit
pub fn[S] LibraryLogger::bind(
  self : LibraryLogger[S],
  fields : Array[Field],
) -> LibraryLogger[ContextSink[S]] {
```

#### input

- `self : LibraryLogger[S]` - Base facade that should gain shared fields.
- `fields : Array[Field]` - Structured fields attached to every emitted record.

#### output

- `LibraryLogger[ContextSink[S]]` - New library-facing wrapper that prepends shared fields at write time.

### Explanation

Detailed rules explaining key parameters and behaviors

- `bind(...)` delegates directly to `with_context_fields(...)`.
- The original facade value is not mutated; a wrapped facade is returned.
- Shared fields are applied to every later log call emitted through the returned facade.
- This alias is useful when you prefer shorter chaining syntax in library code.

### How to Use

Here are some specific examples provided.

#### When Bind Shared Package Context

When a library logger should carry stable metadata through a flow:
```moonbit
let request_logger = default_library_logger()
  .with_target("sdk")
  .bind([field("request_id", "req-42")])
```

In this example, subsequent writes automatically include `request_id`.

#### When Prefer Shorter Chaining Syntax

When a context-bound child facade should stay readable:
```moonbit
let worker = LibraryLogger::new(console_sink(), target="app")
  .child("worker")
  .bind([field("component", "worker")])
```

In this example, `bind(...)` communicates intent without changing underlying behavior.

### Error Case

e.g.:
- If `fields` is empty, the returned facade remains valid and simply adds no extra metadata.

- If duplicate field keys are bound, all copies are preserved for downstream formatting or inspection.

### Notes

1. Use `bind(...)` and `with_context_fields(...)` interchangeably; choose the one that reads better in context.

2. This alias exists for ergonomics, not for different semantics.
