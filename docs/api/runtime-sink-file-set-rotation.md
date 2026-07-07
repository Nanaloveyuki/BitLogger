---
name: runtime-sink-file-set-rotation
group: api
category: runtime
update-time: 20260707
description: Update the rotation policy used by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-set-rotation

Update the rotation policy used by a file-backed `RuntimeSink`.

### Interface

```moonbit
pub fn RuntimeSink::file_set_rotation(self : RuntimeSink, rotation : FileRotation?) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file rotation policy should change.
- `rotation : FileRotation?` - New runtime rotation policy.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants update the wrapped `FileSink` rotation policy and return `true`.
- `QueuedFile` runtime variants forward the update to the wrapped inner `FileSink` only when no queued records are pending.
- Non-file runtime variants return `false`.
- This helper changes policy only; it does not itself rotate or flush pending data.
- If a queued file sink still has pending records, the update is rejected and returns `false` so already queued records are not later written under a different rotation policy than the one they were queued under.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If a queued file sink still has pending records, callers should flush or close it first before changing rotation policy.

### Notes

1. Use this helper when runtime rotation policy should change without rebuilding the sink.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
