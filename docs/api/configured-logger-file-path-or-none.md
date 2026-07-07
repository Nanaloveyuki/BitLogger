---
name: configured-logger-file-path-or-none
group: api
category: runtime
update-time: 20260707
description: Read the effective file path from a ConfiguredLogger only when it is actually file-backed.
key-word:
    - logger
    - runtime
    - file
    - truthful
---

## Configured-logger-file-path-or-none

Read the effective file path from a `ConfiguredLogger` only when it is actually file-backed.

This is the truthful companion to `file_path()`. Prefer it for diagnostics, branching, and recovery logic that must distinguish “not file-backed” from compatibility fallbacks.

### Interface

```moonbit
pub fn ConfiguredLogger::file_path_or_none(self : ConfiguredLogger) -> String? {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file path should be inspected.

#### output

- `String?` - `Some(path)` when the configured sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return `Some(path)` through the wrapped `RuntimeSink`.
- Queued file sinks forward the wrapped inner file sink path as `Some(path)`.
- Non-file sinks return `None`.
- This helper is observation-only and does not mutate logger state.

### How to Use

Here are some specific examples provided.

#### When Need Truthful File-backed Detection

When code should branch only if file semantics really exist:
```moonbit
match logger.file_path_or_none() {
  Some(path) => println(path)
  None => ()
}
```

In this example, `None` means the configured logger is not file-backed.

#### When Need Path Diagnostics Without Fallback Values

When support output should avoid compatibility placeholders:
```moonbit
let maybe_path = logger.file_path_or_none()
```

In this example, callers can keep “no file semantics” distinct from a real path.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `None`.

- If callers need the broader file snapshot or queue context, prefer `file_state_or_none()` or `file_runtime_state()`.

### Notes

1. Prefer this helper over `file_path()` for truthful runtime diagnostics.

2. `file_path()` remains available as the compatibility fallback API.
