---
name: async-runtime-state-to-json
group: api
category: async
update-time: 20260512
description: Convert AsyncRuntimeState into a JSON value for runtime capability and mode diagnostics.
key-word:
    - async
    - state
    - json
    - public
---

## Async-runtime-state-to-json

Convert `AsyncRuntimeState` into a `JsonValue`. This helper exports the async runtime mode and background worker capability in a structured form.

### Interface

```moonbit
pub fn async_runtime_state_to_json(state : AsyncRuntimeState) -> @json_parser.JsonValue {}
```

#### input

- `state : AsyncRuntimeState` - Runtime capability snapshot, usually produced by `async_runtime_state()`.

#### output

- `JsonValue` - Structured JSON representation of the runtime state.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `mode` and `background_worker`.
- `mode` is serialized through `async_runtime_mode_label(...)`.
- This helper focuses on runtime capabilities rather than queue counters or logger lifecycle flags.
- The exported JSON is suitable for diagnostics endpoints and startup environment checks.

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

### Notes

Notes are here.

1. This helper exports runtime capability state, not logger workload state.

2. Use it with `async_runtime_state()` for a fresh snapshot.

3. Prefer `stringify_async_runtime_state(...)` when immediate text output is enough.

4. The output is useful for environment diagnostics across targets.
