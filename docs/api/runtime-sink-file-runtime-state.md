---
name: runtime-sink-file-runtime-state
group: api
category: runtime
update-time: 20260613
description: Read combined file and queue runtime state from a RuntimeSink when it is backed by a file sink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-runtime-state

Read combined file and queue runtime state from a `RuntimeSink`. This helper is the richest file-specific diagnostics API on direct runtime sink values.

### Interface

```moonbit
pub fn RuntimeSink::file_runtime_state(self : RuntimeSink) -> RuntimeFileState? {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file runtime state should be inspected.

#### output

- `RuntimeFileState?` - Combined file and queue diagnostics when the runtime sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return `Some(RuntimeFileState::new(sink.state()))`, so queue metadata stays at its default non-queued shape.
- `QueuedFile` runtime variants return `Some(RuntimeFileState)` with the wrapped file state plus `queued=true`, `pending_count=sink.pending_count()`, and `dropped_count=sink.dropped_count()`.
- Non-file runtime variants return `None`.
- This helper is richer than `file_state()` because it can also surface queued backlog and dropped counts.

### How to Use

Here are some specific examples provided.

#### When Need Rich File Runtime Diagnostics

When support output should include both file and queue state:
```moonbit
let state = sink.file_runtime_state()
```

In this example, callers can inspect availability, failure counters, and queue metrics together.

#### When Need To Branch On File-backed Runtime Shape

When code should behave differently for file-backed direct sinks:
```moonbit
match sink.file_runtime_state() {
  Some(state) => ignore(state)
  None => ()
}
```

In this example, the optional return value reflects whether the runtime sink is file-backed.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `None`.

- If callers only need raw file status without queue context, `file_state()` may be the simpler API.

### Notes

1. Use this helper for the richest file-backed runtime diagnostics on direct sink values.

2. It is especially useful for queued file sinks where file health and queue state both matter.
