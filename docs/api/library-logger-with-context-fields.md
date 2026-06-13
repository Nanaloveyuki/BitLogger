---
name: library-logger-with-context-fields
group: api
category: facade
update-time: 20260613
description: Attach reusable structured fields to a LibraryLogger facade.
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
- `fields : Array[Field]` - Structured fields that will be prepended to each emitted record.

#### output

- `LibraryLogger[ContextSink[S]]` - New library-facing facade wrapping the original sink with context-field merging behavior.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to the wrapped logger's `with_context_fields(...)` behavior and then narrows the result back to `LibraryLogger`.
- Context fields are merged at write time rather than by mutating previously created records.
- The returned facade carries `ContextSink[S]` because the sink pipeline has been extended.
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

### Error Case

e.g.:
- If `fields` is empty, the returned facade remains valid and simply adds no extra metadata.

- If duplicate field keys are provided, all fields are still emitted for downstream formatting or inspection.

### Notes

1. Use this for stable shared metadata, not highly dynamic event-specific values.

2. The narrower `LibraryLogger` surface is preserved after context binding.
