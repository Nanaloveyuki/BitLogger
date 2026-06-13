---
name: runtime-sink-dropped-count
group: api
category: runtime
update-time: 20260613
description: Read the cumulative dropped-record count from a RuntimeSink.
key-word:
    - runtime
    - sink
    - queue
    - public
---

## Runtime-sink-dropped-count

Read the cumulative dropped-record count from a `RuntimeSink`. This helper exposes the direct sink-level loss metric for queue-backed runtime variants.

### Interface

```moonbit
pub fn RuntimeSink::dropped_count(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose dropped-record metric should be inspected.

#### output

- `Int` - Number of dropped records reported by the runtime sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- Queue-wrapped runtime variants forward to the wrapped queue sink's `dropped_count()` value.
- Plain console and plain file runtime variants return `0` because they do not track queued record drops.
- The counter is cumulative for the lifetime of the concrete runtime sink value.
- This method is the direct sink-level API used by `ConfiguredLogger::dropped_count(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Direct Queue Loss Visibility

When a runtime sink may discard records under pressure:
```moonbit
if sink.dropped_count() > 0 {
  println("runtime sink dropped records")
}
```

In this example, direct runtime queue loss becomes visible without inspecting inner fields manually.

#### When Compare Queue Tuning Changes

When queue overflow behavior should be checked operationally:
```moonbit
ignore(sink.dropped_count())
```

In this example, the helper exposes the metric needed to compare different queue settings.

### Error Case

e.g.:
- If the runtime sink is not queue-backed, the method simply returns `0`.

- If callers need the higher-level logger wrapper API, use `ConfiguredLogger::dropped_count()` instead.

### Notes

1. This helper reports cumulative loss, not the reason for that loss.

2. Pair it with `pending_count()` and queue configuration when investigating pressure.
