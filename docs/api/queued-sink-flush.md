---
name: queued-sink-flush
group: api
category: sink
update-time: 20260613
description: Flush a QueuedSink by draining its queued records into the wrapped sink.
key-word:
    - sink
    - queue
    - flush
    - public
---

## Queued-sink-flush

Flush a `QueuedSink[S]` by draining its queued records into the wrapped sink. This is the direct sink-level shorthand for draining the whole queue.

### Interface

```moonbit
pub fn[S : Sink] QueuedSink::flush(self : QueuedSink[S]) -> Int {
```

#### input

- `self : QueuedSink[S]` - Queued sink whose pending records should be fully drained to the wrapped sink.

#### output

- `Int` - Number of drained records.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates directly to `self.drain()`.
- It drains as many queued records as are currently pending.
- The return value is the number of records forwarded to the wrapped sink.
- This helper is the sink-level shorthand for a full manual queue drain.

### How to Use

Here are some specific examples provided.

#### When Need Full Queue Flush Semantics

When a queued sink should forward all pending records:
```moonbit
let flushed = sink.flush()
```

In this example, callers can observe how many queued records were forwarded.

#### When Need A Simpler Alternative To Explicit Drain Limits

When bounded draining is unnecessary and the whole queue should be released:
```moonbit
ignore(sink.flush())
```

In this example, the queue is drained completely without specifying `max_items`.

### Error Case

e.g.:
- If the queue is already empty, the method returns `0`.

- If callers need bounded progress instead of a full drain, `drain(max_items=...)` is the better API.

### Notes

1. Use this helper when code owns a `QueuedSink` directly and wants a full manual queue release.

2. This helper returns a count, unlike `BufferedSink::flush()`.
