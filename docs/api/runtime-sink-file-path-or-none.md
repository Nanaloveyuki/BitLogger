---
name: runtime-sink-file-path-or-none
group: api
category: runtime
update-time: 20260707
description: Read the effective file path from a RuntimeSink only when it is actually file-backed.
key-word:
    - runtime
    - sink
    - file
    - truthful
---

## Runtime-sink-file-path-or-none

Read the effective file path from a `RuntimeSink` only when it is actually file-backed.

This is the truthful companion to `file_path()`. Prefer it for diagnostics, branching, and recovery logic that must distinguish “not file-backed” from compatibility fallbacks.

### Interface

```moonbit
pub fn RuntimeSink::file_path_or_none(self : RuntimeSink) -> String? {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file path should be inspected.

#### output

- `String?` - `Some(path)` when the runtime sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return `Some(path)`.
- `QueuedFile` runtime variants forward the wrapped inner file sink path as `Some(path)`.
- Non-file runtime variants return `None`.
- This helper is observation-only and does not mutate runtime state.

### How to Use

Here are some specific examples provided.

#### When Need Truthful File-backed Detection

When code should branch only if file semantics really exist:
```moonbit
match sink.file_path_or_none() {
  Some(path) => println(path)
  None => ()
}
```

In this example, `None` means the runtime sink is not file-backed.

#### When Need Path Diagnostics Without Fallback Values

When support output should avoid compatibility placeholders:
```moonbit
let maybe_path = sink.file_path_or_none()
```

In this example, callers can keep “no file semantics” distinct from a real path.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `None`.

- If callers need the broader file snapshot or queue context, prefer `file_state_or_none()` or `file_runtime_state()`.

### Notes

1. Prefer this helper over `file_path()` for truthful runtime diagnostics.

2. `file_path()` remains available as the compatibility fallback API.
