---
name: configured-logger-dropped-count
group: api
category: runtime
update-time: 20260512
description: Read the cumulative dropped-record count from a configured runtime logger.
key-word:
    - logger
    - runtime
    - queue
    - public
---

## Configured-logger-dropped-count

Read the cumulative dropped-record count from a `ConfiguredLogger`. This helper is useful when config-driven queue wrapping may discard records under pressure.

### Interface

```moonbit
pub fn ConfiguredLogger::dropped_count(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose dropped-record metric should be inspected.

#### output

- `Int` - Number of dropped records reported by the runtime sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- Queue-backed sinks return their live dropped-count metric.
- Non-queued sinks report `0`.
- The counter is cumulative for the runtime sink lifetime.
- This helper delegates to `RuntimeSink::dropped_count(...)` through the configured logger wrapper.

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
- If the logger is not queue-backed, the method simply returns `0`.

- If callers need queue shape and file status together, `file_runtime_state()` may carry more useful context for file sinks.

### Notes

1. This helper reports cumulative loss, not the reason for that loss.

2. Pair it with `pending_count()` and queue configuration when investigating pressure.
