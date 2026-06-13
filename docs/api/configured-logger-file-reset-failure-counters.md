---
name: configured-logger-file-reset-failure-counters
group: api
category: runtime
update-time: 20260512
description: Reset the file failure counters recorded by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-reset-failure-counters

Reset the file failure counters recorded by a `ConfiguredLogger`. This helper clears open, write, flush, and rotation failure metrics together.

### Interface

```moonbit
pub fn ConfiguredLogger::file_reset_failure_counters(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file failure counters should be cleared.

#### output

- `Bool` - Whether the reset was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks clear all file failure counters together.
- Queued file sinks forward the reset behavior to the wrapped file sink.
- Non-file sinks return `false`.
- This helper is useful after diagnostics, recovery, or controlled tests.

### How to Use

Here are some specific examples provided.

#### When Need A Fresh Diagnostics Baseline

When previous failure history should be cleared before a new observation window:
```moonbit
ignore(logger.file_reset_failure_counters())
```

In this example, future failures can be measured from a clean baseline.

#### When Validate Post-recovery Behavior

When recovery logic should clear old counters before rechecking health:
```moonbit
ignore(logger.file_reset_failure_counters())
ignore(logger.file_open_failures())
```

In this example, the configured logger starts a new diagnostics window after reset.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need the current values before clearing them, they should read the counters or `file_state()` first.

### Notes

1. Use this helper after diagnostics or recovery, not before capturing needed evidence.

2. For queued file sinks, it resets the inner file counters only; it does not clear still-pending queued records that may produce new failures on a later `file_flush()`.
