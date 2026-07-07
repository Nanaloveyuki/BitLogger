---
name: configured-logger-file-reset-policy
group: api
category: runtime
update-time: 20260707
description: Reset the runtime file policy of a configured logger back to its captured defaults.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-reset-policy

Reset the runtime file policy of a `ConfiguredLogger` back to its captured defaults.

### Interface

```moonbit
pub fn ConfiguredLogger::file_reset_policy(self : ConfiguredLogger) -> Bool {}
```

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks restore their runtime default policy through the wrapped `RuntimeSink`.
- Queued file sinks restore the wrapped inner file sink default policy only when no queued records are pending.
- Non-file sinks return `false`.
- If a queued file sink still has pending records, the reset is rejected and returns `false` so already queued records are not later written under a different policy than the one they were queued under.

### Notes

1. Use this helper when runtime file policy should return to its captured defaults.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
