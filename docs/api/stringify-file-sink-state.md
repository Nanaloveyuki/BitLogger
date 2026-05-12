---
name: stringify-file-sink-state
group: api
category: runtime
update-time: 20260512
description: Serialize FileSinkState into compact or pretty JSON text for diagnostics and support output.
key-word:
    - file
    - state
    - stringify
    - public
---

## Stringify-file-sink-state

Serialize `FileSinkState` into JSON text. This helper is the most direct export path for file sink diagnostics snapshots.

### Interface

```moonbit
pub fn stringify_file_sink_state(state : FileSinkState, pretty~ : Bool = false) -> String {}
```

#### input

- `state : FileSinkState` - File sink state snapshot to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the file sink state.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON for human diagnostics.
- This helper builds on top of `file_sink_state_to_json(...)`.
- The output is well-suited for support dumps, incident reports, and log snapshots.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable File Diagnostics

When file sink status should be printed for operators:
```moonbit
println(stringify_file_sink_state(sink.state(), pretty=true))
```

In this example, the full file-state snapshot is rendered in readable JSON.

#### When Need Compact State Export

When a snapshot should stay small:
```moonbit
let text = stringify_file_sink_state(sink.state())
```

In this example, compact JSON is returned without extra formatting logic.

### Error Case

e.g.:
- If the file is unavailable, the output still serializes normally with `available=false`.

- If callers need structured composition instead of text, `file_sink_state_to_json(...)` is the better API.

### Notes

1. Use this helper for direct textual file-state snapshots.

2. `pretty=true` is useful for operator-facing diagnostics and support output.
