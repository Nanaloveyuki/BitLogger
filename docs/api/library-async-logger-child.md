---
name: library-async-logger-child
group: api
category: facade
update-time: 20260614
description: Derive a child LibraryAsyncLogger facade by composing the current target with a child segment while rewrapping the derived async logger state behind the same library-facing surface.
key-word:
    - async
    - library
    - child
    - public
---

## Library-async-logger-child

Create a child `LibraryAsyncLogger[S]` by composing the current target with another target segment. This is the library-facing hierarchical naming helper for async targets such as `sdk.cache` or `plugin.worker.io`.

### Interface

```moonbit
pub fn[S] LibraryAsyncLogger::child(
  self : LibraryAsyncLogger[S],
  target : String,
) -> LibraryAsyncLogger[S] {
```

#### input

- `self : LibraryAsyncLogger[S]` - Parent facade whose target should be extended.
- `target : String` - Child target segment or suffix.

#### output

- `LibraryAsyncLogger[S]` - New library-facing async facade whose target is the composed child path.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to the wrapped async logger's `child(...)` behavior and then re-wraps the result as another `LibraryAsyncLogger[S]`.
- If the parent target is empty, the child target becomes the full target.
- If the child target is empty, the parent target is preserved.
- If both are non-empty, they are joined with `.`.
- The original facade is not mutated. The returned facade stores the derived child target while the source facade keeps its previous parent target.
- Timestamp behavior, enabled-level gating, sink type, queue state, async config, and failure/lifecycle state remain the same because only the derived default target changes.
- Async state helpers remain hidden behind the narrower facade after rewrapping; use `to_async_logger()` if later code needs them.

### How to Use

Here are some specific examples provided.

#### When Need Hierarchical Async Naming In A Library API

When a package wants stable namespace composition without exposing `AsyncLogger[S]`:
```moonbit
let worker = LibraryAsyncLogger::new(@bitlogger.console_sink())
  .with_target("plugin")
  .child("worker")
```

In this example, the final target becomes `plugin.worker`.

#### When Build Scoped Async Facades Step By Step

When deeper target composition should stay readable:
```moonbit
let client = LibraryAsyncLogger::new(@bitlogger.console_sink(), target="sdk")
  .child("http")
  .child("client")
```

In this example, the final facade emits under `sdk.http.client`.

And the target derivation does not rebuild or reset the wrapped async logger state.

The derived facade still uses the same timestamp and level-gating behavior as the source facade.

### Error Case

e.g.:
- If `target` is empty, the returned facade keeps the original parent target.

- If callers need complete replacement instead of composition, `with_target(...)` should be used instead.

### Notes

1. This is the preferred library-facing API for hierarchical async target naming.

2. Composition changes the target only and does not rebuild the queue or sink.

3. Use `with_target(...)` instead when the new target should replace the current target rather than extend it.
