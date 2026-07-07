---
name: runtime-sink-file-reset-policy
group: api
category: runtime
update-time: 20260707
description: Reset the runtime file policy of a RuntimeSink back to its captured defaults.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-reset-policy

Reset the runtime file policy of a `RuntimeSink` back to its captured defaults.

### Interface

```moonbit
pub fn RuntimeSink::file_reset_policy(self : RuntimeSink) -> Bool {
```

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants restore the wrapped `FileSink` default policy and return `true`.
- `QueuedFile` runtime variants restore the wrapped inner `FileSink` default policy only when no queued records are pending.
- Non-file runtime variants return `false`.
- If a queued file sink still has pending records, the reset is rejected and returns `false` so already queued records are not later written under a different policy than the one they were queued under.

### Notes

1. Use this helper when runtime file policy should return to its captured defaults.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
