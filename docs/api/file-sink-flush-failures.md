---
name: file-sink-flush-failures
group: api
category: sink
update-time: 20260613
description: Read the number of flush failures recorded by a FileSink.
key-word:
    - file
    - sink
    - flush
    - public
---

## File-sink-flush-failures

Read the number of flush failures recorded by a `FileSink`. This helper is useful for diagnosing durability-path problems on the direct file sink.

### Interface

```moonbit
pub fn FileSink::flush_failures(self : FileSink) -> Int {
```

#### input

- `self : FileSink` - File sink whose flush-failure counter should be inspected.

#### output

- `Int` - Number of recorded flush failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- The sink reports its recorded flush-failure count directly.
- The counter is cumulative until reset.
- This helper is observation-only and does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Durability-path Diagnostics

When support output should show direct flush-path instability:
```moonbit
let count = sink.flush_failures()
```

In this example, the direct file sink exposes whether flush attempts have been failing.

#### When Inspect Effects Of Auto-flush Policy

When runtime durability tuning should be inspected operationally:
```moonbit
ignore(sink.flush_failures())
```

In this example, callers can correlate flush failures with direct file policy choices.

### Error Case

e.g.:
- If callers need current policy and counters together, `state()` is the better API.

- This counter does not itself say whether the sink is open right now.

### Notes

1. Use this helper when direct flush-path reliability matters.

2. Pair it with `auto_flush_enabled()` and `flush()` when diagnosing durability behavior.
