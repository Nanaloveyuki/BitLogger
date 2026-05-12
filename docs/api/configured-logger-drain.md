---
name: configured-logger-drain
group: api
category: runtime
update-time: 20260512
description: Drain queued work from a configured runtime logger with optional item limits.
key-word:
    - logger
    - runtime
    - queue
    - public
---

## Configured-logger-drain

Drain queued work from a `ConfiguredLogger`. This helper is useful when config-driven queue wrapping should be advanced in a controlled, bounded way.

### Interface

```moonbit
pub fn ConfiguredLogger::drain(self : ConfiguredLogger, max_items~ : Int = -1) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose queued work should be drained.
- `max_items : Int` - Optional upper bound on how many queued items to drain. Negative values mean no explicit bound.

#### output

- `Int` - Number of drained items.

### Explanation

Detailed rules explaining key parameters and behaviors

- Queue-wrapped sinks may drain up to `max_items` records.
- For plain file sinks, the runtime falls back to file flush behavior instead of queue draining.
- For sinks without queue semantics, the result is typically `0`.
- This helper delegates to `RuntimeSink::drain(...)` through the configured logger wrapper.

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
- If the runtime sink is not queue-backed, draining may return `0` or follow fallback flush behavior.

- If callers only need generic flush semantics, `flush()` may be the simpler API.

### Notes

1. Prefer this helper when queue progress should be bounded or observable.

2. Use `pending_count()` to inspect remaining backlog after the drain call.
