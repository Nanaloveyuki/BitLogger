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

- If you need the exact mode name rather than a boolean, use `async_runtime_mode()` or `async_runtime_state()`.

### Notes

Notes are here.

1. Use this helper for minimal capability checks.

2. Prefer `async_runtime_state()` when you want the same information in a richer object.

3. Prefer `AsyncLogger::state()` when logger-instance counters matter too.

4. This helper is intentionally small and should stay cheap to call.
