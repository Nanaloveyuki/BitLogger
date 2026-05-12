---
name: configured-logger-file-available
group: api
category: runtime
update-time: 20260512
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

- File-backed runtime sinks report actual file availability.
- Non-file sinks report `false`.
- Queued file sinks still expose the availability of their wrapped file sink.
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

- If callers need detailed failure counters rather than a simple availability flag, `file_state()` or `file_runtime_state()` is the better API.

### Notes

1. Use this helper for lightweight file sink health checks.

2. Pair it with reopen and failure-counter APIs when diagnosing file sink problems.
