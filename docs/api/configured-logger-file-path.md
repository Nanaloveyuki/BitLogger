---
name: configured-logger-file-path
group: api
category: runtime
update-time: 20260512
description: Read the effective file path used by the configured runtime logger when it is file-backed.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-path

Read the effective file path used by a `ConfiguredLogger`. This helper is useful for diagnostics, support output, and confirming which file-backed runtime sink is active.

### Interface

```moonbit
pub fn ConfiguredLogger::file_path(self : ConfiguredLogger) -> String {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file path should be inspected.

#### output

- `String` - Effective runtime file path, or an empty string for non-file sinks.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return their current file path through the wrapped `RuntimeSink`.
- Queued file sinks forward the wrapped inner file sink path.
- Non-file sinks return an empty string.
- This helper is observation-only and does not modify file state.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Path Diagnostics

When diagnostics should show which file is active:
```moonbit
println(logger.file_path())
```

In this example, operators can verify the effective destination path directly.

#### When Build Support Output

When application state dumps should include file destination info:
```moonbit
let path = logger.file_path()
```

In this example, the path can be surfaced without reading broader runtime state.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns an empty string.

- If callers need richer file status than just the path, `file_state()` or `file_runtime_state()` is the better API.

### Notes

1. Use this helper for direct runtime path visibility.

2. Empty string usually means the configured sink is not file-backed.
