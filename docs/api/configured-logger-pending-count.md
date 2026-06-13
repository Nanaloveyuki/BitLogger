---
name: configured-logger-pending-count
group: api
category: runtime
update-time: 20260613
description: Read the current queued backlog count from a configured runtime logger through RuntimeSink.
key-word:
    - logger
    - runtime
    - queue
    - public
---

## Configured-logger-pending-count

Read the current queued backlog count from a `ConfiguredLogger`. This is the configured logger wrapper over `RuntimeSink::pending_count(...)` for config-driven queue metrics.

### Interface

```moonbit
pub fn ConfiguredLogger::pending_count(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose queue backlog should be inspected.

#### output

- `Int` - Current number returned by the wrapped `RuntimeSink::pending_count()` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.pending_count()`.
- Queue-backed runtime sink variants return their live pending count.
- Plain console and plain file runtime sink variants return `0` because they do not own a pending queue here.
- This is a point-in-time metric and may change immediately after it is read.

### How to Use

Here are some specific examples provided.

#### When Need Configured Queue Backlog Visibility

When a config-built logger should expose queue pressure:
```moonbit
let pending = logger.pending_count()
```

In this example, queue backlog is observed without reaching into the sink internals.

#### When Verify Manual Drain Progress

When drain loops should observe remaining backlog:
```moonbit
ignore(logger.drain(max_items=8))
ignore(logger.pending_count())
```

In this example, the queue metric helps verify manual drain progress.

### Error Case

e.g.:
- If the configured logger is not queue-backed, the method simply returns `0`.

- If callers need richer file-plus-queue state for file sinks, `file_runtime_state()` is the better API.

### Notes

1. Use this helper for simple queue visibility on config-built loggers.

2. Pair it with `dropped_count()` when investigating loss behavior.
