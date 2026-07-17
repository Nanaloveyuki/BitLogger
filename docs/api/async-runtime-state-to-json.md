---
name: async-runtime-state-to-json
group: api
category: async
update-time: 20260614
description: Convert AsyncRuntimeState into a JSON value for runtime capability and mode diagnostics using the canonical mode labels and snapshot field names.
key-word:
    - async
    - state
    - json
    - public
---

## Async-runtime-state-to-json

Convert `AsyncRuntimeState` into a `Json`. This helper exports the async runtime mode and background worker capability in a structured form.

### Interface

```moonbit
pub fn async_runtime_state_to_json(state : AsyncRuntimeState) -> Json {}
```

#### input

- `state : AsyncRuntimeState` - Runtime capability snapshot, usually produced by `async_runtime_state()`.

#### output

- `Json` - Structured JSON representation of the runtime state.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `mode` and `background_worker`.
- `mode` is serialized through `async_runtime_mode_label(...)`.
- The compact serialized shape is `{"mode":"native_worker|compatibility","background_worker":true|false}`.
- This helper focuses on runtime capabilities rather than queue counters or logger lifecycle flags.
- The exported JSON is suitable for diagnostics endpoints and startup environment checks.
- This helper serializes the provided `AsyncRuntimeState` exactly as given; it does not call `async_runtime_state()` or recheck backend capability by itself.
- That means manually constructed runtime snapshots are exported unchanged, with `mode` relabeled through `async_runtime_mode_label(...)` and `background_worker` kept exactly as supplied.

### How to Use

Here are some specific examples provided.

#### When Need Structured Runtime Capability Checks

When startup diagnostics should include async runtime capability data:
```moonbit
let runtime_json = async_runtime_state_to_json(async_runtime_state())
```

In this example, the runtime snapshot becomes a reusable JSON value.

#### When Need To Embed Runtime State In A Larger Payload

When async support should be one field in a bigger diagnostics object:
```moonbit
let payload = async_runtime_state_to_json(state)
```

In this example, callers can reuse the exported object directly.

### Error Case

e.g.:
- If callers expect logger queue counters or failure status, this API is too narrow and `async_logger_state_to_json(...)` should be used instead.

- If the runtime is in compatibility mode, the helper still serializes normally using the matching mode label.

- If callers need the current backend-derived runtime rather than an older or synthetic snapshot, they must capture a fresh `async_runtime_state()` first.

### Notes

1. The output field names are fixed as `mode` and `background_worker`.

2. The `mode` field always uses the canonical labels from `async_runtime_mode_label(...)`, not enum names like `NativeWorker` or `Compatibility`.

