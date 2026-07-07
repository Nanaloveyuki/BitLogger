---
name: runtime-sink-drain
group: api
category: runtime
update-time: 20260707
description: Compatibility RuntimeSink drain helper that still returns one Int by collapsing generic queue progress and plain-file fallback steps.
key-word:
    - runtime
    - sink
    - queue
    - public
---

## Runtime-sink-drain

Drain queued work from a `RuntimeSink` and return one compatibility count. This helper is still available for older code, but new generic runtime code should prefer `drain_progress()` because it exposes queue advancement and plain-file fallback steps separately.

### Interface

```moonbit
pub fn RuntimeSink::drain(self : RuntimeSink, max_items~ : Int = -1) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose queued work should be drained.
- `max_items : Int` - Optional upper bound on drained queued items. Negative values mean no explicit bound.

#### output

- `Int` - Compatibility count produced from the structured `drain_progress()` result.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method now delegates to `drain_progress()` and sums `queue_advanced_count + file_flush_step_count` back into one compatibility number.
- Queue-wrapped runtime sinks still report how many queued records were consumed during the drain.
- A queued file drain can still return a positive number even when file failure counters increase during the same queue-delivery step.
- Plain file runtime sinks still use the generic `FileSink::flush()` fallback and therefore still return `1` or `0`.
- Plain console-style runtime sinks still return `0` because the structured result stays zeroed.
- This method remains the direct sink-level API used by `ConfiguredLogger::drain(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Bounded Queue Progress

When older code already expects one numeric drain count:
```moonbit
let drained = sink.drain(max_items=16)
```

In this example, callers still cap how much queued work is processed in one step while keeping the legacy return shape.

#### When Need Full Manual Drain

When code should keep the older full-drain compatibility path:
```moonbit
ignore(sink.drain())
```

In this example, the runtime sink drains as much queued work as its concrete variant allows while still returning one numeric count.

### Error Case

e.g.:
- If the runtime sink is not queue-backed, the result may be `0` or file-flush fallback behavior.

- If callers need truthful generic progress semantics, `drain_progress()` is the better API.

- If callers only need generic flush semantics, `flush_progress()` may be the simpler structured API.

- If callers need file-specific success semantics after draining a queued file sink, they should inspect failure counters or use `file_flush()` for the file-specific path.

### Notes

1. Treat this method as a compatibility helper for older numeric code.

2. Prefer `drain_progress()` in new generic runtime code.

3. `ConfiguredLogger::drain(...)` is the higher-level wrapper for config-built loggers.
