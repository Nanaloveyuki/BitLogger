---
name: async-runtime-mode-label
group: api
category: async
update-time: 20260614
description: Convert AsyncRuntimeMode into its canonical stable string label for logs, JSON, and diagnostics.
key-word:
    - async
    - runtime
    - label
    - public
---

## Async-runtime-mode-label

Convert `AsyncRuntimeMode` into a stable string label. This helper is useful when runtime mode should be logged, serialized, or exposed through human-readable diagnostics.

### Interface

```moonbit
pub fn async_runtime_mode_label(mode : AsyncRuntimeMode) -> String {}
```

#### input

- `mode : AsyncRuntimeMode` - Runtime mode enum value.

#### output

- `String` - Stable mode label such as `native_worker` or `compatibility`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned value is intended for diagnostics and stable output, not just debugging prints.
- It keeps mode serialization logic in one place.
- This helper is used by async runtime JSON helpers.
- Labels are more stable for telemetry and docs than ad hoc manual matching at call sites.
- The current canonical labels are exactly `native_worker` for `NativeWorker` and `compatibility` for `Compatibility`.

### How to Use

Here are some specific examples provided.

#### When Need A Stable Log Label

When the mode should be included in structured or plain logs:
```moonbit
println(async_runtime_mode_label(async_runtime_mode()))
```

In this example, the label is directly usable in diagnostics.

#### When Build Custom Serialization

When callers want to embed the mode into their own payloads:
```moonbit
let label = async_runtime_mode_label(async_runtime_mode())
```

In this example, code gets a stable string without duplicating enum matching logic.

### Error Case

e.g.:
- This API assumes a valid `AsyncRuntimeMode` input and does not expose a normal runtime error path.

- If callers need the whole runtime object rather than a string label, use `async_runtime_state()`.

### Notes

1. Use this helper when mode values should be rendered as stable text instead of manual enum matching.

2. `async_runtime_state_to_json(...)` uses these exact labels when serializing runtime snapshots.

