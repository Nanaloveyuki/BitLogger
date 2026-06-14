---
name: async-runtime-supports-background-worker
group: api
category: async
update-time: 20260512
description: Return whether the current backend provides native async background worker support.
key-word:
    - async
    - runtime
    - worker
    - public
---

## Async-runtime-supports-background-worker

Return a boolean telling callers whether the current backend provides native background worker semantics for `bitlogger_async`. This is the narrowest capability probe when only worker support matters.

### Interface

```moonbit
pub fn async_runtime_supports_background_worker() -> Bool {}
```

#### input

- `none` - No explicit arguments are required.

#### output

- `Bool` - `true` when native background worker semantics are available, otherwise `false`.

### Explanation

Detailed rules explaining key parameters and behaviors

- `true` indicates native worker capability.
- `false` indicates compatibility-mode behavior.
- This helper is derived from backend-specific async runtime implementation choice.
- The boolean is read from the active backend helper on each call rather than from a cached runtime snapshot object.
- In the current backend split, the native implementation returns `true` while the compatibility stub returns `false`, matching the same mode pair exposed through `async_runtime_mode()` and `async_runtime_state()`.
- The async library still targets multiple backends even when this helper returns `false`.
- Use it when an enum branch is unnecessary and a boolean capability check is enough.

### How to Use

Here are some specific examples provided.

#### When Need A Simple Capability Branch

When logic only depends on worker availability:
```moonbit
if async_runtime_supports_background_worker() {
  println("native worker available")
}
```

In this example, callers avoid a more verbose mode match.

#### When Add Diagnostics Labels

When capability should be surfaced in diagnostics:
```moonbit
println(if async_runtime_supports_background_worker() { "worker" } else { "compat" })
```

In this example, a simple boolean can drive compact status output.

### Error Case

e.g.:
- This API does not normally fail at runtime; it reflects compiled backend behavior.

- If callers need the current paired mode and worker flag together, prefer a fresh `async_runtime_state()` call instead of mixing this boolean with an older saved mode value.

- If you need the exact mode name rather than a boolean, use `async_runtime_mode()` or `async_runtime_state()`.

### Notes

1. Use this helper for minimal capability checks.

2. Prefer `async_runtime_state()` when you want the same information in a richer object.

3. A `false` result should be read as "compatibility-mode runtime behavior" rather than "async library unsupported on this target".

4. This helper does not by itself imply that every non-worker backend has been equally re-verified for the current release; see [target-verification.md](./target-verification.md).
