---
name: runtime-sink-drain
group: api
category: runtime
update-time: 20260613
description: Drain queued work from a RuntimeSink with an optional item limit.
key-word:
    - runtime
    - sink
    - queue
    - public
---

## Runtime-sink-drain

Drain queued work from a `RuntimeSink`. This helper is useful when code owns a runtime sink directly and needs controlled queue progress.

### Interface

```moonbit
pub fn RuntimeSink::drain(self : RuntimeSink, max_items~ : Int = -1) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose queued work should be drained.
- `max_items : Int` - Optional upper bound on drained queued items. Negative values mean no explicit bound.

#### output

- `Int` - Number of drained items, or the fallback flush count for plain file sinks.

### Explanation

Detailed rules explaining key parameters and behaviors

- Queue-wrapped runtime sinks forward to the wrapped queue sink's `drain(...)` behavior.
- Plain file runtime sinks fall back to `FileSink::flush()` behavior and return `1` or `0`.
- Plain console-style runtime sinks return `0` because they do not own a drainable queue.
- This method is the direct sink-level API used by `ConfiguredLogger::drain(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Bounded Queue Progress

When direct queue-backed runtime work should be advanced in chunks:
```moonbit
let drained = sink.drain(max_items=16)
```

In this example, callers cap how much queued work is processed in one step.

#### When Need Full Manual Drain

When a runtime queue should be emptied without an explicit item cap:
```moonbit
ignore(sink.drain())
```

In this example, the runtime sink drains as much queued work as its concrete variant allows.

### Error Case

e.g.:
- If the runtime sink is not queue-backed, the result may be `0` or file-flush fallback behavior.

- If callers only need generic flush semantics, `flush()` may be the simpler API.

### Notes

1. Prefer this helper when queue progress should be bounded or directly observed.

2. `ConfiguredLogger::drain(...)` is the higher-level wrapper for config-built loggers.
