---
name: library-logger-child
group: api
category: facade
update-time: 20260613
description: Derive a child LibraryLogger facade by composing the current target with a child segment while rewrapping the same underlying logger state.
key-word:
    - library
    - facade
    - child
    - public
---

## Library-logger-child

Create a child `LibraryLogger[S]` by composing the current target with another target segment. This is the library-facing hierarchical naming helper for targets such as `sdk.cache` or `plugin.worker.io`.

### Interface

```moonbit
pub fn[S] LibraryLogger::child(self : LibraryLogger[S], target : String) -> LibraryLogger[S] {
```

#### input

- `self : LibraryLogger[S]` - Parent facade whose target should be extended.
- `target : String` - Child target segment or suffix.

#### output

- `LibraryLogger[S]` - New library-facing facade whose target is the composed child path.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to the wrapped logger's `child(...)` behavior and then re-wraps the result.
- If the parent target is empty, the child target becomes the full target.
- If the child target is empty, the parent target is preserved.
- If both are non-empty, they are joined with `.`.
- Sink type, minimum level, timestamp behavior, and any existing sink wrappers remain the same because only the derived target changes.
- Broader composition helpers remain hidden behind the narrower facade after rewrapping; use `to_logger()` if later code needs them.

### How to Use

Here are some specific examples provided.

#### When Need Hierarchical Target Naming In A Library API

When a package wants stable namespace composition without exposing `Logger[S]`:
```moonbit
let worker = default_library_logger()
  .with_target("plugin")
  .child("worker")
```

In this example, the final target becomes `plugin.worker`.

#### When Build Scoped Facades Step By Step

When deeper target composition should stay readable:
```moonbit
let client = LibraryLogger::new(console_sink(), target="sdk")
  .child("http")
  .child("client")
```

In this example, the final facade emits under `sdk.http.client`.

And the target derivation does not rebuild or reset the wrapped logger pipeline.

### Error Case

e.g.:
- If `target` is empty, the returned facade keeps the original parent target.

- If callers need complete replacement instead of composition, `with_target(...)` should be used instead.

### Notes

1. This is the preferred library-facing API for hierarchical target naming.

2. Composition uses `.` as the separator between parent and child segments.

3. Use `with_target(...)` instead when the new target should replace the current target rather than extend it.
