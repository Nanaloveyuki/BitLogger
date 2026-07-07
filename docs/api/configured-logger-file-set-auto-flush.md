---
name: configured-logger-file-set-auto-flush
group: api
category: runtime
update-time: 20260707
description: Update the auto-flush policy used by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-set-auto-flush

Update the auto-flush policy used by a `ConfiguredLogger` file sink. This helper changes runtime durability behavior without rebuilding the logger.

### Interface

```moonbit
pub fn ConfiguredLogger::file_set_auto_flush(self : ConfiguredLogger, enabled : Bool) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose auto-flush policy should change.
- `enabled : Bool` - New auto-flush setting.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks update their runtime auto-flush policy through the wrapped `RuntimeSink`.
- Queued file sinks forward the update to the wrapped inner file sink only when no queued records are pending.
- Non-file sinks return `false`.
- This helper changes policy only; it does not itself flush pending data.
- If a queued file sink still has pending records, the update is rejected and returns `false` so already queued records are not later written under a different auto-flush policy than the one they were queued under.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Durability Tuning

When a file sink should start flushing each write automatically:
```moonbit
ignore(logger.file_set_auto_flush(true))
```

In this example, runtime policy is updated without rebuilding the configured logger.

#### When Need To Relax Flush Pressure

When a file sink should stop auto-flushing for throughput reasons:
```moonbit
let ok = logger.file_set_auto_flush(false)
```

In this example, the call site updates policy explicitly and can inspect the result.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need an immediate flush action, `file_flush()` is the operational API.

- If a queued file sink still has pending records, callers should flush or close it first before changing auto-flush policy.

### Notes

1. Use this helper for runtime durability tuning.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
