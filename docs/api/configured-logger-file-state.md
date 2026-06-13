---
name: configured-logger-file-state
group: api
category: runtime
update-time: 20260512
description: Read the current file sink snapshot from a configured runtime logger.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-state

Read the current file sink snapshot from a `ConfiguredLogger`. This helper exposes path, availability, policy flags, rotation config, and failure counters as one object.

### Interface

```moonbit
pub fn ConfiguredLogger::file_state(self : ConfiguredLogger) -> FileSinkState {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file state snapshot should be inspected.

#### output

- `FileSinkState` - Current file sink snapshot.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return a live snapshot of file state.
- Queued file sinks forward the snapshot from the wrapped inner file sink.
- Non-file sinks return the same fallback empty-style state produced by `RuntimeSink::file_state()`, with an empty path, disabled policy flags, no rotation, and zeroed counters.
- This helper is broader than individual file counters or policy accessors because it aggregates core file status into one read.

### How to Use

Here are some specific examples provided.

#### When Need A Full File Health Snapshot

When diagnostics should inspect runtime file state as one object:
```moonbit
let state = logger.file_state()
```

In this example, callers receive a single file-state snapshot instead of querying each property separately.

#### When Need To Export File Runtime Diagnostics

When a support path should serialize current file state:
```moonbit
println(stringify_file_sink_state(logger.file_state(), pretty=true))
```

In this example, the configured logger snapshot can be exported directly through existing JSON helpers.

### Error Case

e.g.:
- If the configured sink is not file-backed, the returned snapshot is a fallback empty-style state rather than a live file view.

- If callers also need queue context for queued file sinks, `file_runtime_state()` is the richer API.

### Notes

1. Use this helper for the main one-shot file status snapshot.

2. Prefer it over individual counters when broader file diagnostics are needed.
