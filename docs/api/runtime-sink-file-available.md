---
name: runtime-sink-file-available
group: api
category: runtime
update-time: 20260707
description: Read whether a RuntimeSink currently has an available file sink behind its runtime sink shape.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-available

Read whether a `RuntimeSink` currently has an available file sink. This helper is useful for direct runtime diagnostics and recovery checks when code owns a runtime sink value instead of a `ConfiguredLogger`.

### Interface

```moonbit
pub fn RuntimeSink::file_available(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file sink availability should be inspected.

#### output

- `Bool` - Whether an underlying file sink is available.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report actual file availability.
- `QueuedFile` runtime variants expose the availability of their wrapped inner file sink.
- Non-file runtime variants return `false`.
- This means `false` currently merges two different situations: “not file-backed” and “file-backed but currently unavailable”.
- Use `file_path_or_none()`, `file_policy_or_none()`, `file_default_policy_or_none()`, `file_state_or_none()`, or `file_runtime_state()` when callers need truthful file-semantics detection.
- This helper does not mutate runtime sink state.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime File Health Checks

When operators or code should check file sink readiness on a runtime sink value:
```moonbit
if !sink.file_available() {
  println("file sink unavailable")
}
```

In this example, the runtime sink exposes file health directly.

#### When Gate Direct Recovery Logic

When reopen or fallback behavior depends on file availability:
```moonbit
let ok = sink.file_available()
```

In this example, callers can decide whether a recovery action is needed.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need to distinguish “not file-backed” from “file-backed but unavailable”, use one of the truthful `*_or_none()` helpers or `file_runtime_state()`.

- If callers need detailed failure counters rather than a simple availability flag, `file_state_or_none()` or `file_runtime_state()` is the better API.

### Notes

1. Use this helper for lightweight file sink health checks on direct `RuntimeSink` values.

2. Pair it with reopen and failure-counter APIs when diagnosing file sink problems, but prefer the truthful `*_or_none()` helpers when file semantics themselves must be checked.
