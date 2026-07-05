---
name: runtime-file-state-to-json
group: api
category: runtime
update-time: 20260512
description: Convert RuntimeFileState into a JSON value that combines file status with outer queue runtime metrics.
key-word:
    - runtime
    - file
    - state
    - public
---

## Runtime-file-state-to-json

Convert `RuntimeFileState` into a `JsonValue`. This helper exports both file sink status and queue metrics for combined runtime file diagnostics.

### Interface

```moonbit
pub fn runtime_file_state_to_json(state : RuntimeFileState) -> @json_parser.JsonValue {}
```

#### input

- `state : RuntimeFileState` - Combined file and queue runtime snapshot.

#### output

- `JsonValue` - Structured JSON representation of the runtime file state.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `file`, `queued`, `pending_count`, and `dropped_count`.
- `file` is itself exported as a nested file sink state object.
- This helper is richer than `file_sink_state_to_json(...)` because it also carries queue wrapping context.
- It is useful for `RuntimeSink::file_runtime_state()`, `ConfiguredLogger::file_runtime_state()`, and similar queued-file diagnostics flows.
- Any `file_rotation_i64(...)` policy nested under `file` includes both the compatibility `max_bytes` number and `max_bytes_i64` as a string.

### How to Use

Here are some specific examples provided.

#### When Need Structured Queued-file Diagnostics

When file and queue status should be exported together:
```moonbit
let value = runtime_file_state_to_json(snapshot)
```

In this example, callers receive a machine-readable combined runtime snapshot.

#### When Need Support Payload Composition

When queued file runtime data should be embedded into a larger JSON object:
```moonbit
match runtime.file_runtime_state() {
  Some(snapshot) => {
    let payload = runtime_file_state_to_json(snapshot)
    ignore(payload)
  }
  None => ()
}
```

In this example, the helper keeps file-plus-queue diagnostics in one reusable JSON value after the optional runtime snapshot is read.

### Error Case

e.g.:
- If `queued=false`, the state still serializes normally with queue counters present.

- If callers need direct text output, `stringify_runtime_file_state(...)` is the better API.

### Notes

1. Use this helper when file and queue runtime context should stay together.

2. It is especially useful for queued file runtime paths, whether accessed directly or through configured loggers.

3. For wide native rotation policies nested under `file.rotation`, use `max_bytes_i64` when exact threshold recovery matters.
