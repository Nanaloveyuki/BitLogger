---
name: async-runtime-state
group: api
category: async
update-time: 20260512
description: Read the current backend-specific async runtime mode and worker capability.
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
- `async_runtime_state_to_json(...)` and `stringify_async_runtime_state(...)` serialize this state.
- This API is environment-scoped and does not depend on a particular `AsyncLogger` instance.

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

- If callers need richer runtime state, they should use `AsyncLogger::state()` on a logger instance instead.

### Notes

1. Use this API for environment-level diagnostics.

2. Use `AsyncLogger::state()` for logger-instance diagnostics.
