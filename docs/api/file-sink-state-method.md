---
name: file-sink-state-method
group: api
category: sink
update-time: 20260613
description: Read the current file sink snapshot from a FileSink.
key-word:
    - file
    - sink
    - state
    - public
---

## File-sink-state-method

Read the current file sink snapshot from a `FileSink`. This helper exposes path, availability, policy flags, rotation config, and failure counters as one object on the direct sink.

### Interface

```moonbit
pub fn FileSink::state(self : FileSink) -> FileSinkState {
```

#### input

- `self : FileSink` - File sink whose file state snapshot should be inspected.

#### output

- `FileSinkState` - Current file sink snapshot.

### Explanation

Detailed rules explaining key parameters and behaviors

- The snapshot includes path, availability, append policy, auto-flush policy, rotation config, and failure counters.
- `available` is derived from `is_available()`.
- This helper is broader than individual counters or policy accessors because it aggregates core file status into one read.
- It does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need A Full File Health Snapshot

When diagnostics should inspect direct file state as one object:
```moonbit
let state = sink.state()
```

In this example, callers receive a single file-state snapshot instead of querying each property separately.

#### When Need To Export File Diagnostics

When a support path should serialize current file state:
```moonbit
println(stringify_file_sink_state(sink.state(), pretty=true))
```

In this example, the direct sink snapshot can be exported through the existing JSON helpers.

### Error Case

e.g.:
- If callers only need one small part of direct file state, a narrower accessor may be simpler.

- This helper is a snapshot read, not an operational repair action.

### Notes

1. Use this helper for the main one-shot file status snapshot.

2. Prefer it over individual counters when broader direct file diagnostics are needed.
