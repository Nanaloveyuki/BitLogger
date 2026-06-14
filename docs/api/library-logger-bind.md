---
name: library-logger-bind
group: api
category: facade
update-time: 20260613
description: Attach reusable structured fields to a LibraryLogger facade through the bind alias while extending the visible sink type to ContextSink.
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
- Shared fields are applied to every later log call emitted through the returned facade.
- The returned facade changes visible type from `LibraryLogger[S]` to `LibraryLogger[ContextSink[S]]` because the sink pipeline is extended with context-field merging behavior.
- Minimum level, target, and timestamp behavior are preserved while the sink pipeline changes.
- Broader composition helpers remain hidden behind the narrower facade after rewrapping; use `to_logger()` if later code needs them.
- The original facade value is not mutated; a wrapped facade is returned.
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

And because it is only an alias, the resulting facade behaves the same as calling `with_context_fields(...)` directly.

### Error Case

e.g.:
- If `fields` is empty, the returned facade remains valid and simply stores an empty shared field set in `ContextSink[S]`.

- If duplicate field keys are bound, all copies are preserved for downstream formatting or inspection.

- If callers want event-specific fields without changing the shared bound set, they should pass those through `log(..., fields=...)` on the returned facade.

### Notes

1. Use `bind(...)` and `with_context_fields(...)` interchangeably; choose the one that reads better in context.

2. This alias exists for ergonomics, not for different semantics.

3. Use `with_context_fields(...)` when the longer name makes the shared-field sink-type change clearer at the call site.
