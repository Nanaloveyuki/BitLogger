---
name: library-logger-with-context-fields
group: api
category: facade
update-time: 20260613
description: Attach reusable structured fields to a LibraryLogger facade while extending the visible sink type to ContextSink.
key-word:
    - library
    - facade
    - fields
    - public
---

## Library-logger-with-context-fields

Bind shared structured fields to a `LibraryLogger[S]`. This is the library-facing API for attaching stable metadata such as component name, plugin id, or request scope without repeating those fields on every log call.

### Interface

```moonbit
pub fn[S] LibraryLogger::with_context_fields(
  self : LibraryLogger[S],
  fields : Array[Field],
) -> LibraryLogger[ContextSink[S]] {
```

#### input

- `self : LibraryLogger[S]` - Base facade that should gain shared fields.
- `fields : Array[Field]` - Structured fields stored in the added `ContextSink` and prepended to each emitted record.

#### output

- `LibraryLogger[ContextSink[S]]` - New library-facing facade wrapping the original sink with context-field merging behavior.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to the wrapped logger's `with_context_fields(...)` behavior and then narrows the result back to `LibraryLogger`.
- Context fields are merged at write time rather than by mutating previously created records.
- The returned facade carries `ContextSink[S]` because the sink pipeline is extended around the previous sink instead of keeping the original visible sink type `S`.
- Minimum level, target, and timestamp behavior are preserved while the sink pipeline changes from `S` to `ContextSink[S]`.
- Broader composition helpers remain hidden behind the narrower facade after rewrapping; use `to_logger()` if later code needs them.
- `bind(...)` is an ergonomic alias for this same behavior.

### How to Use

Here are some specific examples provided.

#### When Need Stable Library Metadata On Every Record

When a package should attach fixed metadata to all emitted records:
```moonbit
let logger = default_library_logger()
  .with_target("plugin")
  .with_context_fields([field("plugin", "alpha"), field("region", "cn")])
```

In this example, both fields are automatically included on every later write.

#### When Combine Target Scoping And Shared Fields

When a subsystem facade should carry both a target and stable context:
```moonbit
let worker = LibraryLogger::new(console_sink(), target="sdk")
  .child("worker")
  .with_context_fields([field("component", "worker")])
```

In this example, target composition and field binding stay separate but compose cleanly.

And the returned facade keeps the same logger configuration while exposing the widened sink type `ContextSink[S]`.

### Error Case

e.g.:
- If `fields` is empty, the returned facade remains valid and simply stores an empty shared field set inside `ContextSink[S]`.

- If duplicate field keys are provided, all fields are still emitted for downstream formatting or inspection.

- If callers want event-specific fields without changing the shared bound set, they should pass those through `log(..., fields=...)` on the returned facade.

### Notes

1. Use this for stable shared metadata, not highly dynamic event-specific values.

2. The narrower `LibraryLogger` surface is preserved after context binding, even though the visible sink type changes to `ContextSink[S]`.

3. Use `bind(...)` when the shorter alias reads better in chained library code.
