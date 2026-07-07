---
name: runtime-sink-drain-progress
group: api
category: runtime
update-time: 20260707
description: Return a structured generic drain progress snapshot for a RuntimeSink without collapsing queue and plain-file fallback semantics into one Int.
key-word:
    - runtime
    - sink
    - drain
    - public
---

## Runtime-sink-drain-progress

Return a structured generic drain progress snapshot for a `RuntimeSink`. This is the recommended truthful generic runtime drain helper when callers need bounded or full queue progress without relying on the compatibility `Int` returned by `drain()`.

### Interface

```moonbit
pub fn RuntimeSink::drain_progress(
  self : RuntimeSink,
  max_items~ : Int = -1,
) -> RuntimeSinkProgress {
```

#### input

- `self : RuntimeSink` - Runtime sink whose generic drain progress should be observed.
- `max_items : Int` - Optional upper bound on drained queued items. Negative values mean no explicit bound.

#### output

- `RuntimeSinkProgress` - Structured progress snapshot separating queue advancement from plain-file flush fallback steps.

### Explanation

Detailed rules explaining key parameters and behaviors

- Queue-wrapped runtime sinks report consumed queued items through `queue_advanced_count` and honor `max_items`.
- Plain file runtime sinks still follow the generic fallback path and report `FileSink::flush()` as `file_flush_step_count` `1` or `0`.
- Plain console-style runtime sinks return a zeroed snapshot because they do not own a drainable queue here.
- Queued file runtime sinks report queue advancement, while delayed file delivery failures still belong to file failure counters and `file_flush()`.
- This helper preserves the old runtime behavior but makes the meaning explicit in the result shape.
- `drain()` remains available as the legacy convenience wrapper that sums the fields back into one count.

### How to Use

Here are some specific examples provided.

#### When Need Recommended Bounded Generic Drain Progress

When code should observe one bounded drain step without mixing units:
```moonbit
let progress = sink.drain_progress(max_items=16)
```

In this example, queue progress and plain-file fallback stay separated.

#### When Need A Full Manual Generic Drain Snapshot

When support code should empty queued work and keep runtime-shape context:
```moonbit
let progress = sink.drain_progress()
```

In this example, the caller can inspect both the count and the runtime shape afterwards.

### Error Case

e.g.:
- If the runtime sink is not queue-backed, the snapshot may stay zeroed or use the plain-file fallback field.

- If callers want file-specific success semantics after queue delivery, `file_flush()` is the better API.

### Notes

1. Prefer `drain_progress()` over `drain()` in new generic runtime code.

2. Use `pending_count()` together with this helper when remaining backlog must also be observed.
