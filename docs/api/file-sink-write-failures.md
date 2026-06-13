---
name: file-sink-write-failures
group: api
category: sink
update-time: 20260613
description: Read the number of write failures recorded by a FileSink.
key-word:
    - file
    - sink
    - write
    - public
---

## File-sink-write-failures

Read the number of write failures recorded by a `FileSink`. This helper is useful for diagnosing direct runtime write-path problems.

### Interface

```moonbit
pub fn FileSink::write_failures(self : FileSink) -> Int {
```

#### input

- `self : FileSink` - File sink whose write-failure counter should be inspected.

#### output

- `Int` - Number of recorded write failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- The sink reports its recorded write-failure count directly.
- The counter is cumulative until reset.
- This helper is observation-only and does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Write-path Diagnostics

When support output should show whether direct writes have been failing:
```moonbit
let count = sink.write_failures()
```

In this example, callers get a focused signal for direct file write-path health.

#### When Compare Sink Health After Recovery

When recovery logic should verify whether new failures still occur:
```moonbit
ignore(sink.write_failures())
```

In this example, the metric helps measure whether runtime writes improved after intervention.

### Error Case

e.g.:
- If callers need a fuller view of file health, `state()` may be a better API.

- This counter does not itself distinguish open-path issues from write-path issues.

### Notes

1. Use this helper for focused write-failure visibility.

2. Pair it with `flush_failures()` when diagnosing direct output-path instability.
