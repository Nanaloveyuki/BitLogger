---
name: runtime-sink-file-clear-rotation
group: api
category: runtime
update-time: 20260707
description: Clear the rotation policy used by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-clear-rotation

Clear the rotation policy used by a file-backed `RuntimeSink`.

### Interface

```moonbit
pub fn RuntimeSink::file_clear_rotation(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file rotation policy should be cleared.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants clear the wrapped `FileSink` rotation policy and return `true`.
- `QueuedFile` runtime variants clear the wrapped inner `FileSink` rotation policy only when no queued records are pending.
- Non-file runtime variants return `false`.
- If a queued file sink still has pending records, the update is rejected and returns `false` so already queued records are not later written under a different rotation policy than the one they were queued under.

### Notes

1. Use this helper when runtime rotation policy should be removed without rebuilding the sink.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
