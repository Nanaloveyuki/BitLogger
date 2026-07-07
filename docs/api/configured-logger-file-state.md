---
name: configured-logger-file-state
group: api
category: runtime
update-time: 20260707
description: Read the current file sink snapshot from a configured runtime logger, with a compatibility fallback for non-file sinks.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-state

Read the current file sink snapshot from a `ConfiguredLogger`. This helper exposes path, availability, policy flags, rotation config, and failure counters as one object.

The returned `FileSinkState` value is owned by `src/file_model`; this configured-logger surface is a facade over `Logger[@runtime.RuntimeSink]` and delegates file-state reads to the wrapped `RuntimeSink`.

`file_state()` is the compatibility form. For truthful file-semantics detection, prefer `file_state_or_none()`.

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
- The returned snapshot object itself is the shared `@file_model.FileSinkState` model, not a configured-logger-owned concrete type.
- Non-file sinks return the same fallback empty-style state produced by `RuntimeSink::file_state()`, with an empty path, disabled policy flags, no rotation, and zeroed counters.
- This fallback keeps older callers source-compatible, but it is not a live file-backed snapshot.
- New diagnostic or recovery code should prefer `file_state_or_none()`.
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

- If callers need a truthful file-semantics check, use `file_state_or_none()`.

- If callers also need queue context for queued file sinks, `file_runtime_state()` is the richer API.

### Notes

1. Use this helper for the main one-shot file status snapshot.

2. Prefer `file_state_or_none()` or `file_runtime_state()` when broader truthful diagnostics are needed.
