---
name: configured-logger-file-state-or-none
group: api
category: runtime
update-time: 20260707
description: Read the current file sink snapshot from a ConfiguredLogger only when it is actually file-backed.
key-word:
    - logger
    - runtime
    - file
    - truthful
---

## Configured-logger-file-state-or-none

Read the current file sink snapshot from a `ConfiguredLogger` only when it is actually file-backed.

This is the truthful companion to `file_state()`. Prefer it when diagnostics or recovery logic must not confuse fallback snapshots with real file state.

### Interface

```moonbit
pub fn ConfiguredLogger::file_state_or_none(self : ConfiguredLogger) -> FileSinkState? {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file state snapshot should be inspected.

#### output

- `FileSinkState?` - `Some(snapshot)` when the configured sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return `Some(live_snapshot)` through the wrapped `RuntimeSink`.
- Queued file sinks forward the wrapped inner file sink snapshot as `Some(live_snapshot)`.
- Non-file sinks return `None`.
- This helper is broader than individual counters or policy reads because it returns the aggregated file snapshot without fallback synthesis.

### How to Use

Here are some specific examples provided.

#### When Need Truthful File Health Diagnostics

When support output should include file state only for real file-backed sinks:
```moonbit
match logger.file_state_or_none() {
  Some(state) => println(stringify_file_sink_state(state, pretty=true))
  None => ()
}
```

In this example, no compatibility snapshot is fabricated for non-file sinks.

#### When Need State Without Queue Expansion

When code only needs the file snapshot and not queue metadata:
```moonbit
let maybe_state = logger.file_state_or_none()
```

In this example, `None` cleanly signals missing file semantics.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `None`.

- If callers also need queue metrics for queued file sinks, prefer `file_runtime_state()`.

### Notes

1. Prefer this helper over `file_state()` for truthful runtime diagnostics.

2. `file_state()` remains available as the compatibility fallback API.
