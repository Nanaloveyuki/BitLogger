---
name: buffered-sink-pending-count
group: api
category: sink
update-time: 20260613
description: Read the current buffered-record count from a BufferedSink.
key-word:
    - sink
    - buffer
    - queue
    - public
---

## Buffered-sink-pending-count

Read the current buffered-record count from a `BufferedSink[S]`. This is the direct sink-level metric for how many records are still waiting in the in-memory buffer.

### Interface

```moonbit
pub fn[S] BufferedSink::pending_count(self : BufferedSink[S]) -> Int {
```

#### input

- `self : BufferedSink[S]` - Buffered sink whose current in-memory backlog should be inspected.

#### output

- `Int` - Current number of buffered records.

### Explanation

Detailed rules explaining key parameters and behaviors

- The return value is `self.buffer.val.length()` at the time of the call.
- This is a point-in-time metric and may change immediately after it is read.
- It reflects buffered records that have not yet been flushed to the wrapped sink.
- This helper does not mutate the sink.

### How to Use

Here are some specific examples provided.

#### When Need Direct Buffer Backlog Visibility

When code is working with a `BufferedSink` value directly and wants to observe pending buffered records:
```moonbit
let pending = sink.pending_count()
```

In this example, callers can inspect the current in-memory backlog without touching the wrapped sink.

#### When Verify Manual Flush Progress

When explicit flush steps should be checked operationally:
```moonbit
ignore(sink.flush())
ignore(sink.pending_count())
```

In this example, the metric helps verify whether buffered records were forwarded out of the local buffer.

### Error Case

e.g.:
- This helper does not have a normal failure mode; it only reads current buffer length.

- If callers need overflow-aware backlog semantics instead of simple buffering, `QueuedSink::pending_count()` is the better API.

### Notes

1. Use this helper for direct visibility into simple synchronous buffering.

2. Pair it with `flush()` when inspecting whether batched writes have been forwarded.
