---
name: queued-sink-dropped-count
group: api
category: sink
update-time: 20260613
description: Read the cumulative dropped-record count from a QueuedSink.
key-word:
    - sink
    - queue
    - dropped
    - public
---

## Queued-sink-dropped-count

Read the cumulative dropped-record count from a `QueuedSink[S]`. This helper exposes the direct sink-level loss metric when a bounded queue overflows.

### Interface

```moonbit
pub fn[S] QueuedSink::dropped_count(self : QueuedSink[S]) -> Int {
```

#### input

- `self : QueuedSink[S]` - Queued sink whose cumulative dropped-record metric should be inspected.

#### output

- `Int` - Number of dropped records reported by the queue wrapper.

### Explanation

Detailed rules explaining key parameters and behaviors

- The counter value comes from `self.dropped_count.val`.
- It increases when the queue is full and an incoming record cannot be kept without applying overflow handling.
- The counter is cumulative for the lifetime of the concrete queued sink value.
- This helper does not explain why drops happened beyond exposing the count.

### How to Use

Here are some specific examples provided.

#### When Need Direct Queue Loss Visibility

When a bounded queue may discard records under pressure:
```moonbit
if sink.dropped_count() > 0 {
  println("queue dropped records")
}
```

In this example, direct queue loss becomes visible without inspecting internal fields manually.

#### When Compare Overflow Tuning Changes

When queue capacity or overflow policy should be checked operationally:
```moonbit
ignore(sink.dropped_count())
```

In this example, callers can compare the cumulative drop metric across different queue settings.

### Error Case

e.g.:
- If the queue never overflows, this counter remains `0`.

- If callers need a higher-level wrapper around runtime-configured sinks, `RuntimeSink::dropped_count()` or `ConfiguredLogger::dropped_count()` may fit better.

### Notes

1. This helper reports cumulative loss, not the exact overflow moment.

2. Pair it with `pending_count()`, `drain()`, and queue configuration when investigating pressure.
