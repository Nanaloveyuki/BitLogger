---
name: file-sink-reset-failure-counters
group: api
category: sink
update-time: 20260613
description: Reset the file failure counters recorded by a FileSink.
key-word:
    - file
    - sink
    - reset
    - public
---

## File-sink-reset-failure-counters

Reset the file failure counters recorded by a `FileSink`. This helper clears open, write, flush, and rotation failure metrics together on the direct sink.

### Interface

```moonbit
pub fn FileSink::reset_failure_counters(self : FileSink) -> Unit {
```

#### input

- `self : FileSink` - File sink whose file failure counters should be cleared.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper clears open, write, flush, and rotation failure counters together.
- It is useful after diagnostics, recovery, or controlled tests.
- It does not reopen the sink or change file policy.

### How to Use

Here are some specific examples provided.

#### When Need A Fresh Diagnostics Baseline

When previous failure history should be cleared before a new observation window:
```moonbit
sink.reset_failure_counters()
```

In this example, future failures can be measured from a clean baseline.

#### When Validate Post-recovery Behavior

When recovery logic should clear old counters before rechecking health:
```moonbit
sink.reset_failure_counters()
ignore(sink.open_failures())
```

In this example, the direct sink starts a new diagnostics window after reset.

### Error Case

e.g.:
- If callers need the current values before clearing them, they should read the counters or `state()` first.

- This helper resets metrics only; it does not fix the underlying cause of past failures.

### Notes

1. Use this helper after diagnostics or recovery, not before capturing needed evidence.

2. It is the reset companion for the direct file failure-counter helpers.
