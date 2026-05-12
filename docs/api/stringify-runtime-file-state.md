---
name: stringify-runtime-file-state
group: api
category: runtime
update-time: 20260512
description: Serialize RuntimeFileState into compact or pretty JSON text for queued-file diagnostics and support output.
key-word:
    - runtime
    - file
    - state
    - public
---

## Stringify-runtime-file-state

Serialize `RuntimeFileState` into JSON text. This helper is the most direct export path for combined file-and-queue runtime diagnostics.

### Interface

```moonbit
pub fn stringify_runtime_file_state(state : RuntimeFileState, pretty~ : Bool = false) -> String {}
```

#### input

- `state : RuntimeFileState` - Combined file and queue runtime snapshot to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the runtime file state.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON for human diagnostics.
- This helper builds on top of `runtime_file_state_to_json(...)`.
- The output is useful when queued file runtime state should be printed directly during support or incident handling.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Queued-file Diagnostics

When a queued file runtime snapshot should be printed directly:
```moonbit
println(stringify_runtime_file_state(snapshot, pretty=true))
```

In this example, both file state and queue metrics are shown in one readable JSON payload.

#### When Need Compact Runtime Snapshot Export

When a combined file-and-queue snapshot should stay small:
```moonbit
let text = stringify_runtime_file_state(snapshot)
```

In this example, compact JSON is returned without extra formatting logic.

### Error Case

e.g.:
- If callers need a `JsonValue` rather than text, `runtime_file_state_to_json(...)` is the better API.

- If queue wrapping is not relevant, `stringify_file_sink_state(...)` may be the simpler API.

### Notes

1. Use this helper when queued-file diagnostics should be emitted as one JSON string.

2. `pretty=true` is useful for support output and manual inspection.
