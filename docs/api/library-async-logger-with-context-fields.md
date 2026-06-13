---
name: library-async-logger-with-context-fields
group: api
category: facade
update-time: 20260613
description: Attach reusable structured fields to a LibraryAsyncLogger facade while rewrapping the same underlying async logger state.
key-word:
    - async
    - library
    - fields
    - public
---

## Library-async-logger-with-context-fields

Bind shared structured fields to a `LibraryAsyncLogger[S]`. This is the library-facing API for attaching stable metadata such as component name, plugin id, or request scope without repeating those fields on every async log call.

### Interface

```moonbit
pub fn[S] LibraryAsyncLogger::with_context_fields(
  self : LibraryAsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> LibraryAsyncLogger[S] {
```

#### input

- `self : LibraryAsyncLogger[S]` - Base facade that should gain shared fields.
- `fields : Array[@bitlogger.Field]` - Structured fields stored on the facade and prepended to each emitted record.

#### output

- `LibraryAsyncLogger[S]` - New library-facing async facade carrying the shared field set.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to the wrapped async logger's `with_context_fields(...)` behavior and then narrows the result back to `LibraryAsyncLogger`.
- The provided `fields` array replaces the previously stored shared context field set on the wrapped async logger.
- During later `log(...)` calls, those stored shared fields are prepended ahead of per-call fields before enqueue.
- Sink type, queue state, async config, and failure/lifecycle state remain the same because only the stored shared field set changes.
- Unlike synchronous `LibraryLogger::with_context_fields(...)`, this async variant preserves the visible `LibraryAsyncLogger[S]` type instead of changing the visible sink type.
- Async state helpers remain hidden behind the narrower facade after rewrapping; use `to_async_logger()` if later code needs them.
- `bind(...)` is an ergonomic alias for this same behavior.

### How to Use

Here are some specific examples provided.

#### When Need Stable Library Metadata On Every Async Record

When a package should attach fixed metadata to all queued records:
```moonbit
let logger = LibraryAsyncLogger::new(@bitlogger.console_sink())
  .with_target("plugin")
  .with_context_fields([
    @bitlogger.field("plugin", "alpha"),
    @bitlogger.field("region", "cn"),
  ])
```

In this example, both fields are automatically attached before every record enters the queue.

#### When Combine Async Target Scoping And Shared Fields

When a subsystem facade should carry both a target and stable context:
```moonbit
let worker = LibraryAsyncLogger::new(@bitlogger.console_sink(), target="sdk")
  .child("worker")
  .with_context_fields([@bitlogger.field("component", "worker")])
```

In this example, target composition and field binding stay separate but compose cleanly.

And the returned facade keeps the same underlying async runtime state while carrying a different shared field set.

### Error Case

e.g.:
- If `fields` is empty, the returned facade remains valid and simply stores an empty shared field set.

- If duplicate field keys are provided, all fields are still emitted for downstream formatting or inspection.

- If callers want to add event-specific fields without replacing the shared set, they should pass those through `log(..., fields=...)` on the returned facade.

### Notes

1. Use this for stable shared metadata, not highly dynamic event-specific values.

2. The narrower `LibraryAsyncLogger` surface is preserved after field binding.

3. Use `bind(...)` when the shorter alias reads better in chained library code.
