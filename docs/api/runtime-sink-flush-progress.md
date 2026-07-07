---
name: runtime-sink-flush-progress
group: api
category: runtime
update-time: 20260707
description: Return a structured generic flush progress snapshot for a RuntimeSink without collapsing queue and plain-file fallback semantics into one Int.
key-word:
    - runtime
    - sink
    - flush
    - public
---

## Runtime-sink-flush-progress

Return a structured generic flush progress snapshot for a `RuntimeSink`. This is the recommended truthful generic runtime flush helper when callers need to observe progress without relying on the compatibility `Int` returned by `flush()`.

### Interface

```moonbit
pub fn RuntimeSink::flush_progress(self : RuntimeSink) -> RuntimeSinkProgress {
```

#### input

- `self : RuntimeSink` - Runtime sink whose generic flush progress should be observed.

#### output

- `RuntimeSinkProgress` - Structured progress snapshot separating queue advancement from plain-file flush fallback steps.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain console-style runtime sinks return a zeroed snapshot with `queue_backed=false` and `file_backed=false`.
- Plain file runtime sinks call `FileSink::flush()` and report the fallback result through `file_flush_step_count` as `1` or `0`.
- Queue-wrapped runtime sinks report consumed queued items through `queue_advanced_count`.
- Queued file runtime sinks still report generic progress as queue advancement, while `file_backed=true` marks that the queue drains into a file sink.
- This helper does not convert different runtime-shape behaviors into one ambiguous compatibility `Int`.
- `flush()` remains available as the legacy convenience wrapper that sums the fields back into one count.

### How to Use

Here are some specific examples provided.

#### When Need Recommended Generic Flush Progress

When direct runtime code should inspect flush progress explicitly:
```moonbit
let progress = sink.flush_progress()
```

In this example, the caller gets a structured snapshot instead of a mixed `Int`.

#### When Need Queue-aware Branching During Flush

When generic runtime support code should react differently for queue-backed and plain-file sinks:
```moonbit
let progress = sink.flush_progress()
if progress.queue_backed {
  println(progress.queue_advanced_count)
}
```

In this example, queue advancement is explicit and does not need to be inferred from runtime shape.

### Error Case

e.g.:
- If the runtime sink shape has no flushable state, the snapshot simply reports zero counts.

- If callers need file-specific success semantics rather than generic runtime progress, `file_flush()` is the better API.

### Notes

1. Prefer `flush_progress()` over `flush()` in new generic runtime code.

2. Use `flush()` only when older compatibility code still expects one numeric count.
