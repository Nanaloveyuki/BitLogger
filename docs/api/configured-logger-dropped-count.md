---
name: configured-logger-dropped-count
group: api
category: runtime
update-time: 20260613
description: Read the cumulative dropped-record count from a configured runtime logger through RuntimeSink.
key-word:
    - logger
    - runtime
    - queue
    - public
---

## Configured-logger-dropped-count

Read the cumulative dropped-record count from a `ConfiguredLogger`. This helper is the configured logger wrapper over `RuntimeSink::dropped_count(...)` when config-driven queue wrapping may discard records under pressure.

### Interface

```moonbit
pub fn ConfiguredLogger::dropped_count(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose dropped-record metric should be inspected.

#### output

- `Int` - Number returned by the wrapped `RuntimeSink::dropped_count()` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.dropped_count()`.
- Queue-backed runtime sink variants return their live dropped-count metric.
- Plain console and plain file runtime sink variants return `0` because they do not track queued record drops.
- The counter is cumulative for the lifetime of the concrete runtime sink value owned by the configured logger.

### How to Use

Here are some specific examples provided.

#### When Need Loss Visibility On Config-built Queues

When a config-driven queue may discard records:
```moonbit
if logger.dropped_count() > 0 {
  println("configured logger dropped records")
}
```

In this example, the runtime logger exposes queue loss without manual sink inspection.

#### When Compare Queue Tuning Changes

When queue overflow policy should be validated operationally:
```moonbit
ignore(logger.dropped_count())
```

In this example, the helper exposes the metric needed to compare runtime queue tuning.

### Error Case

e.g.:
- If the configured logger is not queue-backed, the method simply returns `0`.

- If callers need queue shape and file status together, `file_runtime_state()` may carry more useful context for file sinks.

### Notes

1. This helper reports cumulative loss, not the reason for that loss.

2. Pair it with `pending_count()` and queue configuration when investigating pressure.
