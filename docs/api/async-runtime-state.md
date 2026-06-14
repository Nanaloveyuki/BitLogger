---
name: async-runtime-state
group: api
category: async
update-time: 20260614
description: Read the current backend-specific async runtime snapshot as the paired result of runtime mode and background-worker capability.
key-word:
    - async
    - runtime
    - diagnostics
    - public
---

## Async-runtime-state

Read the current backend-specific async runtime state for diagnostics. This API focuses on the environment-level async mode rather than any one logger instance.

### Interface

```moonbit
pub fn async_runtime_state() -> AsyncRuntimeState {}
```

#### input

- `none` - This API reads the current backend mode and does not require logger input.

#### output

- `AsyncRuntimeState` - Runtime snapshot containing `mode` and `background_worker` capability.

### Explanation

Detailed rules explaining key parameters and behaviors

- `mode` is derived from the active backend implementation.
- `background_worker` tells callers whether native worker semantics are available.
- This helper is equivalent to `AsyncRuntimeState::new(async_runtime_mode(), async_runtime_supports_background_worker())`.
- The returned pair is rebuilt from those two lower-level helpers on each call rather than read from a cached runtime object.
- In the current backend implementations, the resulting pair is `NativeWorker + true` or `Compatibility + false`.
- `async_runtime_state_to_json(...)` and `stringify_async_runtime_state(...)` serialize this state.
- This API is environment-scoped and does not depend on a particular `AsyncLogger` instance.
- The returned value is a snapshot data object, not a live runtime handle, so later backend checks require calling `async_runtime_state()` again rather than reusing an older value as if it refreshed itself.

### How to Use

Here are some specific examples provided.

#### When Need Startup Diagnostics

When startup logs should reveal async backend behavior:
```moonbit
println(stringify_async_runtime_state(async_runtime_state(), pretty=true))
```

In this example, backend mode is exposed before any logger is started.

#### When Branch Behavior By Runtime Capability

When code should react differently depending on worker support:
```moonbit
let runtime = async_runtime_state()
if runtime.background_worker {
  println("native worker path")
}
```

In this example, branch decisions are based on actual runtime capability instead of assumptions.

### Error Case

e.g.:
- This API does not normally expose a dynamic error path; it reports the currently compiled backend behavior.

- The returned `AsyncRuntimeState` value is not cached onto the helper. If callers need a newer backend read, they must call `async_runtime_state()` again instead of expecting an older value to refresh itself.

- If callers need richer runtime state, they should use `AsyncLogger::state()` on a logger instance instead.

### Notes

1. Use this API for environment-level diagnostics.

2. Use `AsyncLogger::state()` for logger-instance diagnostics.

3. Use `AsyncRuntimeState::new(...)` only when code or tests need to construct a manual snapshot instead of probing the current backend.
