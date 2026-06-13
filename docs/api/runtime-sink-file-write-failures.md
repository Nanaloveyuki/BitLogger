---
name: runtime-sink-file-write-failures
group: api
category: runtime
update-time: 20260613
description: Read the number of write failures recorded by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-write-failures

Read the number of write failures recorded by a file-backed `RuntimeSink`. This helper is useful for direct runtime diagnostics around the file write path.

### Interface

```moonbit
pub fn RuntimeSink::file_write_failures(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose write-failure counter should be inspected.

#### output

- `Int` - Number of recorded write failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report the wrapped `FileSink` write-failure count.
- `QueuedFile` runtime variants forward the metric from the wrapped inner `FileSink`.
- For `QueuedFile`, enqueueing a record does not increment this counter by itself. The counter changes only when queued records are actually drained into the inner file sink, such as through `file_flush()`.
- Non-file runtime variants return `0`.
- The counter is cumulative until `file_reset_failure_counters()` clears it.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Write-path Diagnostics

When support output should show whether file writes have been failing:
```moonbit
let count = sink.file_write_failures()
```

In this example, callers get a focused signal for direct runtime file write-path health.

#### When Compare Sink Health After Recovery

When recovery logic should verify whether new failures still occur:
```moonbit
ignore(sink.file_write_failures())
```

In this example, the metric helps measure whether runtime writes improved after intervention.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `0`.

- If callers need a fuller view of file health, `file_state()` or `file_runtime_state()` may be better APIs.

### Notes

1. Use this helper for focused direct runtime write-failure visibility.

2. Pair it with `file_flush()` and `file_flush_failures()` when diagnosing queued output-path instability.
