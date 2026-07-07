---
name: configured-logger-drain
group: api
category: runtime
update-time: 20260707
description: Compatibility configured runtime drain helper that still returns one Int by collapsing generic queue progress and plain-file fallback steps.
key-word:
    - logger
    - runtime
    - queue
    - public
---

## Configured-logger-drain

Drain queued work from a `ConfiguredLogger` and return one compatibility count. This helper is still available for older code, but new configured-runtime code should prefer `drain_progress()` because it exposes queue advancement and plain-file fallback steps separately.

### Interface

```moonbit
pub fn ConfiguredLogger::drain(self : ConfiguredLogger, max_items~ : Int = -1) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose queued work should be drained.
- `max_items : Int` - Optional upper bound on how many queued items to drain. Negative values mean no explicit bound.

#### output

- `Int` - Compatibility count returned by the wrapped `RuntimeSink::drain(...)` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.drain(max_items=max_items)`.
- Under the hood, `RuntimeSink::drain()` now rebuilds one compatibility count from `drain_progress()`.
- Queue-wrapped sinks still report drained queued items through that compatibility count.
- Plain file sinks still report the generic fallback flush step as `1` or `0`.
- Plain console-style sinks still return `0`.

### How to Use

Here are some specific examples provided.

#### When Need Bounded Queue Progress

When older code already expects one numeric drain count from a config-built logger:
```moonbit
let drained = logger.drain(max_items=16)
```

In this example, callers still limit how much queued work is processed in one step while keeping the legacy return shape.

#### When Need Full Manual Drain

When code should keep the older full-drain compatibility path:
```moonbit
ignore(logger.drain())
```

In this example, the configured runtime logger drains without changing the legacy return shape.

### Error Case

e.g.:
- If the configured runtime sink is not queue-backed, draining may return `0` or follow the plain-file flush fallback.

- If callers need truthful generic progress semantics, `drain_progress()` is the better API.

- If callers only need generic flush semantics, `flush_progress()` may be the simpler structured API.

- If callers need file-specific success semantics after draining a queued file logger, they should inspect failure counters or use `file_flush()` for the file-specific path.

### Notes

1. Treat this method as a compatibility helper for older numeric code.

2. Prefer `drain_progress()` in new configured-runtime code.

3. Use `pending_count()` to inspect remaining backlog after the drain call when the configured sink is queue-backed.
