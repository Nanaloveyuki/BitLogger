---
name: configured-logger-file-available
group: api
category: runtime
update-time: 20260707
description: Read whether the configured runtime logger currently has an available file sink behind its runtime sink shape.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-available

Read whether a `ConfiguredLogger` currently has an available file sink. This helper is useful for runtime diagnostics and recovery checks after config-driven file logger construction.

### Interface

```moonbit
pub fn ConfiguredLogger::file_available(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file sink availability should be inspected.

#### output

- `Bool` - Whether an underlying file sink is available.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed runtime sinks report actual file availability through the wrapped `RuntimeSink`.
- Queued file sinks still expose the availability of their wrapped inner file sink.
- Non-file sinks report `false`.
- This means `false` currently merges two different situations: “not file-backed” and “file-backed but currently unavailable”.
- Use `file_path_or_none()`, `file_policy_or_none()`, `file_default_policy_or_none()`, `file_state_or_none()`, or `file_runtime_state()` when callers need truthful file-semantics detection.
- This helper delegates to the runtime sink and does not mutate logger state.

### How to Use

Here are some specific examples provided.

#### When Need Runtime File Health Checks

When operators or code should check file sink readiness:
```moonbit
if !logger.file_available() {
  println("file sink unavailable")
}
```

In this example, the configured logger exposes file health directly.

#### When Gate Recovery Logic

When reopen or fallback behavior depends on file availability:
```moonbit
let ok = logger.file_available()
```

In this example, callers can decide whether a recovery action is needed.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need to distinguish “not file-backed” from “file-backed but unavailable”, use one of the truthful `*_or_none()` helpers or `file_runtime_state()`.

- If callers need detailed failure counters rather than a simple availability flag, `file_state_or_none()` or `file_runtime_state()` is the better API.

### Notes

1. Use this helper for lightweight file sink health checks.

2. Pair it with reopen and failure-counter APIs when diagnosing file sink problems, but prefer the truthful `*_or_none()` helpers when file semantics themselves must be checked.
