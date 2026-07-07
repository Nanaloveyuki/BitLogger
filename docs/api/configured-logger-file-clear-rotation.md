---
name: configured-logger-file-clear-rotation
group: api
category: runtime
update-time: 20260707
description: Clear the rotation policy used by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-clear-rotation

Clear the rotation policy used by a `ConfiguredLogger` file sink.

### Interface

```moonbit
pub fn ConfiguredLogger::file_clear_rotation(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file rotation policy should be cleared.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks clear their runtime rotation policy through the wrapped `RuntimeSink`.
- Queued file sinks clear the wrapped inner file sink rotation policy only when no queued records are pending.
- Non-file sinks return `false`.
- If a queued file sink still has pending records, the update is rejected and returns `false` so already queued records are not later written under a different rotation policy than the one they were queued under.

### Notes

1. Use this helper when runtime rotation policy should be removed without rebuilding the logger.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
