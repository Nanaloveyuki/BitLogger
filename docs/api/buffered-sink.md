---
name: buffered-sink
group: api
category: sink
update-time: 20260520
description: Create a sink that buffers records and flushes them manually or at a threshold.
key-word:
    - sink
    - buffer
    - flush
    - public
---

## Buffered-sink

Create a sink that buffers records before forwarding them to another sink. This helper is useful when callers want explicit or threshold-based sync batching without using the queue wrapper API.

### Interface

```moonbit
pub fn[S] buffered_sink(sink : S, flush_limit~ : Int = 1) -> BufferedSink[S] {
```

#### input

- `sink : S` - Wrapped sink that receives flushed records.
- `flush_limit : Int` - Buffer length threshold that triggers automatic flush.

#### output

- `BufferedSink[S]` - Buffering sink with `pending_count()` and `flush()` helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- Records are stored in an in-memory buffer until flushed.
- `flush_limit <= 0` is normalized to `1`.
- Flushing forwards the buffered records in order to the wrapped sink.

### How to Use

Here are some specific examples provided.

#### When Need Manual Or Threshold-based Batch Delivery

When writes should accumulate before they reach the destination:
```moonbit
let sink = buffered_sink(console_sink(), flush_limit=2)
let logger = Logger::new(sink, target="buffered")
```

In this example, records stay buffered until the threshold is reached or `flush()` is called.

### Error Case

e.g.:
- If callers never flush a buffer whose threshold is not reached, records remain pending.

- If bounded dropping behavior is required instead of simple buffering, use `queued_sink(...)` or `Logger::with_queue(...)`.

### Notes

1. This helper is simpler than explicit queue overflow management.

2. It is useful for synchronous batching scenarios and tests.
