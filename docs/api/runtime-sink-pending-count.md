---
name: runtime-sink-pending-count
group: api
category: runtime
update-time: 20260613
description: Read the current queued backlog count from a RuntimeSink.
key-word:
    - runtime
    - sink
    - queue
    - public
---

## Runtime-sink-pending-count

Read the current queued backlog count from a `RuntimeSink`. This is the direct sink-level queue metric behind configured logger pending-count behavior.

### Interface

```moonbit
pub fn RuntimeSink::pending_count(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose current queue backlog should be inspected.

#### output

- `Int` - Current number of pending queued records.

### Explanation

Detailed rules explaining key parameters and behaviors

- Queue-wrapped runtime variants forward to the wrapped queue sink's `pending_count()` value.
- Plain console and plain file runtime variants return `0` because they do not own a pending queue here.
- This is a point-in-time metric and may change immediately after it is read.
- This method is the direct sink-level API used by `ConfiguredLogger::pending_count(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Direct Queue Backlog Visibility

When code is working with a `RuntimeSink` value directly and wants queue pressure information:
```moonbit
let pending = sink.pending_count()
```

In this example, backlog is read from the runtime sink without going through a logger wrapper.

#### When Verify Manual Drain Progress

When drain loops should observe remaining queue backlog directly:
```moonbit
ignore(sink.drain(max_items=8))
ignore(sink.pending_count())
```

In this example, the metric helps confirm whether manual queue draining reduced backlog.

### Error Case

e.g.:
- If the runtime sink is not queue-backed, the method simply returns `0`.

- If callers need the higher-level logger wrapper API, use `ConfiguredLogger::pending_count()` instead.

### Notes

1. Use this helper for simple direct queue visibility on `RuntimeSink` values.

2. Pair it with `dropped_count()` when investigating queue pressure and loss.
