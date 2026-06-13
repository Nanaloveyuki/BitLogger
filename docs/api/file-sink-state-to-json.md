---
name: file-sink-state-to-json
group: api
category: runtime
update-time: 20260512
description: Convert FileSinkState into a JSON value for file sink diagnostics and state transport.
key-word:
    - file
    - state
    - json
    - public
---

## File-sink-state-to-json

Convert `FileSinkState` into a `JsonValue`. This helper exports file path, availability, policy flags, rotation config, and failure counters in a structured form.

### Interface

```moonbit
pub fn file_sink_state_to_json(state : FileSinkState) -> @json_parser.JsonValue {}
```

#### input

- `state : FileSinkState` - File sink state snapshot to export.

#### output

- `JsonValue` - Structured JSON representation of the file sink state.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `path`, `available`, `append`, `auto_flush`, failure counters, and `rotation`.
- `rotation` is exported as `null` when rotation is disabled.
- This helper exports state snapshots, not mutable runtime control handles.
- It is useful when file sink state should be embedded into larger diagnostics payloads.
- Typical inputs come from `FileSink::state()`, `RuntimeSink::file_state()`, or `ConfiguredLogger::file_state()`.

### How to Use

Here are some specific examples provided.

#### When Need Structured File Diagnostics

When file runtime status should be composed into a larger JSON object:
```moonbit
let value = file_sink_state_to_json(runtime.file_state())
```

In this example, callers receive a structured file-state snapshot instead of plain text.

#### When Need Runtime State Snapshots For Tooling

When support tooling should ingest file sink state programmatically:
```moonbit
let snapshot = file_sink_state_to_json(runtime.file_state())
```

In this example, the helper exposes all major live file-state fields in machine-readable form.

### Error Case

e.g.:
- If the file is unavailable, the exported snapshot still serializes normally with `available=false`.

- If callers need direct text output, `stringify_file_sink_state(...)` is the better API.

### Notes

1. Use this helper when diagnostics consumers expect `JsonValue`.

2. It pairs naturally with `FileSink::state()`, `RuntimeSink::file_state()`, and `ConfiguredLogger::file_state()`.
