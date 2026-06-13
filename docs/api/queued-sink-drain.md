---
name: queued-sink-drain
group: api
category: sink
update-time: 20260613
description: Drain queued records from a QueuedSink with an optional item limit.
key-word:
    - sink
    - queue
    - drain
    - public
---

## Queued-sink-drain

Drain queued records from a `QueuedSink[S]`. This is the direct sink-level queue delivery API when code owns a queued sink and wants controlled progress into the wrapped sink.

### Interface

```moonbit
pub fn[S : Sink] QueuedSink::drain(self : QueuedSink[S], max_items~ : Int = -1) -> Int {
```

#### input

- `self : QueuedSink[S]` - Queued sink whose pending records should be drained to the wrapped sink.
- `max_items : Int` - Optional upper bound on drained queued records. Negative values mean no explicit bound.

#### output

- `Int` - Number of drained records.

### Explanation

Detailed rules explaining key parameters and behaviors

- `max_items == 0` returns `0` immediately.
- Negative `max_items` means drain up to the current `pending_count()`.
- The method repeatedly pops from the queue and writes each record to the wrapped sink in order until the limit is reached or the queue becomes empty.
- The return value is the number of records actually drained.

### How to Use

Here are some specific examples provided.

#### When Need Bounded Queue Progress

When queued work should be advanced in chunks:
```moonbit
let drained = sink.drain(max_items=16)
```

In this example, callers cap how much queue backlog is forwarded in one step.

#### When Need Full Manual Drain

When a queued sink should be emptied explicitly:
```moonbit
ignore(sink.drain())
```

In this example, the queue is drained without an explicit item cap.

### Error Case

e.g.:
- If the queue is already empty, the method returns `0`.

- If callers only need the shorthand that drains the whole queue, `flush()` is the simpler API.

### Notes

1. Prefer this helper when queue progress should be bounded or directly observed.

2. Pair it with `pending_count()` to inspect remaining backlog after a drain step.
