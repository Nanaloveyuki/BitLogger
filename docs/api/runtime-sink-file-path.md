---
name: runtime-sink-file-path
group: api
category: runtime
update-time: 20260613
description: Read the effective file path used by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-path

Read the effective file path used by a file-backed `RuntimeSink`. This helper is useful for diagnostics, support output, and confirming which direct runtime file sink is active.

### Interface

```moonbit
pub fn RuntimeSink::file_path(self : RuntimeSink) -> String {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file path should be inspected.

#### output

- `String` - Effective runtime file path, or an empty string for non-file sinks.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return their current file path.
- `QueuedFile` runtime variants forward the wrapped inner file sink path.
- Non-file runtime variants return an empty string.
- This helper is observation-only and does not modify file state.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Path Diagnostics

When code owns a `RuntimeSink` and should show which file is active:
```moonbit
println(sink.file_path())
```

In this example, operators can verify the effective destination path directly from the runtime sink.

#### When Build Support Output From A Runtime Sink

When application state dumps should include file destination info:
```moonbit
let path = sink.file_path()
```

In this example, the path can be surfaced without reading broader runtime state.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns an empty string.

- If callers need richer file status than just the path, `file_state()` or `file_runtime_state()` is the better API.

### Notes

1. Use this helper for direct runtime path visibility on `RuntimeSink` values.

2. Empty string usually means the runtime sink is not file-backed.
