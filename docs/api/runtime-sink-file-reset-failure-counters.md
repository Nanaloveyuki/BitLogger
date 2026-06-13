---
name: runtime-sink-file-reset-failure-counters
group: api
category: runtime
update-time: 20260613
description: Reset the file failure counters recorded by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-reset-failure-counters

Reset the file failure counters recorded by a file-backed `RuntimeSink`. This helper clears open, write, flush, and rotation failure metrics together.

### Interface

```moonbit
pub fn RuntimeSink::file_reset_failure_counters(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file failure counters should be cleared.

#### output

- `Bool` - Whether the reset was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants clear all file failure counters together and return `true`.
- `QueuedFile` runtime variants forward the reset behavior to the wrapped inner `FileSink` and return `true`.
- Non-file runtime variants return `false`.
- This helper is useful after diagnostics, recovery, or controlled tests.

### How to Use

Here are some specific examples provided.

#### When Need A Fresh Diagnostics Baseline

When previous failure history should be cleared before a new observation window:
```moonbit
ignore(sink.file_reset_failure_counters())
```

In this example, future failures can be measured from a clean baseline.

#### When Validate Post-recovery Behavior

When recovery logic should clear old counters before rechecking health:
```moonbit
ignore(sink.file_reset_failure_counters())
ignore(sink.file_open_failures())
```

In this example, the runtime sink starts a new diagnostics window after reset.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need the current values before clearing them, they should read the counters or `file_state()` first.

### Notes

1. Use this helper after diagnostics or recovery, not before capturing needed evidence.

2. It is the reset companion for the direct runtime file failure-counter helpers.
