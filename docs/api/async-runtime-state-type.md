---
name: async-runtime-state-type
group: api
category: async
update-time: 20260614
description: Public async runtime state alias used for backend capability snapshots and diagnostics, pairing runtime mode with background-worker support.
key-word:
    - async
    - runtime
    - state
    - public
---

## Async-runtime-state-type

`AsyncRuntimeState` is the public snapshot type used to describe backend-level async runtime capability. It is a direct alias to the async runtime state model returned by `async_runtime_state()` and used by async diagnostics serializers.

### Interface

```moonbit
pub type AsyncRuntimeState = @utils.AsyncRuntimeState
```

#### output

- `AsyncRuntimeState` - Public runtime snapshot containing `mode` and `background_worker`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a live runtime controller.
- The current fields are `mode : AsyncRuntimeMode` and `background_worker : Bool`.
- `async_runtime_state()` returns this type directly as an environment-level snapshot.
- `async_runtime_state()` currently builds that snapshot from `async_runtime_mode()` and `async_runtime_supports_background_worker()`.
- `async_runtime_state_to_json(...)` and `stringify_async_runtime_state(...)` serialize the same snapshot shape for diagnostics.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Backend Capability Snapshot

When startup or diagnostics code should keep the runtime state as structured data:
```moonbit
let runtime : AsyncRuntimeState = async_runtime_state()
```

In this example, the backend capability snapshot stays available as a typed value instead of only as printed text.

#### When Need To Read Runtime Mode And Worker Support Together

When code should inspect both async mode and worker availability from one object:
```moonbit
let runtime = async_runtime_state()
if runtime.background_worker {
  println(async_runtime_mode_label(runtime.mode))
}
```

In this example, both fields are consumed from the same public snapshot type.

### Error Case

e.g.:
- `AsyncRuntimeState` itself does not have a runtime failure mode.

- The snapshot is point-in-time diagnostic data; it should not be treated as proof that every target was re-verified in the current release cycle.

- Because this is just a data shape, manual construction can represent combinations that do not come from the current backend probe.

### Notes

1. Use `async_runtime_state()` when you need a value of this type from the current backend.

2. Use `AsyncLoggerState` when logger-instance queue and lifecycle information is also required.

3. Use `async_runtime_mode_label(...)` when the `mode` field should be rendered as stable text such as `native_worker` or `compatibility`.
