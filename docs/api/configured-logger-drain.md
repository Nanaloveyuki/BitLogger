---
name: configured-logger-drain
group: api
category: runtime
update-time: 20260613
description: Drain queued work from a configured runtime logger with optional item limits through RuntimeSink.
key-word:
    - logger
    - runtime
    - queue
    - public
---

## Configured-logger-drain

Drain queued work from a `ConfiguredLogger`. This helper is the configured logger wrapper over `RuntimeSink::drain(...)` when config-driven queue wrapping should be advanced in a controlled, bounded way.

### Interface

```moonbit
pub fn ConfiguredLogger::drain(self : ConfiguredLogger, max_items~ : Int = -1) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose queued work should be drained.
- `max_items : Int` - Optional upper bound on how many queued items to drain. Negative values mean no explicit bound.

#### output

- `Int` - Count returned by the wrapped `RuntimeSink::drain(...)` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.drain(max_items=max_items)`.
- Queue-wrapped sinks forward to the concrete queue sink's `drain(...)` behavior and may drain up to `max_items` records.
- Plain file sinks fall back to `FileSink::flush()` behavior through `RuntimeSink` and return `1` or `0`.
- Plain console-style sinks return `0` because they do not own a drainable queue here.

### How to Use

Here are some specific examples provided.

#### When Need Bounded Queue Progress

When queued output should be advanced in chunks:
```moonbit
let drained = logger.drain(max_items=16)
```

In this example, callers limit how much queued work is processed in one step.

#### When Need Full Manual Drain

When the configured queue should be emptied explicitly:
```moonbit
ignore(logger.drain())
```

In this example, the configured runtime logger drains without imposing an item cap.

### Error Case

e.g.:
- If the configured runtime sink is not queue-backed, draining may return `0` or follow the plain-file flush fallback.

- If callers only need generic flush semantics, `flush()` may be the simpler API.

### Notes

1. Prefer this helper when queue progress should be bounded or observable.

2. Use `pending_count()` to inspect remaining backlog after the drain call when the configured sink is queue-backed.
