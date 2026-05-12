---
name: stringify-async-runtime-state
group: api
category: async
update-time: 20260512
description: Serialize AsyncRuntimeState into compact or pretty JSON text for diagnostics and startup reporting.
key-word:
    - async
    - state
    - stringify
    - public
---

## Stringify-async-runtime-state

Serialize `AsyncRuntimeState` into JSON text. This helper is the most direct reporting path for async runtime mode and background worker capability.

### Interface

```moonbit
pub fn stringify_async_runtime_state(
  state : AsyncRuntimeState,
  pretty~ : Bool = false,
) -> String {}
```

#### input

- `state : AsyncRuntimeState` - Runtime capability snapshot to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the runtime state.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON for human diagnostics.
- This helper is built on top of `async_runtime_state_to_json(...)`.
- It is well-suited for startup banners, support reports, and target capability logs.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Runtime Diagnostics

When capability information should be printed during startup:
```moonbit
println(stringify_async_runtime_state(async_runtime_state(), pretty=true))
```

In this example, the runtime state is emitted in a readable form.

#### When Need Compact Capability Logs

When runtime info should stay small in structured logs:
```moonbit
let text = stringify_async_runtime_state(async_runtime_state())
```

In this example, compact JSON is returned without extra formatting.

### Error Case

e.g.:
- If callers need a JSON value rather than text, they should use `async_runtime_state_to_json(...)` instead.

- If more complete async logger diagnostics are required, this helper should be replaced with `stringify_async_logger_state(...)`.

### Notes

Notes are here.

1. This API reports runtime capability state only.

2. `pretty=true` is more suitable for humans and support output.

3. The compact default is better for transport and structured logging.

4. This helper is useful when comparing target-specific async runtime behavior.
