---
name: runtime-sink-file-state
group: api
category: runtime
update-time: 20260613
description: Read the current file sink snapshot from a RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-state

Read the current file sink snapshot from a `RuntimeSink`. This helper exposes path, availability, policy flags, rotation config, and failure counters as one object.

### Interface

```moonbit
pub fn RuntimeSink::file_state(self : RuntimeSink) -> FileSinkState {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file state snapshot should be inspected.

#### output

- `FileSinkState` - Current file sink snapshot.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return a live snapshot from the wrapped `FileSink`.
- `QueuedFile` runtime variants forward the snapshot from the wrapped inner `FileSink`.
- Non-file runtime variants return a fallback empty-style state with `path=""`, `available=false`, `append=false`, `auto_flush=false`, `rotation=None`, and all failure counters set to `0`.
- This helper is broader than individual file counters or policy accessors because it aggregates core file status into one read.

### How to Use

Here are some specific examples provided.

#### When Need A Full File Health Snapshot

When diagnostics should inspect direct runtime file state as one object:
```moonbit
let state = sink.file_state()
```

In this example, callers receive a single file-state snapshot instead of querying each property separately.

#### When Need To Export File Runtime Diagnostics

When a support path should serialize current file state:
```moonbit
println(stringify_file_sink_state(sink.file_state(), pretty=true))
```

In this example, the runtime sink snapshot can be exported directly through existing JSON helpers.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the returned snapshot is a fallback empty-style state rather than a live file view.

- If callers also need queue context for queued file sinks, `file_runtime_state()` is the richer API.

### Notes

1. Use this helper for the main one-shot file status snapshot.

2. Prefer it over individual counters when broader file diagnostics are needed.
