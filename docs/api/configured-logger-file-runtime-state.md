---
name: configured-logger-file-runtime-state
group: api
category: runtime
update-time: 20260512
description: Read combined file and queue runtime state from a configured logger when it is backed by a file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-runtime-state

Read combined file and queue runtime state from a `ConfiguredLogger`. This helper is the richest file-specific diagnostics API on config-built runtime loggers.

### Interface

```moonbit
pub fn ConfiguredLogger::file_runtime_state(self : ConfiguredLogger) -> RuntimeFileState? {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file runtime state should be inspected.

#### output

- `RuntimeFileState?` - Combined file and queue diagnostics when the runtime sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return `Some(RuntimeFileState)` through the wrapped `RuntimeSink`.
- Queued file sinks include both file status and queue metrics in the returned state.
- Non-file sinks return `None`.
- This helper is richer than `file_state()` because it can also surface queued backlog and dropped counts.

### How to Use

Here are some specific examples provided.

#### When Need Rich File Runtime Diagnostics

When support output should include both file and queue state:
```moonbit
let state = logger.file_runtime_state()
```

In this example, callers can inspect availability, failure counters, and queue metrics together.

#### When Need To Branch On File-backed Runtime Shape

When code should behave differently for file-backed config-built loggers:
```moonbit
match logger.file_runtime_state() {
  Some(state) => ignore(state)
  None => ()
}
```

In this example, the optional return value reflects whether the runtime sink is file-backed.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `None`.

- If callers only need raw file status without queue context, `file_state()` may be the simpler API.

### Notes

1. Use this helper for the richest file-backed runtime diagnostics on config-built loggers.

2. It is especially useful for queued file sinks where file health and queue state both matter.
