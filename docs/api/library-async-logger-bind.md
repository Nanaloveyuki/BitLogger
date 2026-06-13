---
name: library-async-logger-bind
group: api
category: facade
update-time: 20260613
description: Attach reusable structured fields to a LibraryAsyncLogger facade through the bind alias.
key-word:
    - async
    - library
    - bind
    - public
---

## Library-async-logger-bind

Attach shared structured fields to a `LibraryAsyncLogger[S]` through the `bind(...)` alias. This is behaviorally identical to `with_context_fields(...)` and exists as a shorter name for common library-facing async context binding.

### Interface

```moonbit
pub fn[S] LibraryAsyncLogger::bind(
  self : LibraryAsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> LibraryAsyncLogger[S] {
```

#### input

- `self : LibraryAsyncLogger[S]` - Base facade that should gain shared fields.
- `fields : Array[@bitlogger.Field]` - Structured fields attached to every emitted record.

#### output

- `LibraryAsyncLogger[S]` - New library-facing async wrapper that carries the shared field set.

### Explanation

Detailed rules explaining key parameters and behaviors

- `bind(...)` delegates directly to `with_context_fields(...)`.
- The original facade value is not mutated; a wrapped facade is returned.
- Shared fields are applied to every later log call emitted through the returned facade.
- This alias is useful when you prefer shorter chaining syntax in library async code.

### How to Use

Here are some specific examples provided.

#### When Bind Shared Package Context For Async Writes

When a library async logger should carry stable metadata through a flow:
```moonbit
let request_logger = LibraryAsyncLogger::new(@bitlogger.console_sink())
  .with_target("sdk")
  .bind([@bitlogger.field("request_id", "req-42")])
```

In this example, subsequent async writes automatically include `request_id`.

#### When Prefer Shorter Async Chaining Syntax

When a context-bound child async facade should stay readable:
```moonbit
let worker = LibraryAsyncLogger::new(@bitlogger.console_sink(), target="app")
  .child("worker")
  .bind([@bitlogger.field("component", "worker")])
```

In this example, `bind(...)` communicates intent without changing underlying behavior.

### Error Case

e.g.:
- If `fields` is empty, the returned facade remains valid and simply adds no extra metadata.

- If duplicate field keys are bound, all copies are preserved for downstream formatting or inspection.

### Notes

1. Use `bind(...)` and `with_context_fields(...)` interchangeably; choose the one that reads better in context.

2. This alias exists for ergonomics, not for different semantics.
