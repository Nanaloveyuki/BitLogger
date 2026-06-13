---
name: queued-sink-pending-count
group: api
category: sink
update-time: 20260613
description: Read the current queued-record count from a QueuedSink.
key-word:
    - sink
    - queue
    - backlog
    - public
---

## Queued-sink-pending-count

Read the current queued-record count from a `QueuedSink[S]`. This is the direct sink-level backlog metric for records that have been queued but not yet drained to the wrapped sink.

### Interface

```moonbit
pub fn[S] QueuedSink::pending_count(self : QueuedSink[S]) -> Int {
```

#### input

- `self : QueuedSink[S]` - Queued sink whose current pending backlog should be inspected.

#### output

- `Int` - Current number of queued records.

### Explanation

Detailed rules explaining key parameters and behaviors

- The return value is `self.queue.length()` at the time of the call.
- This is a point-in-time metric and may change immediately after it is read.
- It reflects queued records that have not yet been drained or flushed to the wrapped sink.
- This helper does not mutate the sink.

### How to Use

Here are some specific examples provided.

#### When Need Direct Queue Backlog Visibility

When code is working with a `QueuedSink` value directly and wants to inspect backlog pressure:
```moonbit
let pending = sink.pending_count()
```

In this example, callers can inspect the current queue size without draining it.

#### When Verify Drain Progress

When manual draining should be checked operationally:
```moonbit
ignore(sink.drain(max_items=8))
ignore(sink.pending_count())
```

In this example, the metric helps verify whether a drain step reduced queued backlog.

### Error Case

e.g.:
- This helper does not have a normal failure mode; it only reads current queue length.

- If callers only need simple threshold buffering instead of an explicit queue, `BufferedSink::pending_count()` may be the better API.

### Notes

1. Use this helper for direct visibility into queue backlog on `QueuedSink` values.

2. Pair it with `dropped_count()` when investigating queue pressure.
