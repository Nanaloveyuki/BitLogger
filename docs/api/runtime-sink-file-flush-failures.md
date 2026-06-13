---
name: runtime-sink-file-flush-failures
group: api
category: runtime
update-time: 20260613
description: Read the number of flush failures recorded by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-flush-failures

Read the number of flush failures recorded by a file-backed `RuntimeSink`. This helper is useful for direct runtime diagnostics around durability-path problems.

### Interface

```moonbit
pub fn RuntimeSink::file_flush_failures(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose flush-failure counter should be inspected.

#### output

- `Int` - Number of recorded flush failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report the wrapped `FileSink` flush-failure count.
- `QueuedFile` runtime variants forward the metric from the wrapped inner `FileSink`.
- Non-file runtime variants return `0`.
- The counter is cumulative until `file_reset_failure_counters()` clears it.

### How to Use

Here are some specific examples provided.

#### When Need Durability-path Diagnostics

When support output should show flush-path instability:
```moonbit
let count = sink.file_flush_failures()
```

In this example, the runtime sink exposes whether file flush attempts have been failing.

#### When Inspect Effects Of Auto-flush Policy

When runtime durability tuning should be inspected operationally:
```moonbit
ignore(sink.file_flush_failures())
```

In this example, callers can correlate flush failures with direct runtime file policy choices.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `0`.

- If callers need current policy and counters together, `file_state()` is the better API.

### Notes

1. Use this helper when direct runtime flush-path reliability matters.

2. Pair it with `file_auto_flush()` and `file_flush()` when diagnosing durability behavior.
