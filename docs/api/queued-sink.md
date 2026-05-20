---
name: queued-sink
group: api
category: sink
update-time: 20260520
description: Create a sink that buffers records in an explicit queue with overflow policy control.
key-word:
    - sink
    - queue
    - overflow
    - public
---

## Queued-sink

Create a sink that stores records in an explicit synchronous queue before forwarding them to another sink. This is the low-level sink constructor behind queue-style sync buffering behavior.

### Interface

```moonbit
pub fn[S] queued_sink(
  sink : S,
  max_pending~ : Int = 0,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueuedSink[S] {
```

#### input

- `sink : S` - Wrapped sink receiving drained records.
- `max_pending : Int` - Queue capacity before overflow policy applies. `0` means unbounded.
- `overflow : QueueOverflowPolicy` - Overflow behavior such as `DropNewest` or `DropOldest`.

#### output

- `QueuedSink[S]` - Explicit queue sink with `pending_count()`, `dropped_count()`, `drain()`, and `flush()` helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- Records are enqueued first and only reach the wrapped sink when drained or flushed.
- `max_pending=0` means the queue is not bounded by capacity.
- Overflow behavior controls whether the incoming record is dropped or the oldest queued record is replaced.

### How to Use

Here are some specific examples provided.

#### When Need Low-level Explicit Queue Composition

When a sync logger should own a queue sink directly:
```moonbit
let sink = queued_sink(console_sink(), max_pending=2, overflow=QueueOverflowPolicy::DropOldest)
let logger = Logger::new(sink, target="queue")
```

In this example, records stay pending until the queue is drained or flushed.

### Error Case

e.g.:
- If the queue is bounded too tightly, overflow may drop records during bursts.

- If callers never drain or flush, queued records remain pending.

### Notes

1. This helper is the sink-level alternative to `Logger::with_queue(...)` and config-side `with_queue(...)`.

2. Use the higher-level APIs when you do not need to manipulate the queue sink directly.
