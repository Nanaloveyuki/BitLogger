---
name: configured-logger-file-set-rotation
group: api
category: runtime
update-time: 20260707
description: Update the rotation policy used by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-set-rotation

Update the rotation policy used by a `ConfiguredLogger` file sink.

### Interface

```moonbit
pub fn ConfiguredLogger::file_set_rotation(self : ConfiguredLogger, rotation : FileRotation?) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file rotation policy should change.
- `rotation : FileRotation?` - New runtime rotation policy.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks update their runtime rotation policy through the wrapped `RuntimeSink`.
- Queued file sinks forward the update to the wrapped inner file sink only when no queued records are pending.
- Non-file sinks return `false`.
- This helper changes policy only; it does not itself rotate or flush pending data.
- If a queued file sink still has pending records, the update is rejected and returns `false` so already queued records are not later written under a different rotation policy than the one they were queued under.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If a queued file sink still has pending records, callers should flush or close it first before changing rotation policy.

### Notes

1. Use this helper when runtime rotation policy should change without rebuilding the logger.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
